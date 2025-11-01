# TODO: this script is silly, we ought to programatically determine all
# these paths
MODELS=/nix/store/68f86zic5ihbjj4g79jkhn9d6x819s22-gz-waves-models/share/gz-waves-models
PLUGINS=/nix/store/rdvmfcyzj8sbxipky3l8w6mms4bnagsg-gz-waves

# ensure the model and world files are found
export GZ_SIM_RESOURCE_PATH=\
$GZ_SIM_RESOURCE_PATH:\
$MODELS/models:\
$MODELS/world_models:\
$MODELS/worlds

# ensure the system plugins are found
export GZ_SIM_SYSTEM_PLUGIN_PATH=\
$GZ_SIM_SYSTEM_PLUGIN_PATH:\
$PLUGINS/lib
