----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:01:56 05/16/2015 
-- Design Name: 
-- Module Name:    datapath_module - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.all;										

entity datapath_module is
    Port (  --in
				clk : in STD_LOGIC;
				instruction_in : in  STD_LOGIC_VECTOR (31 downto 0);				--befehl aus befehlsspeicher
				pc_inc_in : in  STD_LOGIC_VECTOR (31 downto 0);						--der um 4 erh�hte Befehlsz�hler
				
				--in steuersignale
				--ex
				reg_dst_ctrl_in : in STD_LOGIC;											--entscheided, ob rd oder rt feld als write addr f�r des regfile genutzt wird											
				alu_src_in : in STD_LOGIC;
				alu_op_in : in STD_LOGIC_VECTOR (1 downto 0);
				--mem
				mem_write_in : in STD_LOGIC;
				mem_read_in : in STD_LOGIC;
				branch_in : in STD_LOGIC;													--wenn brach und zero ausgang der alu beide 1 sind, wird gesprungen
				--wb
				mem_to_reg_in : in STD_LOGIC;	
				mem_reg_write_in : in STD_LOGIC;				
			  
			   --out
			   instruction_out : out STD_LOGIC_VECTOR (31 downto 0);		   	--befehl, der ans Steuerwerk geht
				pc_src : out STD_LOGIC);													--ausgang f�r den muxer vor dem program counter, der bei sprung die quelle ausw�hlt
end datapath_module;

	----------------------------------------------------------------------------------------------------------
	--Architecture			  
	----------------------------------------------------------------------------------------------------------

architecture Behavioral of datapath_module is

	--ifid output signals
	signal ifid_pc_out : STD_LOGIC_VECTOR (31 downto 0);
	signal ifid_instruc_out : STD_LOGIC_VECTOR (31 downto 0);

	--regfile output signals
	signal read_data1_out : STD_LOGIC_VECTOR (31 downto 0);
	signal read_data2_out : STD_LOGIC_VECTOR (31 downto 0);

	--sign extension output signals
	signal sign_extended_out : STD_LOGIC_VECTOR (31 downto 0);
	
	--idex output signals
	signal idex_read_data1_out : STD_LOGIC_VECTOR (31 downto 0);
	signal idex_read_data2_out : STD_LOGIC_VECTOR (31 downto 0);
	signal idex_sign_extended_out : STD_LOGIC_VECTOR (31 downto 0);
	signal idex_write_address_rt_out : STD_LOGIC_VECTOR (31 downto 0);
	signal idex_write_address_rd_out : STD_LOGIC_VECTOR (31 downto 0);
	signal idex_program_counter_out : STD_LOGIC_VECTOR (31 downto 0);	
	signal idex_reg_dst_ctrl_out : STD_LOGIC;											--out steuersignale (ex)	
	signal idex_alu_src_out : STD_LOGIC;
	signal idex_alu_op_out : STD_LOGIC_VECTOR (1 downto 0);	
	signal idex_mem_write_out : STD_LOGIC;												--mem
	signal idex_mem_read_out : STD_LOGIC;
	signal idex_branch_out : STD_LOGIC;	
	signal idex_mem_to_reg_out : STD_LOGIC;											--wb
	signal idex_reg_write_out : STD_LOGIC;
	
	--alu control output signals
	signal alu_control_sig_out : STD_LOGIC_VECTOR (3 downto 0);
	
	--alu src muxer output signals
	signal alu_src_mux_out : STD_LOGIC_VECTOR (31 downto 0);
	
	--alu output signals
	signal alu_result_out : STD_LOGIC_VECTOR (31 downto 0);
	signal alu_zero_out : STD_LOGIC;
	
	--reg dst muxer output signals
	signal reg_dst_mux_out : STD_LOGIC_VECTOR (4 downto 0);
	
	--jump_addr_calc output signals
	signal jump_addr_calc_out : STD_LOGIC_VECTOR (31 downto 0);
	
	--exmem output signals
	signal exmem_jump_addr_out : STD_LOGIC_VECTOR (31 downto 0);
	signal exmem_alu_zero_out : STD_LOGIC;
	signal exmem_alu_result_out : STD_LOGIC_VECTOR (31 downto 0);
	signal exmem_write_data_out : STD_LOGIC_VECTOR (31 downto 0);
	signal exmem_reg_dst_addr_out : STD_LOGIC_VECTOR (4 downto 0);	
	signal exmem_mem_write_out : STD_LOGIC;											--steuersignale(mem)
	signal exmem_mem_read_out : STD_LOGIC;
	signal exmem_branch_out : STD_LOGIC;					
	signal exmem_mem_to_reg_out : STD_LOGIC;											--wb
	signal exmem_reg_write_out : STD_LOGIC;
	
	--data_storage output signals
	signal data_storage_read_data_out : STD_LOGIC_VECTOR (31 downto 0);
	
	--memwb output signals
	signal memwb_read_data_out : STD_LOGIC_VECTOR (31 downto 0);
	signal memwb_alu_result_out : STD_LOGIC_VECTOR (31 downto 0);
	signal memwb_reg_dst_addr_out : STD_LOGIC_VECTOR (4 downto 0);
	signal memwb_mem_to_reg_out : STD_LOGIC;			  
	signal memwb_reg_write_out : STD_LOGIC;
	
	--mem to reg muxer output signals
	signal mem_to_reg_mux_out : STD_LOGIC_VECTOR (31 downto 0);

