local class = require 'pl.class'
local TestClassOpenOCD = class()


function TestClassOpenOCD:_init(strTestName)
  self.parameters = require 'parameters'
  self.pl = require'pl.import_into'()

  self.CFG_strTestName = strTestName

  self.CFG_aParameterDefinitions = {
    {
      name="script",
      default=nil,
      help="The file name of the TCL script to execute.",
      mandatory=true,
      validate=nil,
      constrains=nil
    }
  }
end



function TestClassOpenOCD:run(aParameters, tLog)
  ----------------------------------------------------------------------
  --
  -- Parse the parameters and collect all options.
  --
  local openocd = require 'luaopenocd'

  -- Read the TCL script.
  local strFileName = self.pl.path.exists(aParameters['script'])
  if strFileName==nil then
    tLog.error('The TCL script "%s" does not exist.', aParameters['script'])
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
