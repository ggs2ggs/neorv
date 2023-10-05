-- #################################################################################################
-- # << NEORV32 - Processor-internal bootloader ROM (BOOTROM) >>                                   #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2023, Stephan Nolting. All rights reserved.                                     #
-- #                                                                                               #
-- # Redistribution and use in source and binary forms, with or without modification, are          #
-- # permitted provided that the following conditions are met:                                     #
-- #                                                                                               #
-- # 1. Redistributions of source code must retain the above copyright notice, this list of        #
-- #    conditions and the following disclaimer.                                                   #
-- #                                                                                               #
-- # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
-- #    conditions and the following disclaimer in the documentation and/or other materials        #
-- #    provided with the distribution.                                                            #
-- #                                                                                               #
-- # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
-- #    endorse or promote products derived from this software without specific prior written      #
-- #    permission.                                                                                #
-- #                                                                                               #
-- # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
-- # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
-- # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
-- # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
-- # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
-- # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
-- # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
-- # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
-- # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
-- # ********************************************************************************************* #
-- # The NEORV32 Processor - https://github.com/stnolting/neorv32              (c) Stephan Nolting #
-- #################################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;
use neorv32.neorv32_bootloader_image.all; -- this file is generated by the image generator

entity neorv32_boot_rom is
  port (
    clk_i     : in  std_ulogic; -- global clock line
    bus_req_i : in  bus_req_t;  -- bus request
    bus_rsp_o : out bus_rsp_t   -- bus response
  );
end neorv32_boot_rom;

architecture neorv32_boot_rom_rtl of neorv32_boot_rom is

  -- determine required ROM size in bytes (expand to next power of two) --
  constant boot_rom_size_index_c : natural := index_size_f((bootloader_init_image'length)); -- address with (32-bit entries)
  constant boot_rom_size_c       : natural := (2**boot_rom_size_index_c)*4; -- physical size in bytes

  -- local signals --
  signal rden  : std_ulogic;
  signal rdata : std_ulogic_vector(31 downto 0);

  -- ROM - initialized with executable code --
  constant mem_rom : mem32_t(0 to boot_rom_size_c/4-1) := mem32_init_f(bootloader_init_image, boot_rom_size_c/4);

begin

  -- Sanity Checks --------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  assert false report
    "NEORV32 PROCESSOR CONFIG NOTE: Implementing internal bootloader ROM (" & natural'image(boot_rom_size_c) & " bytes)." severity note;
  assert not (boot_rom_size_c > mem_boot_size_c) report
    "NEORV32 PROCESSOR CONFIG ERROR! Boot ROM size out of range! Max " & natural'image(mem_boot_size_c) & " bytes." severity error;


  -- Memory Access --------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  mem_file_access: process(clk_i)
  begin
    if rising_edge(clk_i) then
      rden  <= bus_req_i.stb and (not bus_req_i.rw); -- read-only
      rdata <= mem_rom(to_integer(unsigned(bus_req_i.addr(boot_rom_size_index_c+1 downto 2))));
    end if;
  end process mem_file_access;

  -- response --
  bus_rsp_o.data <= rdata when (rden = '1') else (others => '0'); -- output gate
  bus_rsp_o.ack  <= rden;
  bus_rsp_o.err  <= '0';


end neorv32_boot_rom_rtl;