begin
	ifid_reg : entity work.ifid_pipeline_reg 											--ifid_pipeline_reg
	port map ( program_counter_in => pc_inc_in,
				  instruction_in => instruction_in,
				  program_counter_out => ifid_pc_out,
				  instruction_out => ifid_instruc_out,
				  clk => clk);
				  
	regfile : entity work.register_file 												--regfile
   port map ( read_address1_in => ifid_instruc_out (25 downto 21),
				  read_address2_in => ifid_instruc_out (20 downto 16),
				  write_address_in => memwb_reg_dst_addr_out,
				  write_data_in    => mem_to_reg_mux_out,
				  read_data1_out   => read_data1_out,
				  read_data2_out   => read_data2_out,
				  clk              => clk,
				  --Steuersignale
				  reg_write_in 	 => memwb_reg_write_out);	

	sign_extend : entity work.sign_extension 											--sign extension
   port map ( imm =>  ifid_instruc_out (15 downto 0),
              imm_ext => sign_extended_out);
				  
	idex_reg : entity work.idex_pipeline_reg 											--idex pipeline reg
   port map ( clk => clk,
				  --in
				  read_data1_in => read_data1_out,
				  read_data2_in => read_data2_out,
				  sign_extended_in => sign_extended_out,
				  write_address_rt_in => ifid_instruc_out(20 downto 16),
				  write_address_rd_in => ifid_instruc_out(15 downto 11),
				  program_counter_in => ifid_pc_out,			  
				  
				  --in steuersignale(kommen direkt von eing�ngen des datenpfad moduls, also von der steuereinheit)
				  --ex
				  reg_dst_ctrl_in => reg_dst_ctrl_in,									--entscheided, ob rd oder rt feld als write addr f�r des regfile genutzt wird											
				  alu_src_in => alu_src_in,
				  alu_op_in => alu_op_in,
				  --mem
				  mem_write_in => mem_write_in,
				  mem_read_in => mem_read_in,
				  branch_in => branch_in,													--wenn brach und zero ausgang der alu beide 1 sind, wird gesprungen
				  --wb
				  mem_to_reg_in => mem_to_reg_in,
				  reg_write_in => mem_reg_write_in,
				  
				  --out
				  read_data1_out => idex_read_data1_out,						
				  read_data2_out => idex_read_data2_out,
				  sign_extended_out => idex_sign_extended_out,
				  write_address_rt_out => idex_write_address_rt_out,
				  write_address_rd_out => idex_write_address_rd_out,
				  program_counter_out => idex_program_counter_out,				  
				  			  
				  --out steuersignale
				  --ex
				  reg_dst_ctrl_out => idex_reg_dst_ctrl_out,
				  alu_src_out => idex_alu_src_out,
				  alu_op_out => idex_alu_op_out,
				  --mem
				  mem_write_out => idex_mem_write_out,
				  mem_read_out => idex_mem_read_out,
				  branch_out => idex_branch_out,
				  --wb
				  mem_to_reg_out => idex_mem_to_reg_out,
				  reg_write_out => idex_reg_write_out);
		
	alu_ctrl : entity work.alu_control													--alu control
   port map ( alu_op => idex_alu_op_out,						
              funct => idex_sign_extended_out(5 downto 0),						--die untersten 6 bits entsprechen auch immer funct
              alu_control_sig => alu_control_sig_out);
				  
	alu_src_mux : entity work.mux2_32 													--alu src muxer
   port map ( x_0 => idex_read_data2_out,
              x_1 => idex_sign_extended_out,
              control => idex_alu_src_out,
              y => alu_src_mux_out);			  
					
	alu : ENTITY work.alu32 																--alu
	PORT map (  CTRL => alu_control_sig_out,
					A => idex_read_data1_out,
					B => alu_src_mux_out,
					S => alu_result_out,
					ZERO => alu_zero_out);
	
	reg_dst_mux : entity work.mux2_5 													--reg destination muxer: entscheided ob rt oder rd als write address verwendet wird
   port map ( x_0 => idex_write_address_rt_out,
              x_1 => idex_write_address_rd_out,
              control => idex_reg_dst_ctrl_out,
              y => reg_dst_mux_out);
				  
	jump_addr_calc : entity work.jump_addr_calc
   port map( pc_inc_in => idex_program_counter_out,
             offset => idex_sign_extended_out,
             pc_out => jump_addr_calc_out);
				 
	
	exmem_reg : entity work.exmem_pipeline_reg										--exmem pipeline reg
	port map(--in
				clk => clk,
				jump_addr_in => jump_addr_calc_out,
				alu_zero_in  => alu_zero_out,
				alu_result_in => alu_result_out,
				write_data_in => idex_read_data2_out,
				reg_dst_addr_in => reg_dst_mux_out,

				--steuersignale
				--mem
				mem_write_in => idex_mem_write_out,
				mem_read_in  => idex_mem_read_out,
				branch_in  => idex_branch_out,
				--wb
				mem_to_reg_in => idex_mem_to_reg_out,
				reg_write_in => idex_reg_write_out,
				

				--out
				jump_addr_out => exmem_jump_addr_out,
				alu_zero_out => exmem_alu_zero_out,
				alu_result_out => exmem_alu_result_out,
				write_data_out => exmem_write_data_out,
				reg_dst_addr_out => exmem_reg_dst_addr_out,

				--steuersignale
				--mem
				mem_write_out => exmem_mem_write_out,
				mem_read_out => exmem_mem_read_out,
				branch_out => exmem_branch_out,
				--wb
				mem_to_reg_out => exmem_mem_to_reg_out,
				reg_write_out => exmem_reg_write_out);
				
	data_storage : entity work.data_storage											--data storage (muss noch implementiert werden)
   port map ( --in
				  address_in => exmem_alu_result_out,
				  write_data_in => exmem_write_data_out,
				  --steuersignale
				  mem_read_in => exmem_mem_read_out,
				  mem_write_in => exmem_mem_read_out,
				  
				  --out
				  read_data_out => data_storage_read_data_out);
				  
	memwb_reg : entity work.memwb_pipeline_reg 										--memwb pipeline reg
   port map ( --in
				  clk => clk,
				  read_data_in => data_storage_read_data_out,
				  alu_result_in => alu_result_out,
				  reg_dst_addr_in => exmem_reg_dst_addr_out,
				  mem_to_reg_in => exmem_mem_to_reg_out,
				  reg_write_in => exmem_reg_write_out,			  
				  
				  --out
				  read_data_out => memwb_read_data_out,
				  alu_result_out => memwb_alu_result_out,
				  reg_dst_addr_out => memwb_reg_dst_addr_out,
				  mem_to_reg_out => memwb_mem_to_reg_out,
				  reg_write_out => memwb_reg_write_out);	
	
	mem_to_reg_mux : entity work.mux2_32 													--mem to reg muxer
   port map ( x_0 => memwb_read_data_out,
              x_1 => memwb_alu_result_out,
              control => memwb_mem_to_reg_out,
              y => mem_to_reg_mux_out);	
				  
	----------------------------------------------------------------------------------------------------------
	--Instanziierung Ende			  
	----------------------------------------------------------------------------------------------------------			  
	instruction_out <= ifid_instruc_out;												--geht nach ifid_reg an steuerwerk
	pc_src <= exmem_branch_out AND alu_zero_out;
	
end Behavioral;

