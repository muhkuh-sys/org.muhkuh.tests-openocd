local class = require 'pl.class'
local TestClass = require 'test_class'
local TestClassOpenOCD = class(TestClass)


function TestClassOpenOCD:_init(strTestName, uiTestCase, tLogWriter, strLogLevel)
  self:super(strTestName, uiTestCase, tLogWriter, strLogLevel)

  local P = self.P
  self:__parameter {
    P:P('script', 'The file name of the TCL script to execute.'):
      required(true)
  }
end



function TestClassOpenOCD:run()
  local atParameter = self.atParameter
  local tLog = self.tLog

  ----------------------------------------------------------------------
  --
  -- Parse the parameters and collect all options.
  --
  local openocd = require 'luaopenocd'

  -- Read the TCL script.
  local strScriptFileName = atParameter['script']:get()
  local strFileName = self.pl.path.exists(strScriptFileName)
  if strFileName~=strScriptFileName then
    tLog.error('The TCL script "%s" does not exist.', strScriptFileName)
    error('Failed to load the TCL script.')
  end
  local strScript = self.pl.file.read(strFileName)

  tOpenOCD = openocd.luaopenocd()

  tLog.debug('Initialize OpenOCD.')
  tOpenOCD:initialize()

  local strResult
  local iResult = tOpenOCD:run(strScript)
  if iResult~=0 then
    error('Failed to execute the script.')
  else
    strResult = tOpenOCD:get_result()
    tLog.info('Script result: %s', strResult)
    if strResult~='0' then
      error('The script result is not "0".')
    end
  end

  tLog.debug('Uninitialize OpenOCD.')
  tOpenOCD:uninit()

  tLog.info('')
  tLog.info(' #######  ##    ## ')
  tLog.info('##     ## ##   ##  ')
  tLog.info('##     ## ##  ##   ')
  tLog.info('##     ## #####    ')
  tLog.info('##     ## ##  ##   ')
  tLog.info('##     ## ##   ##  ')
  tLog.info(' #######  ##    ## ')
  tLog.info('')
end

return TestClassOpenOCD
