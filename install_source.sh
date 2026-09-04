#!/bin/bash
# 模块：easySVA 源码部署入口（含流媒体协议组 GB28181 集成）。
# 职责：在 Ubuntu 22.04 安装 CPU/GPU 分析器、前后端、原媒体服务，以及旁路的 WVP/GB28181 ZLMediaKit。
# 边界：CPU/GPU 只决定分析器与编解码依赖；SIP、设备同步和浏览器预览流程两种模式完全一致。
# 前置：easySVA-lib.zip 位于 /opt（或由 EASYSVA_LIB_ARCHIVE 指定），并以 root 用户执行。

set -e -o pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LIB_ARCHIVE="${EASYSVA_LIB_ARCHIVE:-/opt/easySVA-lib.zip}"
REPO_BASE="${EASYSVA_REPO_BASE:-https://github.com/We1chan}"
# Pin the audited cross-repository baseline so every machine builds the same code.
# The collaboration backend does not publish the old upstream v1.2.8 tag.
MEDIA_SERVER_REF="${EASYSVA_MEDIA_SERVER_REF:-95eda58fcf3e8ed401d404f825cfbc434362af34}"
ANALYZER_REF="${EASYSVA_SERVER_REF:-f49d60183014117152607be2b592a72776db6f9f}"
BACKEND_REF="${EASYSVA_BACKEND_REF:-6390beca5ee6c08ac8f339872bcb907cca96f635}"
WEB_REF="${EASYSVA_WEB_REF:-98607abc3f598ba5e41a8511d184e1f2899d79e4}"
WVP_REPO="${EASYSVA_WVP_REPO:-https://github.com/648540858/wvp-GB28181-pro.git}"
WVP_REF="${EASYSVA_WVP_REF:-fb45787da01cb4f33a0b1dfaa613becf67391c17}"
GB_SIMULATOR_REPO="${EASYSVA_GB_SIMULATOR_REPO:-https://github.com/sb-im/sbgb28181.git}"
GB_SIMULATOR_REF="${EASYSVA_GB_SIMULATOR_REF:-1da9bc62134d4cb1fd4374f733583fb5997c3f0a}"
WVP_DB_NAME="${EASYSVA_WVP_DB_NAME:-wvp}"
WVP_DB_USERNAME="${EASYSVA_WVP_DB_USERNAME:-wvp}"
WVP_DB_PASSWORD="${EASYSVA_WVP_DB_PASSWORD:-easySVA.GB28181}"
GB28181_SIP_PASSWORD="${EASYSVA_GB28181_SIP_PASSWORD:-admin123}"
GB28181_ZLM_SECRET="${EASYSVA_GB28181_ZLM_SECRET:-easySVA.GB28181.ZLM}"
GB28181_HOST_IP="${EASYSVA_GB28181_HOST_IP:-}"
SLEEP_POSE_MODEL_SOURCE="${EASYSVA_SLEEP_POSE_MODEL:-}"
SAMPLE_SOURCES_AUTO_START="${EASYSVA_AUTO_START_SAMPLE_SOURCES:-0}"
SLEEP_DETECT_FPS="${EASYSVA_SLEEP_DETECT_FPS:-}"
SQL_FILE="$SCRIPT_DIR/data_20250520.sql"

checkout_repo_at_ref() {
    local repo_url="$1"
    local target_dir="$2"
    local ref="$3"
    if [[ -e "$target_dir" ]]; then
        echo "目标目录已存在，拒绝覆盖: $target_dir" >&2
        exit 1
    fi
    git init -q "$target_dir"
    git -C "$target_dir" remote add origin "$repo_url"
    # Direct fetch accepts an immutable commit as well as an explicit branch/tag.
    git -C "$target_dir" fetch --depth=1 origin "$ref"
    git -C "$target_dir" checkout --detach FETCH_HEAD
}

if [[ ! "$WVP_DB_NAME" =~ ^[A-Za-z0-9_]+$ ]] ||
   [[ ! "$WVP_DB_USERNAME" =~ ^[A-Za-z0-9_]+$ ]]; then
    echo "WVP数据库名和用户名只能包含字母、数字、下划线。" >&2
    exit 1
fi

