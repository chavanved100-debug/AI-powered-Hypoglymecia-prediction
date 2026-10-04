import os
import json
from pathlib import Path
import numpy as np
from PIL import Image
import tensorflow as tf
from tensorflow import keras

DATASET_DIR = Path(r'D:\\food_images')
MAPPING_PATH = Path(r'D:\\hack 2 ishan new\\class_to_food_mapping.json')
OUT_DIR = Path(r'D:\\hack 2 ishan new\\glucose_guard\\assets\\models')
OUT_DIR.mkdir(parents=True, exist_ok=True)

IMG_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS = 10

def load_mapped():
    with open(MAPPING_PATH) as f:
        m = json.load(f)
    items = []
    for x in m:
        cls = x['image_class']
        fid = x['food_id']
        name = x['food_name']
        cls_dir = DATASET_DIR / cls
        if cls_dir.exists():
            items.append((cls, fid, name))
    return items

def build_dataset(items, split=0.8):
    train_imgs, train_labels, val_imgs, val_labels = [], [], [], []
    class_to_idx = {it[0]: i for i, it in enumerate(items)}
    for i, (cls, fid, name) in enumerate(items):
        cls_dir = DATASET_DIR / cls
        files = [f for f in os.listdir(cls_dir) if f.lower().endswith(('.jpg','.jpeg','.png','.bmp','.webp'))]
        # limit if too many? keep reasonable
        np.random.shuffle(files)
        n = len(files)
        n_train = int(n * split)
        for f in files[:n_train]:
            train_imgs.append(str(cls_dir / f))
            train_labels.append(i)
        for f in files[n_train:]:
            val_imgs.append(str(cls_dir / f))
            val_labels.append(i)
    return train_imgs, train_labels, val_imgs, val_labels, class_to_idx, items

def preprocess(path, label):
    img = tf.io.read_file(path)
    img = tf.image.decode_image(img, channels=3, expand_animations=False)
    img = tf.image.resize(img, IMG_SIZE)
    img = img / 255.0
    return img, label

def main():
    items = load_mapped()
    print('Classes:', len(items))
    train_imgs, train_labels, val_imgs, val_labels, class_to_idx, items = build_dataset(items)
    print('Train:', len(train_imgs), 'Val:', len(val_imgs))
    train_ds = tf.data.Dataset.from_tensor_slices((train_imgs, train_labels))
    train_ds = train_ds.map(preprocess, num_parallel_calls=tf.data.AUTOTUNE).shuffle(1000).batch(BATCH_SIZE).prefetch(tf.data.AUTOTUNE)
    val_ds = tf.data.Dataset.from_tensor_slices((val_imgs, val_labels))
    val_ds = val_ds.map(preprocess, num_parallel_calls=tf.data.AUTOTUNE).batch(BATCH_SIZE).prefetch(tf.data.AUTOTUNE)
    
    base_model = keras.applications.MobileNetV3Large(input_shape=(*IMG_SIZE,3), include_top=False, weights='imagenet')
    base_model.trainable = False
    inputs = keras.Input(shape=(*IMG_SIZE,3))
    x = base_model(inputs, training=False)
    x = keras.layers.GlobalAveragePooling2D()(x)
    x = keras.layers.Dropout(0.3)(x)
    outputs = keras.layers.Dense(len(items), activation='softmax')(x)
    model = keras.Model(inputs, outputs)
    model.compile(optimizer=keras.optimizers.Adam(1e-3), loss='sparse_categorical_crossentropy', metrics=['accuracy'])
    model.fit(train_ds, validation_data=val_ds, epochs=EPOCHS, verbose=1)
    
    # fine tune
    base_model.trainable = True
    for layer in base_model.layers[:-50]:
        layer.trainable = False
    model.compile(optimizer=keras.optimizers.Adam(1e-4), loss='sparse_categorical_crossentropy', metrics=['accuracy'])
    model.fit(train_ds, validation_data=val_ds, epochs=2, verbose=1)
    
    # save labels
    labels = []
    for i, (cls, fid, name) in enumerate(items):
        labels.append({'index': i, 'image_class': cls, 'food_id': fid, 'food_name': name})
    with open(OUT_DIR / 'labels.json','w') as f:
        json.dump(labels, f, indent=2)
    
    # convert to tflite
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    (OUT_DIR / 'food_classifier.tflite').write_bytes(tflite_model)
    print('saved to', OUT_DIR)

if __name__ == '__main__':
    main()
