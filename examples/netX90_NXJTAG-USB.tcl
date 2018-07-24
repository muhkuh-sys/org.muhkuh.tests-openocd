proc read_data32 {addr} {
  set value(0) 0
  mem2array value 32 $addr 1
  return $value(0)
}

proc probe {} {
  global SC_CFG_RESULT
  set SC_CFG_RESULT 0
  set RESULT -1

  # Setup the interface.
  interface ftdi
  transport select jtag
  ftdi_device_desc "NXJTAG-USB"
  ftdi_vid_pid 0x1939 0x0023
  adapter_khz 1000
  ftdi_layout_init 0x0308 0x030b
  ftdi_layout_signal nTRST -data 0x0100 -oe 0x0100
  ftdi_layout_signal nSRST -data 0x0200 -oe 0x0200

  # Expect a netX90 scan chain.
  jtag newtap netx90 dap -expected-id 0x6ba00477 -irlen 4 -enable
  jtag newtap netx90 tap -expected-id 0x102046ad -irlen 4 -enable
  jtag configure netx90.dap -event setup { global SC_CFG_RESULT ; echo {Yay - setup netx 90} ; set SC_CFG_RESULT {OK} }

  # Expect working SRST and TRST lines.
  reset_config trst_and_srst

  # Try to initialize the JTAG layer.
  if {[ catch {jtag init} ]==0 } {
    if { $SC_CFG_RESULT=={OK} } {
      target create netx90.comm cortex_m -chain-position netx90.dap -coreid 0 -ap-num 2
      netx90.comm configure -event reset-init { halt }
      cortex_m reset_config srst

      init

      # Try to stop the CPU.
      halt

      # Write a register which will be initialized by a reset.
      # Stop GPIO counter 0 and use its "MAX" register as a scratchpad.
      mww 0xff001420 0x00000000
      mww 0xff001424 0x12345678
      set readbackvalue [read_data32 0xff001424]
      echo [format "Readback value before reset: 0x%08x" $readbackvalue ]
      if { $readbackvalue!={0x12345678} } {
        echo {Failed to set a register on the netX.}
      } else {
        # irscan netx90.dap 0xe
        # set val [drscan netx90.dap 16 0x0000 -endstate DRPAUSE]
        # echo [format "DR %s" $val]
        # set val [drscan netx90.dap 16 0x0000]
        # echo [format "DR %s" $val]

        # Reset the JTAG part of the CPU.
        echo {Trying TRST}
        jtag_reset 1 0
        sleep 100
        jtag_reset 0 0

        # TODO: Test TRST somehow.

        set readbackvalue [read_data32 0xff001424]
        echo [format "Readback value after TRST: 0x%08x" $readbackvalue ]
        if { $readbackvalue!={0x12345678} } {
          echo {The CPU register did not survive a SRST. Is TRST and SRST connected?}
        } else {
          # Reset the board.
          echo {Trying SRST}
          jtag_reset 0 1
          sleep 100
          jtag_reset 0 0

          set readbackvalue [read_data32 0xff001424]
          echo [format "Readback value after reset: 0x%08x" $readbackvalue ]
          if { $readbackvalue=={0x00000000} } {
            set RESULT 0
          }
        }
      }
    }
  }

  return $RESULT
}

probe
