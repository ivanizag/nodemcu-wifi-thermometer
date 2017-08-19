-- Safe init based on https://bigdanzblog.wordpress.com/2015/04/24/esp8266-nodemcu-interrupting-init-lua-during-boot/

function startup()
  if a == 1 then
    print('startup aborted')
    return
  end
  print("Booting.")
  dofile('DS18B20.lua')

  serverIp = "192.168.1.101"
  serverPort = 23322
  sensorDQPin = 2
  sensorVCCPin = 1
  ds18b20_read_send_sleep(serverIp, serverPort, sensorDQPin, sensorVCCPin)
end

a = 0
print("To skip boot type within 4 seconds:")
print("  a=1")

tmr.alarm(0, 4000, 0, startup)
