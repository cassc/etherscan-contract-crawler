// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Interface
//---------------------------------------------------------
interface ITokenXBaseV3
{
	function set_chick(address _new_chick) external;
	function set_chick_work(bool _is_work) external;

	function toggle_block_send(address[] memory _accounts, bool _is_blocked) external;
	function toggle_block_recv(address[] memory _accounts, bool _is_blocked) external;

	function mint(address _to, uint256 _amount) external;
	function burn(uint256 _amount) external;
}