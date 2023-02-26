// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
interface IChick
{
	function pause() external;
	function resume() external;
	function set_address_vault(address _address_busd_vault, address _address_wbnb_vault) external;
	function set_address_token(address _address_arrow, address _address_target) external;
	function set_bnb_per_busd_vault_ratio(uint256 _bnd_ratio) external;
	function set_swap_threshold(uint256 _threshold) external;
	function handle_stuck(address _token, uint256 _amount, address _to) external;
	function make_juice() external;
}