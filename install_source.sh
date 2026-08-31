#!/bin/bash
#本脚本用于在Ubuntu 22.04系统上安装easySVA的源码编译环境，包括依赖包、FFmpeg、OpenCV、MediaServer、前后端等组件。
#请确保easySVA-lib.zip位于/opt目录下，并以root用户执行。

set -o pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LIB_ARCHIVE="${EASYSVA_LIB_ARCHIVE:-/opt/easySVA-lib.zip}"
REPO_BASE="${EASYSVA_REPO_BASE:-https://github.com/We1chan}"
SQL_FILE="$SCRIPT_DIR/data_20250520.sql"

if [[ $EUID -ne 0 ]]; then
    echo "请先执行 sudo -s 切换为root用户，再运行本脚本。"
    exit 1
fi

if [[ ! -f "$LIB_ARCHIVE" ]]; then
    echo "未找到依赖包: $LIB_ARCHIVE"
    echo "请将easySVA-lib.zip下载到/opt目录，或通过EASYSVA_LIB_ARCHIVE指定路径。"
    exit 1
fi

if [[ ! -f "$SQL_FILE" ]]; then
    echo "未找到数据库初始化文件: $SQL_FILE"
    echo "请从FWWsva仓库完整克隆后运行install_source.sh。"
    exit 1
fi


