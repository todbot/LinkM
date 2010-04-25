

while [ 1 ] ; do
echo "------------------------"
echo `date`
./linkmbootload_macosx -r linkm.hex
sleep 1
./linkmbootload_macosx -f
#echo "looking for LinkM: \c"
#system_profiler SPUSBDataType|grep -i LinkM
echo "\nTo run another LinkBoot load, press return"
read
done
