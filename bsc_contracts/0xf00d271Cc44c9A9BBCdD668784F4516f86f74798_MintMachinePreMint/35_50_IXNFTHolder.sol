// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Interface
//---------------------------------------------------------
interface IXNFTHolder
{
	function deposit(uint256 _pool_id, address _address_user, uint256 _xnft_id) external;
	function withdraw(uint256 _pool_id, address _address_user, uint256 _xnft_id) external;
	function balanceOf(uint256 _pool_id, address _address_user) external view returns(uint256);
	function get_pool_tvl_boost_rate_e6(uint256 _pool_id) external view returns(uint256);
	function get_user_tvl_boost_rate_e6(uint256 _pool_id, address _address_user) external view returns(uint256);
	function has_nft(address _address_user) external view returns(bool);
	function set_operator(address _new_operator) external;
	function set_boost_rate(uint256 level, uint256 _level_prefix, uint256 _tvl_boost_rate_e6) external;
}