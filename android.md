

#OTA
#SIGN OTA PACKAGE
./build/tools/releasetools/ota_from_target_files \
	-v -n -p out/host/linux-x86 \
	-k build/target/product/security/$PRODUCT/releaseKey \
	$UNSIGN_UPDATE.zip $update.zip
	
#OTA Incremental package
./build/tools/releasetools/ota_from_target_files \
	-k build/target/product/security/$PRODUCT/releaseKey \
	-v -i [-w to erase data] \
	$OLD_PACKAGE $NEW_PACKAGE $OUT_OTA_PACKAGE
	