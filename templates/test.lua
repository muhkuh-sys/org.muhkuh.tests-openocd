local TestClassOpenOCD = require 'test_class_openocd'
return function(ulTestID, tLogWriter, strLogLevel) return TestClassOpenOCD('@NAME@', ulTestID, tLogWriter, strLogLevel) end
