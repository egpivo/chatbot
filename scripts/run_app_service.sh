#!/bin/bash
#
# Chatbot Serving
#
# - Parameters
#    - Optional
#       - --t5_pretrained_model: Specifies the Hugging Face SpeechT5 model. Default: microsoft/speecht5_tts
#       - --t5_pretrained_vocoder: Specifies the Hugging Face SpeechT5 HiFi-GAN Vocoder. Default: microsoft/speecht5_hifigan
#       - --whisper_pretrained_model: Specifies the Hugging Face SWhisper model. Default: openai/whisper-tiny
#       - --is_retraining: Forces retraining of models.
#
# This script automates the process of checking and fine-tuning pre-trained models for the Chatbot application.
# It supports customizing the SpeechT5 and SWhisper models, as well as enabling retraining if needed.
# If the specified models do not exist, or if retraining is forced, the script initiates the fine-tuning process.
# After model preparation, it serves the Chatbot application using BentoML.
#

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_BASE_PATH="${CURRENT_DIR}/../"
source "${PACKAGE_BASE_PATH}/.env"
source "${CURRENT_DIR}/exit_code.sh"

# Parse command line options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --t5_pretrained_model) T5_PRETRAINED_MODEL="$2"; shift 2 ;;
    --t5_pretrained_vocoder) T5_PRETRAINED_VOCODER="$2"; shift 2 ;;
    --whisper_pretrained_model) WHISPER_PRETRAINED_MODEL="$2"; shift 2 ;;
    --is_retraining) IS_RETRAINING="TRUE"; shift ;;
    *) shift ;;
  esac
done

# Set default values if not provided
T5_PRETRAINED_MODEL=${T5_PRETRAINED_MODEL:-"microsoft/speecht5_tts"}
T5_PRETRAINED_VOCODER=${T5_PRETRAINED_VOCODER:-"microsoft/speecht5_hifigan"}
WHISPER_PRETRAINED_MODEL=${WHISPER_PRETRAINED_MODEL:-"openai/whisper-tiny"}

# Set job commands
JOB_COMMANDS=(
  "${CURRENT_DIR}/run_model_training.py"
  "--t5_pretrained_model" "${T5_PRETRAINED_MODEL}"
  "--t5_pretrained_vocoder" "${T5_PRETRAINED_VOCODER}"
  "--whisper_pretrained_model" "${WHISPER_PRETRAINED_MODEL}"
)
[[ "x${IS_RETRAINING}x" == "xTRUEx" ]] && JOB_COMMANDS+=("--is_retraining")

# Check and fine-tune models
echo -e "$(tput setaf 6)Check and fine-tune models$(tput sgr0)"
python "${JOB_COMMANDS[@]}"
if [ "$?" != "${SUCCESS_EXITCODE}" ]; then
  exit "${ERROR_EXITCODE}"
fi

# Serve BentoML App
echo -e "$(tput setaf 2)Serve BentoML App$(tput sgr0)"
bentoml serve chatbot/app.py