git clone https://github.com/jayrm/fbcunit.git
cd fbcunit
make
copy inc\*.* ..\inc\
copy lib\*.* ..\lib\
cd ..
rmdir /S /Q fbcunit