if [[ ! "$WVP_DB_PASSWORD" =~ ^[A-Za-z0-9._@%+=:-]+$ ]] ||
   [[ ! "$GB28181_SIP_PASSWORD" =~ ^[A-Za-z0-9._@%+=:-]+$ ]] ||
   [[ ! "$GB28181_ZLM_SECRET" =~ ^[A-Za-z0-9._@%+=:-]+$ ]]; then
    echo "WVP数据库密码、SIP密码和ZLM密钥包含不支持的字符。" >&2
    echo "仅支持字母、数字和 . _ @ % + = : -" >&2
    exit 1
fi

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

if [[ -n "$SLEEP_POSE_MODEL_SOURCE" && ! -s "$SLEEP_POSE_MODEL_SOURCE" ]]; then
    echo "EASYSVA_SLEEP_POSE_MODEL 指向的文件不存在或为空: $SLEEP_POSE_MODEL_SOURCE" >&2
    exit 1
fi

if [[ "$SAMPLE_SOURCES_AUTO_START" != "0" && "$SAMPLE_SOURCES_AUTO_START" != "1" ]]; then
    echo "EASYSVA_AUTO_START_SAMPLE_SOURCES 只允许 0 或 1。" >&2
    exit 1
fi

if [[ -n "$SLEEP_DETECT_FPS" && ! "$SLEEP_DETECT_FPS" =~ ^([1-9]|[12][0-9]|30)$ ]]; then
    echo "EASYSVA_SLEEP_DETECT_FPS 必须是 1 到 30 的整数。" >&2
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
echo "媒体服务版本: $MEDIA_SERVER_REF"
echo "分析器版本: $ANALYZER_REF"
echo "后端版本: $BACKEND_REF"
echo "前端版本: $WEB_REF"
echo "WVP版本: $WVP_REF"
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
apt install -y build-essential unzip meson ninja-build python3 \
    gstreamer1.0-tools gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly gstreamer1.0-libav \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libglib2.0-dev

cd /opt
unzip "$LIB_ARCHIVE"
cd easySVA-lib

# CPU/GPU 选择只影响分析器及本地编解码加速，GB28181 信令和媒体接入不依赖该选择。
echo "如果你的系统有NVIDIA GPU并且显卡驱动 ≥ 580.xx，建议选择GPU版本，否则选择CPU版本。"
read -p "G:编译GPU版本; C:编译CPU版本:" gpu_answer 
#如果输入的不是G/g或者C/c，提示错误并退出
if [[ "$gpu_answer" != "g" && "$gpu_answer" != "G" && "$gpu_answer" != "c" && "$gpu_answer" != "C" ]]; then
    echo "输入错误，请输入G或C"
    exit 1
fi

# CPU Runtime 始终安装，供无GPU环境或GPU依赖异常时自动回退。
echo "安装CPU版 ONNX Runtime 1.26.0"
rm -rf /usr/local/onnxruntime
mkdir -p /usr/local/onnxruntime
tar -xzf onnxruntime-linux-x64-1.26.0.tgz \
    --strip-components=1 -C /usr/local/onnxruntime

if [[ "$gpu_answer" == "g" || "$gpu_answer" == "G" ]]; then
    echo "将安装cuda13.1 耗时较长，请耐心等待"
    chmod +x cuda_13.1.2_590.48.01_linux.run
# WSL由Windows提供GPU驱动，此处只安装CUDA Toolkit，并禁用旧安装器的GUI探测。
env -u DISPLAY ./cuda_13.1.2_590.48.01_linux.run \
    --silent --toolkit --toolkitpath=/usr/local/cuda-13.1 --tmpdir=/opt

echo "安装GPU版 ONNX Runtime 1.26.0"
rm -rf /usr/local/onnxruntime-gpu
mkdir -p /usr/local/onnxruntime-gpu
tar -xzf onnxruntime-linux-x64-gpu_cuda13-1.26.0.tgz \
    --strip-components=1 -C /usr/local/onnxruntime-gpu

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
apt install -y libnvinfer10=$VER libnvinfer-plugin10=$VER libnvonnxparsers10=$VER libnvinfer-dev=$VER libnvinfer-plugin-dev=$VER libnvonnxparsers-dev=$VER libnvinfer-headers-dev=$VER libnvinfer-headers-plugin-dev=$VER

#防止系统自动更新这些包导致版本不兼容
apt-mark hold libnvinfer10 libnvinfer-plugin10 libnvonnxparsers10 libnvinfer-dev libnvinfer-plugin-dev libnvonnxparsers-dev libnvinfer-headers-dev libnvinfer-headers-plugin-dev
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
if [[ -n "$SLEEP_POSE_MODEL_SOURCE" ]]; then
    install -m 0644 "$SLEEP_POSE_MODEL_SOURCE" /opt/SVA/models/yolo11n-pose.onnx
