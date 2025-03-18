#!/bin/bash

# Directorio donde están los videos
INPUT_DIR="$(dirname "$(pwd)")"
# 1920, 1280, 720, 640, 480, 360, 240
DESIRED_WIDTH=""
# VBR, CQP o CBR
RC_MODE="-rc_mode VBR"
BITRATE_LIMIT="15000"
QUALITY="-crf 25"
# VBR or CQP
preset="-preset slow"
APPEND="_compressed"

# Verifica si el directorio contiene archivos
if [ -z "$(ls -A $INPUT_DIR)" ]; then
    echo "El directorio está vacío."
    exit 1
fi

# Verificar si el directorio contiene archivos de video
VIDEO_FILES=$(find "$INPUT_DIR" -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" \))

if [ -z "$VIDEO_FILES" ]; then
    echo "No se encontraron archivos de video en el directorio."
    exit 1
fi

# Verifica si ffmpeg está instalado
if ! command -v ffmpeg &> /dev/null; then
    echo "ffmpeg no está instalado. Por favor, instálalo y vuelve a intentarlo."
    exit 1
fi

# Recorre todos los archivos de video en el directorio
for INPUT_VIDEO in "$INPUT_DIR"/*.{mp4,mkv,avi}; do
    if [ -f "$INPUT_VIDEO" ]; then

        # Verifica si el archivo ya tiene el sufijo APPEND
        if [[ "$INPUT_VIDEO" == *"$APPEND"* ]]; then
            echo "El archivo $(basename "$INPUT_VIDEO") ya tiene el sufijo $APPEND. Omitiendo conversión."
            continue
        fi

        # Define el archivo de salida
        OUTPUT_VIDEO="${INPUT_VIDEO%.*}${APPEND}.${INPUT_VIDEO##*.}"

        # Verifica si el archivo de salida ya existe
        if [ -f "$OUTPUT_VIDEO" ]; then
            echo "El archivo $(basename "$INPUT_VIDEO") ya fue convertido anteriormente ya que un archivo llamado $(basename "$OUTPUT_VIDEO") se encuentra en el mismo directorio. Omitiendo conversion."
            continue
        fi

        


        # Obtiene el bitrate original utilizando ffmpeg
        ORIGINAL_BITRATE=$(ffmpeg -i "$INPUT_VIDEO" 2>&1 | grep -oP 'bitrate: \K[0-9]+')
        
        # Obtiene la resolución original utilizando ffmpeg
        RESOLUTION=$(ffmpeg -i "$INPUT_VIDEO" 2>&1 | grep -oP 'Video:.* (\d{3,4})x(\d{3,4})' | head -n 1 | grep -oP '\d{3,4}x\d{3,4}')
        WIDTH=$(echo "$RESOLUTION" | cut -d'x' -f1)
        HEIGHT=$(echo "$RESOLUTION" | cut -d'x' -f2)

        # Verifica si el bitrate es menor a BITRATE_LIMIT
        if [ "$ORIGINAL_BITRATE" -lt "$BITRATE_LIMIT" ]; then
            echo "El archivo $(basename "$INPUT_VIDEO") tiene un bitrate menor a $BITRATE_LIMIT kb/s. Omitiendo conversión."
            continue
        fi

        # Verifica si el ancho es menor a DESIRED_WIDTH
        if [ -n "$DESIRED_WIDTH" ] && [ "$WIDTH" -lt "$DESIRED_WIDTH" ]; then
            echo "El archivo $(basename "$INPUT_VIDEO") tiene un ancho menor a $DESIRED_WIDTH. Omitiendo conversión."
            continue
        fi

        echo "Procesando: $INPUT_VIDEO"
        echo "Bitrate original: $ORIGINAL_BITRATE kb/s"
        echo "Resolución original del video: ${WIDTH}x${HEIGHT}"

        # Redimensiona si es necesario
        if [ -z "$DESIRED_WIDTH" ]; then
            echo "El archivo mantendra sus dimensiones originales."
            SCALE_FILTER="-vf format=nv12,hwupload"
        elif [ "$WIDTH" -gt $DESIRED_WIDTH ] || [ "$HEIGHT" -gt 1080 ]; then
            echo "Redimensionando a ${DESIRED_WIDTH}x-2 manteniendo el aspect ratio."
            SCALE_FILTER="-vf format=nv12,hwupload,scale_vaapi=w=$DESIRED_WIDTH:h=-2"
        else
            SCALE_FILTER=""
        fi

        # Reduce el bitrate si es mayor a BITRATE_LIMIT kbps
        if [ -z "$BITRATE_LIMIT" ]; then
            BITRATE_OPTION=""
        elif [ "$ORIGINAL_BITRATE" -gt "$BITRATE_LIMIT" ]; then
            echo "Reduciendo el bitrate a $BITRATE_LIMIT kbps."
            # BITRATE_OPTION="-b:v ${BITRATE_LIMIT}k"
            BITRATE_OPTION="-b:v ${BITRATE_LIMIT}k"
        else
            # BITRATE_OPTION="-b:v ${BITRATE}k"
            BITRATE_OPTION="-b:v ${BITRATE_LIMIT}k"

        fi

        # Construye y ejecuta el comando ffmpeg
        FFMPEG_CMD="ffmpeg -v error -stats -hwaccel vaapi -vaapi_device /dev/dri/renderD128 -i '${INPUT_VIDEO}' ${SCALE_FILTER} -c:v hevc_vaapi ${QUALITY} $PRESET $RC_MODE -q:v 24 -quality 1 -slices 16 ${BITRATE_OPTION} -map 0:v:0 -map 0:a:0 -c:a:0 copy -y '${OUTPUT_VIDEO}'"
        echo "Ejecutando comando: $FFMPEG_CMD"
        eval $FFMPEG_CMD

        # Verifica si el archivo de salida tiene tamaño mayor a 0 bytes
        if [ ! -s "$OUTPUT_VIDEO" ]; then
            echo "La conversión falló o el archivo está vacío. Eliminando $OUTPUT_VIDEO."
            rm -f "$OUTPUT_VIDEO"
        else
            # Verifica la resolución del archivo de salida
            OUTPUT_RESOLUTION=$(ffmpeg -i "$OUTPUT_VIDEO" 2>&1 | grep -oP 'Video:.* (\d{3,4})x(\d{3,4})' | head -n 1 | grep -oP '\d{3,4}x\d{3,4}')
            SIZE=$(du -m "$OUTPUT_VIDEO" | cut -f1)
            OUTPUT_BITRATE=$(ffmpeg -i "$OUTPUT_VIDEO" 2>&1 | grep -oP 'bitrate: \K[0-9]+')
            echo "Propiedades del video convertido - Resolucion: $OUTPUT_RESOLUTION Peso: $SIZE mb Bitrate: $OUTPUT_BITRATE kb/s"
            echo "Video convertido y guardado como $OUTPUT_VIDEO"
        fi
        echo 
    fi
done
        