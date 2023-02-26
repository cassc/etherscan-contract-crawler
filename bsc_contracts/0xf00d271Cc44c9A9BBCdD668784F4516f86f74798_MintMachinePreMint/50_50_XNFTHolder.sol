// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract XNFTHolder is ReentrancyGuard, Pausable, ERC1155Holder
{
	struct LevelInfo
	{
		uint256 level_prefix;
		uint256 tvl_boost_rate_e6;
	}

	struct UserInfo
	{
		mapping(uint256 => bool) xnft_id_list;
		uint256 xnft_amount;
		uint256 tvl_boost_rate_e6;
	}

	struct PoolInfo
	{
		uint256 tvl_boost_rate_e6;
		mapping(address => UserInfo) user_info; // user_adddress / user_info
	}
	
	//uint256[] tvl_boost_rate_e6 = [300, 600, 900];
	//uint256[] xnft_level_prefix = [1000000, 2000000, 3000000];

	address public address_operator;
	address public address_nft;

	mapping(uint256 => LevelInfo) public level_info; // level_id(1, 2, 3...) / level_info
	mapping(uint256 => PoolInfo) public pool_info; // pool_id / pool_info
	mapping(uint256 => bool) public is_deposited; // xnft_id / is_staked
	mapping(address => bool) public has_xnft; // user_address / has_nft

	//---------------------------------------------------------------
	// Front-end connectors
	//---------------------------------------------------------------
	event DepositCB(address indexed user, uint256 _xnft_id);
	event WithdrawCB(address indexed user, uint256 _xnft_id);
	event SetOperatorCB(address indexed operator, address _new_operator);

	//---------------------------------------------------------------
	// Modifier
	//---------------------------------------------------------------
	modifier onlyOperator() { require(msg.sender == address_operator, "onlyOperator: not authorized"); _; }

	//---------------------------------------------------------------
	// External Method
	//---------------------------------------------------------------
	constructor(address _address_nft)
	{
		address_operator = msg.sender;
		address_nft = _address_nft;
	}

	function deposit(uint256 _pool_id, address _address_user, uint256 _xnft_id) external whenNotPaused nonReentrant
	{
		require(is_deposited[_xnft_id] == false, "deposit: already deposited xnft");

		PoolInfo storage pool = pool_info[_pool_id];
		UserInfo storage user = pool.user_info[_address_user];
		require(user.xnft_id_list[_xnft_id] == false, "deposit: already deposited xnft");

		// User -> Bullish Booster
		IERC1155 stake_token = IERC1155(address_nft);
		stake_token.safeTransferFrom(_address_user, address(this), _xnft_id, 1, "");

		uint256 level = _get_nft_level(_xnft_id);
		pool.tvl_boost_rate_e6 += level_info[level].tvl_boost_rate_e6;

		user.xnft_id_list[_xnft_id] = true;
		user.xnft_amount += 1;
		user.tvl_boost_rate_e6 += level_info[level].tvl_boost_rate_e6;

		is_deposited[_xnft_id] = true;
		has_xnft[_address_user] = true;
		
		emit DepositCB(_address_user, _xnft_id);	
	}

	function withdraw(uint256 _pool_id, address _address_user, uint256 _xnft_id) external nonReentrant
	{
		require(is_deposited[_xnft_id] == true, "withdraw: not deposited xnft");

		PoolInfo storage pool = pool_info[_pool_id];
		UserInfo storage user = pool.user_info[_address_user];

		// Bullish Booster -> User
		IERC1155 stake_token = IERC1155(address_nft);
		stake_token.safeTransferFrom(address(this), _address_user, _xnft_id, 1, "");

		uint256 level = _get_nft_level(_xnft_id);
		pool.tvl_boost_rate_e6 -= level_info[level].tvl_boost_rate_e6;

		user.xnft_id_list[_xnft_id] = false;
		user.xnft_amount -= 1;
		user.tvl_boost_rate_e6 -= level_info[level].tvl_boost_rate_e6;

		is_deposited[_xnft_id] = false;
		has_xnft[_address_user] = (user.xnft_amount > 0);	

		emit WithdrawCB(_address_user, _xnft_id);
	}

	function balanceOf(uint256 _pool_id, address _address_user) external view returns(uint256)
	{
		PoolInfo storage pool = pool_info[_pool_id];
		UserInfo storage user = pool.user_info[_address_user];
		return user.xnft_amount;
	}

	function get_pool_tvl_boost_rate_e6(uint256 _pool_id) external view returns(uint256)
	{
		PoolInfo storage pool = pool_info[_pool_id];
		return pool.tvl_boost_rate_e6;
	}

	function get_user_tvl_boost_rate_e6(uint256 _pool_id, address _address_user) external view returns(uint256)
	{
		PoolInfo storage pool = pool_info[_pool_id];
		UserInfo storage user = pool.user_info[_address_user];
		return user.tvl_boost_rate_e6;
	}
	
	function has_nft(address _address_user) external view returns(bool)
	{
		return has_xnft[_address_user];
	}

	//---------------------------------------------------------------
	// Variable Interfaces
	//---------------------------------------------------------------
	function set_operator(address _new_operator) external onlyOperator
	{
		require(_new_operator != address(0), "set_operator: Wrong address");
		address_operator = _new_operator;
		emit SetOperatorCB(msg.sender, _new_operator);
	}

	function set_boost_rate(uint256 level, uint256 _level_prefix, uint256 _tvl_boost_rate_e6) external onlyOperator
	{
		LevelInfo storage cur_level_info = level_info[level];
		cur_level_info.level_prefix = _level_prefix;
		cur_level_info.tvl_boost_rate_e6 = _tvl_boost_rate_e6;
	}

	//---------------------------------------------------------------
	// Internal Method
	//---------------------------------------------------------------
	function _get_nft_level(uint256 _xnft_id) internal view returns(uint256)
	{
		for(uint256 level=2; level<127; level++)
		{
			if(level_info[level].level_prefix == 0 || level_info[level].level_prefix > _xnft_id)
				return level-1;
		}

		return 1;
	}
}