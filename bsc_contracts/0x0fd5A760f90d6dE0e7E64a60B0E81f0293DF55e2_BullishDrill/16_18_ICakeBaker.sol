// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Interface
//---------------------------------------------------------
interface ICakeBaker
{
	function set_address_reward_vault(address _new_address) external;
	function set_operator(address _new_address) external;
	function set_controller(address _new_address) external;
	function set_pancake_masterchef(address _new_address) external;
	function add_pancake_farm(uint256 _pool_id, address _address_lp, address _address_token_reward) external returns(uint256);
	function delegate(address _address_lp_vault, address _address_lp, uint256 _amount) external returns(uint256);
	function retain(address _address_lp_vault, address _address_lp, uint256 _amount) external returns(uint256);
	function harvest() external;
	function pause() external;
	function resume() external;
}