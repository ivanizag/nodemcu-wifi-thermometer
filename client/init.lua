if gpio.read(3) == 0 then
  print("FLASH button is pushed. init.lua skipped.")
else
  print("Booting (had to press FLASH button to skip boot).")
  print("To skip boot rename the init file and reset. Rename with:")
  print("  file.rename('init.lua','init.old')")

  dofile('DS18B20.lua')

  serverIp = "192.168.1.101"
  serverPort = 23322
  sensorDQPin = 2
  sensorVCCPin = 1
  ds18b20_read_send_sleep(serverIp, serverPort, sensorDQPin, sensorVCCPin)
end