fi
if [[ -s /opt/SVA/models/yolo11n-pose.onnx ]]; then
    SLEEP_DEMO_ENABLED=1
    if [[ -z "$SLEEP_DETECT_FPS" ]]; then
        if [[ "$gpu_answer" == "g" || "$gpu_answer" == "G" ]]; then
            SLEEP_DETECT_FPS=10
        else
            SLEEP_DETECT_FPS=1
        fi
    fi
    echo "已准备睡岗姿态模型；检测帧率为 ${SLEEP_DETECT_FPS} FPS。"
    echo "睡岗任务默认停止；确认机器负载后再从页面逐路启动。"
else
    SLEEP_DEMO_ENABLED=0
    echo "未提供 yolo11n-pose.onnx；跳过睡岗演示任务，普通分析和 GB28181 功能仍可使用。"
fi

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


checkout_repo_at_ref "$REPO_BASE/SVA-mediaServer.git" \
    /opt/SVA/SVA-mediaServer "$MEDIA_SERVER_REF"
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

checkout_repo_at_ref "$REPO_BASE/SVA-server.git" \
    /opt/SVA/SVA-server "$ANALYZER_REF"

if [[ "$SLEEP_DEMO_ENABLED" == "1" ]]; then
    install -m 0644 \
        /opt/SVA/SVA-server/prototypes/sleep_pose/models/open-closed-eye-0001.onnx \
        /opt/SVA/models/open-closed-eye-0001.onnx
fi

# CPU版本始终编译，作为自动回退路径。
echo "编译CPU版本的Analyzer"
sleep 2
cmake -S /opt/SVA/SVA-server -B /opt/SVA/SVA-server/build-cpu \
    -DCMAKE_BUILD_TYPE=Release \
    -DONNXRUNTIME_ROOT=/usr/local/onnxruntime \
    -DSVA_ONNXRUNTIME_GPU=OFF
cmake --build /opt/SVA/SVA-server/build-cpu \
    --parallel $(($(nproc)>6?6:$(nproc)))

if [[ "$gpu_answer" == "g" || "$gpu_answer" == "G" ]]; then
    echo "编译GPU版本的Analyzer"
    sleep 2
    cmake -S /opt/SVA/SVA-server -B /opt/SVA/SVA-server/build-gpu \
        -DCMAKE_BUILD_TYPE=Release \
        -DONNXRUNTIME_ROOT=/usr/local/onnxruntime-gpu \
        -DSVA_ONNXRUNTIME_GPU=ON
    cmake --build /opt/SVA/SVA-server/build-gpu \
        --parallel $(($(nproc)>6?6:$(nproc)))
fi

cp /opt/SVA/SVA-server/config.json /opt/SVA/

echo "接下来将编译前后端，感谢RuoYi-Vue-Plus的开源贡献"
sleep 2

apt update
apt -y install net-tools git curl sudo tmux zip --no-install-recommends wget curl git gnupg libjpeg-dev libpng16-16 libavcodec-dev libavformat-dev libswscale-dev libgl1 libglib2.0-0


apt install redis-server -y

apt install mariadb-server -y
/etc/init.d/mariadb start
systemctl enable mariadb

apt install openjdk-17-jdk openjdk-21-jdk -y

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
create database ${WVP_DB_NAME} default character set utf8mb4 collate utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${WVP_DB_USERNAME}'@'localhost' IDENTIFIED BY '${WVP_DB_PASSWORD}';
CREATE USER IF NOT EXISTS '${WVP_DB_USERNAME}'@'127.0.0.1' IDENTIFIED BY '${WVP_DB_PASSWORD}';
ALTER USER '${WVP_DB_USERNAME}'@'localhost' IDENTIFIED BY '${WVP_DB_PASSWORD}';
ALTER USER '${WVP_DB_USERNAME}'@'127.0.0.1' IDENTIFIED BY '${WVP_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${WVP_DB_NAME}.* TO '${WVP_DB_USERNAME}'@'localhost';
GRANT ALL PRIVILEGES ON ${WVP_DB_NAME}.* TO '${WVP_DB_USERNAME}'@'127.0.0.1';
FLUSH PRIVILEGES;
EOF

mysql -uroot -peasySVA.EZ easySVA < "$SQL_FILE"
mysql -uroot -peasySVA.EZ easySVA < \
    "$SCRIPT_DIR/deploy/sql/20260901_gb28181_business.sql"
