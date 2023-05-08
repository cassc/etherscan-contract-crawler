// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Interface
//---------------------------------------------------------
interface IXNFTHolder
{
	function deposit_nfts(uint256 _pool_id, uint256[] memory _xnft_ids) external returns(uint256);
	function withdraw_nfts(uint256 _pool_id, uint256[] memory _xnft_ids) external returns(uint256);
	function refresh_pool_boost_rate(uint256 _pool_id) external;
	function emergency_withdraw_nft(uint256 _pool_id) external;
	function handle_stuck_nft(address _address_user, address _address_nft, uint256 _nft_id, uint256 _amount) external;
	function set_boost_rate_e6(uint256 grade, uint256 _tvl_boost_rate_e6) external;
	function get_pool_tvl_boost_rate_e6(uint256 _pool_id) external view returns(uint256);
	function get_user_tvl_boost_rate_e6(uint256 _pool_id, address _address_user) external view returns(uint256);
	function get_deposit_nft_amount(uint256 _pool_id) external view returns(uint256);
	function get_deposit_nft_list(uint256 _pool_id) external view returns(uint256[] memory);
	function set_operator(address _new_operator) external;
	function user_total_staked_amount(address _address_user) external view returns(uint256);
}