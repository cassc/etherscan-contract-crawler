// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Interface
//---------------------------------------------------------
interface ICakeBaker
{
	function add_pancake_farm(uint256 _pancake_pool_id, address _address_lp) external returns(uint256);
	function delegate(address _from, address _address_lp, uint256 _amount) external returns(uint256);
	function retain(address _to, address _address_lp, uint256 _amount) external returns(uint256);
	function harvest() external;
	function handle_stuck(address _token, uint256 _amount, address _to) external;
	function set_address_reward_vault(address _new_address) external;
	function set_operator(address _new_address) external;
	function set_controller(address _new_controller) external;
}