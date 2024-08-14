%~dp0kopia.exe server start ^
  --config-file "%~dp0configs\repository.config" ^
  --log-dir %~dp0logs ^
  --address 127.0.0.1:51515 ^
  --htpasswd-file "%~dp0configs\.htpasswd" ^
  --tls-cert-file "%~dp0tls\kopia.crt" ^
  --tls-key-file "%~dp0tls\kopia.key"