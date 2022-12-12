// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Interface
//---------------------------------------------------------
interface IBullish
{
	function set_chick(address _new_address) external;
	function set_cakebaker(address _new_address) external;
	function set_operator(address _new_operator) external;
	function set_xnft_address(address _address_xnft) external;
	function get_pool_count() external returns(uint256);
	function set_deposit_fee(uint256 _pool_id, uint16 _fee) external;
	function set_withdrawal_fee(uint256 _pool_id, uint16 _fee_max, uint16 _fee_min, uint256 _period) external;
	function set_alloc_point(uint256 _pool_id, uint256 _alloc_point, bool _update_all) external;
	function set_emission_per_block(address _address_reward, uint256 _emission_per_block) external;
	function make_reward(address _address_reward_token, uint256 _reward_mint_start_block_id) external;
	function add_nft_booster(uint256 _pool_id, uint256 _nft_id) external;
	function remove_nft_booster(uint256 _pool_id, uint256 _nft_id) external;
	function get_nft_booster_list(uint256 _pool_id) external returns(uint256[] memory);
	function has_nft(address _address_user) external view returns(bool);
	function get_pending_reward_amount(uint256 _pool_id, address _address_user) external returns(uint256);
	function pause() external;
	function resume() external;
}