if [[ "$SLEEP_DEMO_ENABLED" == "1" ]]; then
    mysql -uroot -peasySVA.EZ easySVA < \
        "$SCRIPT_DIR/deploy/sql/20260903_add_test3_sleep_source.sql"
    mysql -uroot -peasySVA.EZ easySVA < \
        "$SCRIPT_DIR/deploy/sql/20260903_tune_sleep_detection.sql"
    mysql -uroot -peasySVA.EZ easySVA < \
        "$SCRIPT_DIR/deploy/sql/20260903_mixed_gb_rtsp_sources.sql"
    mysql -uroot -peasySVA.EZ easySVA <<EOF
UPDATE deployment_task_algorithm
SET detect_fps = ${SLEEP_DETECT_FPS}, update_time = NOW()
WHERE deployment_id IN ('controliDWtaBsTRom2rH', 'controlH87UlyOJCtFwOq', 'controlTest3Sleep20260903', 'controlGbTest3Sleep20260903')
  AND algorithm_code = 'on_yolo11n_pose_sleep';
EOF
fi



checkout_repo_at_ref "$REPO_BASE/SVA-backend.git" \
    /opt/SVA/SVA-backend "$BACKEND_REF"
cd /opt/SVA/SVA-backend
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
PATH="/usr/lib/jvm/java-17-openjdk-amd64/bin:$PATH" \
    mvn clean package -Dmaven.test.skip=true

# WVP 固定到已验收提交，避免外部依赖升级改变 API 响应结构或 SIP 行为。
echo "编译GB28181信令服务WVP"
checkout_repo_at_ref "$WVP_REPO" /opt/SVA/wvp-GB28181-pro "$WVP_REF"
cd /opt/SVA/wvp-GB28181-pro

JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 \
PATH="/usr/lib/jvm/java-21-openjdk-amd64/bin:$PATH" \
    mvn clean package -DskipTests

echo "编译GB28181软件摄像头"
checkout_repo_at_ref "$GB_SIMULATOR_REPO" /opt/SVA/sbgb28181 "$GB_SIMULATOR_REF"
git -C /opt/SVA/sbgb28181 apply \
    "$SCRIPT_DIR/deploy/patches/sbgb28181-fixed-local-port.patch"
meson setup /opt/SVA/sbgb28181/gst-gb28181sink/build \
    /opt/SVA/sbgb28181/gst-gb28181sink
meson compile -C /opt/SVA/sbgb28181/gst-gb28181sink/build

WVP_SCHEMA="/opt/SVA/wvp-GB28181-pro/数据库/2.7.4/初始化-mysql-2.7.4.sql"
if [[ ! -f "$WVP_SCHEMA" ]]; then
    echo "未找到WVP数据库初始化文件: $WVP_SCHEMA" >&2
    exit 1
fi

mysql -uroot -peasySVA.EZ "$WVP_DB_NAME" < "$WVP_SCHEMA"
mysql -uroot -peasySVA.EZ easySVA < \
    /opt/SVA/SVA-backend/deploy/gb28181/sql/001_extend_h_device.sql
mysql -uroot -peasySVA.EZ easySVA < \
    /opt/SVA/SVA-backend/deploy/gb28181/sql/002_add_gb_stream_url.sql
# Apply the unified GB28181 business schema after the earlier WVP columns.
# This migration is idempotent and preserves existing RTSP devices and alarms.
mysql -uroot -peasySVA.EZ easySVA < \
    /opt/FWWsva/deploy/sql/20260901_gb28181_business.sql

############################安装web#######################################
apt install -y nginx-full

curl -sL https://deb.nodesource.com/setup_22.x | sudo -E bash -
apt install -y nodejs