cat <<'EOF'
8 8888888888            .8.            d888888o.  `8.`8888.      ,8' d888888o.  `8.`888b           ,8' .8.
8 8888                 .888.         .`8888:' `88. `8.`8888.    ,8'.`8888:' `88. `8.`888b         ,8' .888.
8 8888                :88888.        8.`8888.   Y8  `8.`8888.  ,8' 8.`8888.   Y8  `8.`888b       ,8' :88888.
8 8888               . `88888.       `8.`8888.       `8.`8888.,8'  `8.`8888.       `8.`888b     ,8' . `88888.
8 888888888888      .8. `88888.       `8.`8888.       `8.`88888'    `8.`8888.       `8.`888b   ,8' .8. `88888.
8 8888             .8`8. `88888.       `8.`8888.       `8. 8888      `8.`8888.       `8.`888b ,8' .8`8. `88888.
8 8888            .8' `8. `88888.       `8.`8888.       `8 8888       `8.`8888.       `8.`888b8' .8' `8. `88888.
8 8888           .8'   `8. `88888.  8b   `8.`8888.       8 8888   8b   `8.`8888.       `8.`888' .8'   `8. `88888.
8 8888          .888888888. `88888. `8b.  ;8.`8888       8 8888   `8b.  ;8.`8888        `8.`8' .888888888. `88888.
8 888888888888 .8'       `8. `88888. `Y8888P ,88P'       8 8888    `Y8888P ,88P'         `8.` .8'       `8. `88888.
EOF


echo "                 "
echo "                 "
echo "欢迎试用easySVA的源码编译脚本"
echo "推荐在Ubuntu 22.04系统上安装"
echo "源码仓库: $REPO_BASE"
echo "依赖包: $LIB_ARCHIVE"
read -p "请sudo -s切换为root用户后再进行安装，输入y/Y继续执行脚本: " answer
if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo "感谢您对我们的支持"
    exit 1
fi

echo "开始安装easySVA，请耐心等待，安装过程可能需要30分钟以上"
echo "安装过程中请不要关闭终端，安装完成后会提示您"
echo "现在开始安装环境和依赖包，并且编译FFmpeg"
sleep 2

apt update
apt install -y build-essential unzip

cd /opt
unzip "$LIB_ARCHIVE"
cd easySVA-lib

#让用户选择编译gpu版本还是cpu版本
echo "如果你的系统有NVIDIA GPU并且显卡驱动 ≥ 580.xx，建议选择GPU版本，否则选择CPU版本。"
read -p "G:编译GPU版本; C:编译CPU版本:" gpu_answer 
#如果输入的不是G/g或者C/c，提示错误并退出
if [[ "$gpu_answer" != "g" && "$gpu_answer" != "G" && "$gpu_answer" != "c" && "$gpu_answer" != "C" ]]; then
    echo "输入错误，请输入G或C"
    exit 1
fi

if [[ "$gpu_answer" == "g" || "$gpu_answer" == "G" ]]; then
    echo "将安装cuda13.1 耗时较长，请耐心等待"
    chmod +x cuda_13.1.2_590.48.01_linux.run
#不安装GUI的相关工具
./cuda_13.1.2_590.48.01_linux.run --silent --toolkit --tmpdir /opt

tar -zxvf onnxruntime-linux-x64-gpu_cuda13-1.26.0.tgz
mv onnxruntime-linux-x64-gpu-1.26.0 /usr/local/onnxruntime

echo 'export PATH="/usr/local/cuda/bin:$PATH"' >> /etc/profile
echo 'export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"' >> /etc/profile

#生效配置，查询cuda版本
source /etc/profile
nvcc -V

read -p "确认能查询到cuda版本，输入y/Y继续执行脚本: " answer
if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo "请上传完成后再执行脚本"
    exit 1
fi


wget https://developer.download.nvidia.cn/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
dpkg -i cuda-keyring_1.1-1_all.deb


apt update
apt -y install cudnn9-cuda-13

VER=10.15.1.29-1+cuda13.1
sudo apt install -y libnvinfer10=$VER libnvinfer-plugin10=$VER libnvonnxparsers10=$VER libnvinfer-dev=$VER  libnvinfer-plugin-dev=$VER  libnvonnxparsers-dev=$VER libnvinfer-headers-dev=$VER  libnvinfer-headers-plugin-dev=$VER 

#防止系统自动更新这些包导致版本不兼容
sudo apt-mark hold libnvinfer10 libnvinfer-plugin10 libnvonnxparsers10 libnvinfer-dev libnvinfer-plugin-dev libnvonnxparsers-dev libnvinfer-headers-dev libnvinfer-headers-plugin-dev
fi

#如果输入的是cpu版本，就安装onnxruntime的cpu版本
if [[ "$gpu_answer" == "c" || "$gpu_answer" == "C" ]]; then
    echo "将编译CPU版本的"
tar -zxvf onnxruntime-linux-x64-1.26.0.tgz
mv onnxruntime-linux-x64-1.26.0 /usr/local/onnxruntime
fi

read -p "完成了onnxruntime安装，输入y/Y继续执行脚本: " answer
if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo "请上传完成后再执行脚本"
    exit 1
fi

apt install -y git build-essential cmake 
#创建TensorRT的trt_cache目录，TensorRT加速时会将优化后的模型缓存到这个目录中，重启系统不用等3分钟
mkdir -p /opt/SVA/tmp/trt_cache

cd /opt/easySVA-lib/
mv /opt/easySVA-lib/models /opt/SVA/ 

add-apt-repository -y main restricted universe multiverse
apt update
apt install -y yasm libfaac-dev libmp3lame-dev libopus-dev libx264-dev libx265-dev libtheora-dev libvorbis-dev libxvidcore-dev  libxext-dev libxfixes-dev

apt install -y pkg-config


cd /opt/easySVA-lib
unzip nv-codec-headers.zip
cd nv-codec-headers && make
make install

cd /opt/easySVA-lib/
tar xvf ffmpeg-6.1.4.tar.xz && cd ffmpeg-6.1.4

if [[ "$gpu_answer" == "g" || "$gpu_answer" == "G" ]]; then
    echo "编译GPU版本的ffmpeg"
./configure  --prefix=/usr/local \
--enable-pic \
--enable-shared \
--enable-gpl  \
--enable-libmp3lame \
--enable-libopus \
--enable-libx264 \
--enable-libx265 \
--enable-nonfree  \
--enable-pthreads \
--enable-cuda \
--enable-cuvid \
--enable-nvenc \
--enable-ffnvcodec \
--extra-cflags=-I/usr/local/cuda/include \
--extra-ldflags=-L/usr/local/cuda/lib64
fi

if [[ "$gpu_answer" == "c" || "$gpu_answer" == "C" ]]; then
 echo -e "\n===== 开始配置 纯 CPU 版本 FFmpeg ====="
    # CPU 版本配置参数（去掉所有 CUDA 相关，保持通用依赖）
    ./configure  --prefix=/usr/local \
    --enable-pic \
    --enable-shared \
    --enable-gpl  \
    --enable-libmp3lame \
    --enable-libopus \
    --enable-libx264 \
    --enable-libx265 \
    --enable-nonfree  \
    --enable-pthreads
fi

read -p "确认ffmpeg配置正常，输入y/Y继续执行脚本: " answer
if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo "请上传完成后再执行脚本"
    exit 1
fi

make -j$(($(nproc)>6?6:$(nproc)))
make install

ldconfig

apt install -y  libgtk2.0-dev  

cd /opt/



echo "接下来将编译opencv"
sleep 2

cd /opt/easySVA-lib/

unzip opencv-4.13.0.zip
unzip opencv_contrib-4.13.0.zip

mv opencv-4.13.0 opencv
mv opencv_contrib-4.13.0 opencv_contrib

cd opencv && mkdir -p build 

cd /opt/easySVA-lib/opencv/build


if [[ "$gpu_answer" == "g" || "$gpu_answer" == "G" ]]; then
    echo "使用GPU编译OpenCV"
    sleep 2

if command -v nvidia-smi &> /dev/null; then
    CUDA_ARCH_BIN=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader | sort -u | tr '\n' ' ' | sed 's/ $//')
    echo "自动检测GPU算力 CUDA_ARCH_BIN: $CUDA_ARCH_BIN"
else
    echo "未检测到nvidia-smi，关闭CUDA"
    exit 1
fi

cmake -D CMAKE_BUILD_TYPE=RELEASE \
-D CMAKE_INSTALL_PREFIX=/usr/local \
-D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
-D INSTALL_C_EXAMPLES=OFF \
-D INSTALL_PYTHON_EXAMPLES=OFF \
-D BUILD_opencv_python3=OFF \
-D BUILD_opencv_python3_tests=OFF \
-D BUILD_EXAMPLES=OFF \
-D WITH_TBB=ON \
-D WITH_CUDA=ON \
-D CUDA_ARCH_BIN="$CUDA_ARCH_BIN" \
-D CUDA_ARCH_PTX="" \
-D WITH_CUDNN=ON \
-D OPENCV_DNN_CUDA=ON \
-D CUDNN_INCLUDE_DIR=/usr/include/x86_64-linux-gnu/ \
-D CUDNN_LIBRARY=/usr/lib/x86_64-linux-gnu/libcudnn.so \
-D CUDNN_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/ \
-D WITH_CUBLAS=ON \
-D ENABLE_FAST_MATH=ON \
-D CUDA_FAST_MATH=ON \
-D WITH_V4L=ON \
-D WITH_QT=ON \
-D WITH_OPENGL=ON \
-D OPENCV_GENERATE_PKGCONFIG=ON \
-D OPENCV_PC_FILE_NAME=opencv4.pc \
-D OPENCV_ENABLE_NONFREE=ON \
-D WITH_TENSORRT=ON \
-D TENSORRT_DIR=/usr/ \
-D BUILD_TESTS=OFF \
-D BUILD_PERF_TESTS=OFF \
-D BUILD_TIFF=OFF \
-D OPENCV_GENERATE_SETUPVARS=OFF ..    
fi

if [[ "$gpu_answer" == "c" || "$gpu_answer" == "C" ]]; then
    echo "使用CPU编译OpenCV"
    sleep 2
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
    -D INSTALL_C_EXAMPLES=OFF \
    -D INSTALL_PYTHON_EXAMPLES=OFF \
    -D BUILD_opencv_python3=OFF \
    -D BUILD_opencv_python3_tests=OFF \
    -D BUILD_EXAMPLES=OFF \
    -D WITH_TBB=ON \
    -D WITH_CUDA=OFF \
    -D WITH_CUDNN=OFF \
    -D OPENCV_DNN_CUDA=OFF \
    -D WITH_TENSORRT=OFF \
    -D WITH_V4L=ON \
    -D WITH_QT=ON \
    -D WITH_OPENGL=ON \
    -D OPENCV_GENERATE_PKGCONFIG=ON \
    -D OPENCV_PC_FILE_NAME=opencv4.pc \
    -D OPENCV_ENABLE_NONFREE=ON \
    -D BUILD_TESTS=OFF \
    -D BUILD_PERF_TESTS=OFF \
    -D BUILD_TIFF=OFF \
    -D OPENCV_GENERATE_SETUPVARS=OFF ..
fi


read -p "确定opencv配置正确,y/Y继续执行脚本: " answer
if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo "请上传完成后再执行脚本"
    exit 1
fi

make -j$(($(nproc)>6?6:$(nproc)))
make install


echo "接下来将编译MediaServer,感谢ZLMediaKit的开源贡献"
sleep 2

apt install -y libssl-dev libevent-dev

apt install -y libjsoncpp-dev


cd /opt/easySVA-lib
unzip curl-7.83.0.zip

cd curl-7.83.0
./configure \
  --with-openssl \
  --enable-http3 \
  --enable-threaded-resolver \
  --enable-versioned-symbols

make -j$(($(nproc)>6?6:$(nproc)))
make install


git clone --depth=1 "$REPO_BASE/SVA-mediaServer.git" /opt/SVA/SVA-mediaServer
cd /opt/SVA/SVA-mediaServer

mkdir build && cd build

cmake -D CMAKE_BUILD_TYPE=Release \
-D ENABLE_WEBRTC=OFF \
-D ENABLE_SRT=OFF \
-D ENABLE_TESTS=OFF -D ENABLE_MEM_DEBUG=OFF ..

make -j$(($(nproc)>6?6:$(nproc)))

#覆盖一下配置文件
cp /opt/SVA/SVA-mediaServer/conf/config.ini /opt/SVA/SVA-mediaServer/release/linux/Release/

echo "编译AI分析器Analyzer"
sleep 2

git clone --depth=1 "$REPO_BASE/SVA-server.git" /opt/SVA/SVA-server/

if [[ "$gpu_answer" == "g" || "$gpu_answer" == "G" ]]; then
    echo "编译GPU版本的Analyzer"
    sleep 2
cd /opt/SVA/SVA-server/
mkdir build && cd build
cmake ..
make -j$(($(nproc)>6?6:$(nproc)))
cp /opt/SVA/SVA-server/config.json /opt/SVA/
fi

if [[ "$gpu_answer" == "c" || "$gpu_answer" == "C" ]]; then
    echo "编译CPU版本的Analyzer"
    sleep 2
    cd /opt/SVA/SVA-server/
mkdir build && cd build
cmake .. -DSVA_ONNXRUNTIME_GPU=OFF
make -j$(($(nproc)>6?6:$(nproc)))
cp /opt/SVA/SVA-server/config.json /opt/SVA/
fi


echo "接下来将编译前后端，感谢RuoYi-Vue-Plus的开源贡献"
sleep 2

apt update
apt -y install net-tools git curl sudo tmux zip --no-install-recommends wget curl git gnupg libjpeg-dev libpng16-16 libavcodec-dev libavformat-dev libswscale-dev libgl1 libglib2.0-0


apt install redis-server -y

apt install mariadb-server -y
/etc/init.d/mariadb start
systemctl enable mariadb

apt install openjdk-17-jdk -y

cd /opt/easySVA-lib
# 安装 Maven
apt install maven -y

mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY 'easySVA.EZ';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
create database easySVA default character set utf8mb4 collate utf8mb4_unicode_ci;
EOF

mysql -uroot -peasySVA.EZ easySVA < "$SQL_FILE"



git clone --depth=1 "$REPO_BASE/SVA-backend.git" /opt/SVA/SVA-backend
cd /opt/SVA/SVA-backend
mvn clean package -Dmaven.test.skip=true

#只需要创建rc.local并且可执行权限，系统就会启动的时候自动调用
cat <<EOF >/etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

#In order to avoid the failure to start freeswitch due to failure to obtain the address,
#start it manually

sleep 3
cd /opt/SVA/backend/ && java -jar backend.jar &>log.out&

sleep 2
cd /opt/SVA/mediaServer/ && ./MediaServer -d &

sleep 2
cd /opt/SVA/server/ && ./Analyzer -f /opt/SVA/config.json &>log.out&

exit 0
EOF

chmod +x /etc/rc.local

############################安装web#######################################
apt install -y nginx-full

curl -sL https://deb.nodesource.com/setup_22.x | sudo -E bash -
apt install -y nodejs


#前端编译
#用户名为  admin/admin123
git clone --depth=1 "$REPO_BASE/SVA-web.git" /var/www/SVA-web
cd /var/www/SVA-web
npm config set registry https://registry.npmmirror.com/
npm install


# 开发调试
# npm run dev
# 浏览器访问 http://localhost:80 


# 构建生产环境
export NODE_OPTIONS=--openssl-legacy-provider && npm run build:prod


# 构建测试环境
# npm run build:stage

# server上传文件的目录是/var/www/SVA-web/upload/alarm/
mkdir -p /var/www/SVA-web/upload/

#配置nginx来访问

echo '
upstream websocket_backend {
    server 127.0.0.1:9114;  # 替换为实际 WebSocket 服务器地址和端口
}

server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/SVA-web/dist/;

        index index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
                try_files $uri $uri/ =404;
        }

        location /alarm/ {
               alias /var/www/SVA-web/upload/alarm/;
        }

        location /zlm/ {
               alias /var/www/SVA-web/upload/storage/;
        }

        location  /prod-api/ {
            proxy_pass  http://127.0.0.1:9114/;
            proxy_set_header Host $http_host;
        }

        location /websocket/ {  # 匹配 WebSocket 请求路径
            proxy_pass http://websocket_backend;  # 转发到上游服务器
            proxy_http_version 1.1;  # 启用 HTTP/1.1
            proxy_set_header Upgrade $http_upgrade;  # 处理协议升级头
            proxy_set_header Connection "upgrade";  # 设置连接类型为升级
            proxy_set_header Host $host;  # 传递客户端 Host 信息
            proxy_read_timeout 600s;     # 防止超时断开（可选）
        }

}
'>/etc/nginx/sites-enabled/default

echo "是否要把编译后的软件部署到指定目录，实现开机自启，输入y/Y继续执行脚本: "
read -r deploy_choice
if [[ "$deploy_choice" =~ ^[Yy]$ ]]; then
    echo "正在部署软件并设置开机自启..."
    # 在这里添加部署和设置开机自启的命令
    mkdir -p /opt/SVA/backend
cp /opt/SVA/SVA-backend/ruoyi-admin/target/ruoyi-admin.jar /opt/SVA/backend/backend.jar
mkdir -p /opt/SVA/mediaServer
cp /opt/SVA/SVA-mediaServer/release/linux/Release/* /opt/SVA/mediaServer/ -r
mkdir -p /opt/SVA/server

cp /opt/SVA/SVA-server/build/Analyzer  /opt/SVA/server/Analyzer

fi

echo "安装完成，请重启系统，重启后访问http://ip/，用户名admin，密码admin123"
echo "zlm_server和sva_server的默认地址是127.0.0.1,如果想对外提供服务请修改为服务器的公网IP地址"
echo "数据库的用户名和密码是root/easySVA.EZ"
