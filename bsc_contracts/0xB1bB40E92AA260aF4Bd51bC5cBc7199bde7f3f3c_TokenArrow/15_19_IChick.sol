// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Interface
//---------------------------------------------------------
interface IChick
{
	function make_juice(address _address_token) external;
	function set_operator(address _new_operator) external;
	function set_address_token(address _address_arrow, address _address_target) external;
	function set_bnb_per_busd_vault_ratio(uint256 _bnd_ratio) external;
	function set_swap_threshold(uint256 _threshold) external;
	function handle_stuck(address _address_token, uint256 _amount, address _to) external;
}