#前端编译
#用户名为  admin/admin123
checkout_repo_at_ref "$REPO_BASE/SVA-web.git" /var/www/SVA-web "$WEB_REF"
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

        location = / {
                try_files /index.html =404;
                add_header Cache-Control "no-cache, no-store, must-revalidate" always;
                add_header Pragma "no-cache" always;
                add_header Expires "0" always;
        }

        location = /index.html {
                add_header Cache-Control "no-cache, no-store, must-revalidate" always;
                add_header Pragma "no-cache" always;
                add_header Expires "0" always;
        }

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

        location /media/ {
            proxy_pass http://127.0.0.1:9992/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $http_host;
            proxy_read_timeout 600s;
            proxy_buffering off;
        }

        location /live/ {
            proxy_pass http://127.0.0.1:9992;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $http_host;
            proxy_read_timeout 600s;
            proxy_buffering off;
        }

        location /analyzer/ {
            proxy_pass http://127.0.0.1:9992;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $http_host;
            proxy_read_timeout 600s;
            proxy_buffering off;
        }

        location /gb-media/ {
            proxy_pass http://127.0.0.1:9996/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $http_host;
            proxy_read_timeout 600s;
            proxy_buffering off;
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
    mkdir -p /opt/SVA/backend
    cp /opt/SVA/SVA-backend/ruoyi-admin/target/ruoyi-admin.jar /opt/SVA/backend/backend.jar

    # Sample videos are versioned with Git LFS. Keep service files independent
    # of the checkout location while avoiding a second multi-gigabyte copy.
    mkdir -p /opt/SVA/samples
    for sample_video in test3.mp4 test6.mp4 test8.mp4; do
        if [[ ! -f "$SCRIPT_DIR/$sample_video" ]]; then
            echo "缺少模拟摄像头素材 $SCRIPT_DIR/$sample_video，请先执行 git lfs pull。" >&2
            exit 1
        fi
        ln -sfn "$SCRIPT_DIR/$sample_video" "/opt/SVA/samples/$sample_video"
    done

    # GB28181 复用同一 ZLMediaKit 可执行文件，但采用独立配置、端口和 systemd 服务。
    mkdir -p /opt/SVA/mediaServer
    cp /opt/SVA/SVA-mediaServer/release/linux/Release/* /opt/SVA/mediaServer/ -r

    mkdir -p /opt/SVA/gb28181 /opt/SVA/wvp /opt/SVA/logs
    mkdir -p /var/www/SVA-web/upload/gb28181
    WVP_JAR="$(find /opt/SVA/wvp-GB28181-pro/target -maxdepth 1 -type f \
        -name 'wvp-pro-*.jar' ! -name '*.original' -print -quit)"
    if [[ -z "$WVP_JAR" ]]; then
        echo "未找到WVP编译产物。" >&2
        exit 1
    fi
    install -m 0644 "$WVP_JAR" /opt/SVA/wvp/wvp-pro.jar
    install -m 0644 /opt/SVA/SVA-backend/deploy/gb28181/config/wvp.local.yml \
        /opt/SVA/gb28181/wvp.yml
    install -m 0644 /opt/SVA/SVA-backend/deploy/gb28181/config/zlm-gb.local.ini \
        /opt/SVA/gb28181/zlm-gb.ini
    sed -i 's#/opt/easySVA/wvp/jwk.json#/opt/SVA/wvp/jwk.json#g' \
        /opt/SVA/gb28181/wvp.yml
    sed -i 's#/opt/easySVA/logs#/opt/SVA/logs#g' \
        /opt/SVA/gb28181/zlm-gb.ini
    sed -i "s/easySVA\.GB28181\.ZLM/$GB28181_ZLM_SECRET/g" \
        /opt/SVA/gb28181/zlm-gb.ini

    mkdir -p /etc/easySVA
    {
        printf 'WVP_DB_USERNAME=%q\n' "$WVP_DB_USERNAME"
        printf 'WVP_DB_PASSWORD=%q\n' "$WVP_DB_PASSWORD"
        printf 'GB28181_SIP_PASSWORD=%q\n' "$GB28181_SIP_PASSWORD"
        printf 'GB28181_ZLM_SECRET=%q\n' "$GB28181_ZLM_SECRET"
        printf 'SPRING_DATASOURCE_URL=%q\n' \
            "jdbc:mysql://127.0.0.1:3306/${WVP_DB_NAME}?useUnicode=true&characterEncoding=UTF8&rewriteBatchedStatements=true&serverTimezone=Asia/Shanghai&useSSL=false&allowMultiQueries=true&allowPublicKeyRetrieval=true"
        if [[ -n "$GB28181_HOST_IP" ]]; then
            printf 'GB28181_HOST_IP=%q\n' "$GB28181_HOST_IP"
        fi
    } > /etc/easySVA/gb28181.env
    chmod 0600 /etc/easySVA/gb28181.env

    install -m 0755 "$SCRIPT_DIR/deploy/scripts/easysva-wvp-launcher.sh" \
        /opt/SVA/wvp/easysva-wvp-launcher.sh
    install -m 0755 "$SCRIPT_DIR/deploy/scripts/easysva-gb-health.sh" \
        /usr/local/bin/easysva-gb-health
    install -m 0755 "$SCRIPT_DIR/deploy/scripts/easysva-gb-simulator-launcher.sh" \
        /opt/SVA/gb28181/easysva-gb-simulator-launcher.sh

    mkdir -p /opt/SVA/server
    install -m 0755 /opt/SVA/SVA-server/build-cpu/Analyzer /opt/SVA/server/Analyzer.cpu
    cp /opt/SVA/server/Analyzer.cpu /opt/SVA/server/Analyzer

    if [[ "$gpu_answer" == "g" || "$gpu_answer" == "G" ]]; then
        install -m 0755 /opt/SVA/SVA-server/build-gpu/Analyzer /opt/SVA/server/Analyzer-gpu
    fi

    install -m 0755 "$SCRIPT_DIR/deploy/scripts/easysva-analyzer-launcher.sh" \
        /opt/SVA/server/easysva-analyzer-launcher.sh
    install -m 0755 "$SCRIPT_DIR/deploy/scripts/easysva-rtsp-simulator.sh" \
        /opt/SVA/server/easysva-rtsp-simulator.sh
    install -m 0755 "$SCRIPT_DIR/deploy/scripts/easysva-restore-streams.sh" \
        /opt/SVA/server/easysva-restore-streams.sh
    install -m 0644 "$SCRIPT_DIR/deploy/systemd/easysva-backend.service" \
        /etc/systemd/system/easysva-backend.service
    install -m 0644 "$SCRIPT_DIR/deploy/systemd/easysva-media.service" \
        /etc/systemd/system/easysva-media.service
    install -m 0644 "$SCRIPT_DIR/deploy/systemd/easysva-analyzer.service" \
        /etc/systemd/system/easysva-analyzer.service
    install -m 0644 "$SCRIPT_DIR/deploy/systemd/easysva-stream-restore.service" \
        /etc/systemd/system/easysva-stream-restore.service
    install -m 0644 "$SCRIPT_DIR/deploy/systemd/easysva-rtsp-simulator.service" \
        /etc/systemd/system/easysva-rtsp-simulator.service
    install -m 0644 "$SCRIPT_DIR/deploy/systemd/easysva-rtsp-simulator-2.service" \
        /etc/systemd/system/easysva-rtsp-simulator-2.service
    install -m 0644 "$SCRIPT_DIR/deploy/systemd/easysva-rtsp-simulator-3.service" \
        /etc/systemd/system/easysva-rtsp-simulator-3.service
    install -m 0644 "$SCRIPT_DIR/deploy/systemd/easysva-gb-media.service" \
        /etc/systemd/system/easysva-gb-media.service
    install -m 0644 "$SCRIPT_DIR/deploy/systemd/easysva-wvp.service" \
        /etc/systemd/system/easysva-wvp.service
    install -m 0644 "$SCRIPT_DIR/deploy/systemd/easysva-gb-simulator-test6.service" \
        /etc/systemd/system/easysva-gb-simulator-test6.service
    install -m 0644 "$SCRIPT_DIR/deploy/systemd/easysva-gb-simulator-test3.service" \
        /etc/systemd/system/easysva-gb-simulator-test3.service

    if command -v ufw >/dev/null 2>&1 && ufw status | grep -q '^Status: active'; then
        ufw allow 5060/tcp
        ufw allow 5060/udp
        ufw allow 9996/tcp
        ufw allow 9997/tcp
        ufw allow 10000/udp
        ufw allow 40002:45000/udp
        ufw allow 50000:55000/udp
    fi

    systemctl daemon-reload
    systemctl enable easysva-backend easysva-media easysva-analyzer easysva-stream-restore \
        easysva-gb-media easysva-wvp nginx mariadb redis-server
    if [[ "$SAMPLE_SOURCES_AUTO_START" == "1" ]]; then
        systemctl enable easysva-rtsp-simulator easysva-rtsp-simulator-2 \
            easysva-rtsp-simulator-3 easysva-gb-simulator-test6 easysva-gb-simulator-test3
    fi

fi

echo "安装完成，请重启系统，重启后访问http://ip/，用户名admin，密码admin123"
echo "zlm_server和sva_server的默认地址是127.0.0.1,如果想对外提供服务请修改为服务器的公网IP地址"
echo "数据库的用户名和密码是root/easySVA.EZ"
echo "GB28181参数保存在/etc/easySVA/gb28181.env（仅root可读）"
echo "重启后可执行 easysva-gb-health 检查GB28181服务"
