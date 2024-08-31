const opsplash = require('./src/opsplash');

document.getElementById('uploadButton').addEventListener('change', handleFileUpload);
document.getElementById('test').addEventListener('click', testSplashImage);
document.getElementById('download').addEventListener('click', downloadSplashImage);
document.getElementById('preview').addEventListener('click', previewImage);
document.getElementById('change').addEventListener('click', changeImageByIndex);

var splash = false; // OPPOSplashImage

function handleFileUpload(event) {
    const file = event.target.files[0];
    if (file) {
        console.log('File uploaded:', file);

        // 执行文件处理
        processFile(file);
    }
}

function testSplashImage() {
    console.log("Run test:");
    if (splash instanceof opsplash.OPPOSPlashImage) {
        splash.test();
    } else {
        console.log("Error: No splash image loaded!");
    }
}

function changeImageByIndex() {
    // 获取所有 name 为 "index" 的 radio 按钮
    const radios = document.querySelectorAll('input[name="index"]');
    let index = null;

    // 遍历 radio 按钮，找到被选中的那个
    radios.forEach(radio => {
        if (radio.checked) {
            index = radio.value;
        }
    });

    if (index == null) {
        console.log("Image not selected!");
        return;
    }

    // 创建 input 元素
    const inputElement = document.createElement('input');

    console.log("Create input element");

    // 设置 input 属性
    inputElement.type = 'file';
    inputElement.accept = 'image/*'; // 仅接受图像文件

    // 为 input 添加 change 事件处理程序
    inputElement.addEventListener('change', function (event) {
        const file = event.target.files[0];
        if (file) {
            console.log('Selected file:', file.name);
            // 你可以在这里处理文件，例如预览或上传

            const reader = new FileReader();
            reader.onload = (e) => {
                const img = new Image();

                img.onload = function () {
                    const canvas = document.createElement('canvas');
                    canvas.width = img.width;
                    canvas.height = img.height;

                    const ctx = canvas.getContext('2d');
                    ctx.drawImage(img, 0, 0); // 在画布上绘制图像

                    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
                    if (!imageData) {
                        console.log("Failed to load image data!");
                        return;
                    }
                    splash.changeImageByIndex(index, imageData);
                    console.log("Done!");
                };

                img.src = e.target.result; // 使用 Data URL 加载图像
            };

            // 将文件读取为 Data URL
            reader.readAsDataURL(file);
        }
    });

    // 触发文件选择对话框
    inputElement.click();
}

function previewImage() {
    // 获取所有 name 为 "index" 的 radio 按钮
    const radios = document.querySelectorAll('input[name="index"]');
    let index = null;

    // 遍历 radio 按钮，找到被选中的那个
    radios.forEach(radio => {
        if (radio.checked) {
            index = radio.value;
        }
    });
    console.log('Get image by index', index);

    if (index != null) {
        const dialog = document.getElementById('imgdialog');
        const img = document.getElementById('previewimg');

        // get image blob
        const blob = splash.getRawImageBlobByIndex(index);
        const url = URL.createObjectURL(blob);

        img.src = url;
        img.alt = 'BMP Image';

        dialog.show();
    }
}

function downloadSplashImage() {
    console.log("Download blob");
    if (splash instanceof opsplash.OPPOSPlashImage) {

        let blob = splash.genNewImage();
        let url = URL.createObjectURL(blob);
        let a = document.createElement('a')
        a.href = url;
        a.download = 'new-splash.img';
        document.body.appendChild(a);
        a.click();

        document.body.removeChild(a); // 移除链接
        URL.revokeObjectURL(url); // 释放内存

    } else {
        console.log("Splash image not loaded!");
    }
}

function processFile(file) {
    console.log('Processing file:', file.name);

    const reader = new FileReader();
    reader.onload = function (e) {
        const arrayBuffer = e.target.result;
        console.log('ArrayBuffer length:', arrayBuffer.byteLength);
        // 在这里进一步处理 ArrayBuffer 数据
        try {
            splash = new opsplash.OPPOSPlashImage(arrayBuffer);

            var tbody = document.querySelector("#splashTable tbody")
            while (tbody.firstChild) {
                tbody.removeChild(tbody.firstChild);
            }

            for (let i = 0; i < splash.imageNum; i++) {
                var newrow = document.createElement('tr');
                for (let j = 0; j < 5; j++) {
                    var newcell;
                    if (j < 4) {
                        newcell = document.createElement('td');
                    } else {
                        newcell = document.createElement('div');
                    }

                    switch (j) {
                        case 0:
                            newcell.textContent = splash.dataInfos[i].name;
                            break;
                        case 1:
                            newcell.textContent = splash.dataInfos[i].offset;
                            break;
                        case 2:
                            newcell.textContent = splash.dataInfos[i].compsz;
                            break;
                        case 3:
                            newcell.textContent = splash.dataInfos[i].realsz;
                            break;
                        case 4:
                            let radio = document.createElement('input');
                            radio.type = 'radio';
                            radio.name = 'index';
                            radio.value = i;
                            newcell.appendChild(radio);
                            break;
                        default:
                            break;
                    }
                    newrow.appendChild(newcell);
                }
                tbody.appendChild(newrow);
            }

        } catch (error) {
            console.log(error);
        }

    };

    reader.onerror = function (e) {
        console.error('Error reading file:', e);
    };

    reader.readAsArrayBuffer(file);
}