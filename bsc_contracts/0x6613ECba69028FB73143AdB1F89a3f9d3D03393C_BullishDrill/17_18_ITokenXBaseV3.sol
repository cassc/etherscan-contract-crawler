// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Interface
//---------------------------------------------------------
interface ITokenXBaseV3
{
	function mint(address _to, uint256 _amount) external;
	function burn(uint256 _amount) external;
	function set_operator(address _new_operator) external;
	function set_controller(address _new_controller, bool _is_set) external;
	function set_chick(address _new_chick) external;
	function set_chick_work(bool _is_work) external;
	function set_total_supply_limit(uint256 _amount) external;
	function set_tax_free(address _to, bool _is_free) external;
	function set_sell_amount_limit(address _address_to_limit, uint256 _limit) external;
	function toggle_block_send(address[] memory _accounts, bool _is_blocked) external;
	function toggle_block_recv(address[] memory _accounts, bool _is_blocked) external;
	function set_send_tax_e6(uint256 _tax_rate, uint256 _tax_with_nft_rate) external;
	function set_recv_tax_e6(uint256 _tax_rate, uint256 _tax_with_nft_rate) external;
	function set_address_xnft(address _address_xnft) external;
}