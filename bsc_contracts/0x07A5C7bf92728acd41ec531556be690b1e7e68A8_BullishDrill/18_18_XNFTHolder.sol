// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.11;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract XNFTHolder is Pausable, ERC1155Holder
{
	struct GradeInfo
	{
		uint256 grade_prefix;
		uint256 tvl_boost_rate_e6;
	}

	struct UserNFTInfo
	{
		mapping(uint256 => bool) xnft_exist;
		uint256[] used_xnft_ids;
		uint256 xnft_amount;
		uint256 tvl_boost_rate_e6;
	}

	struct PoolNFTInfo
	{
		uint256 tvl_boost_rate_e6;
		address[] address_user_list;
		mapping(address => UserNFTInfo) user_info; // user_adddress / user_info
	}

	address public address_operator;
	address public address_nft;

	mapping(uint256 => GradeInfo) public grade_info; // grade_id(1, 2, 3...) / grade_info
	mapping(uint256 => PoolNFTInfo) public pool_nft_info; // pool_id / pool_nft_info

	uint256 public constant MAX_POOL_COUNT = 50; 

	//---------------------------------------------------------------
	// Front-end connectors
	//---------------------------------------------------------------
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

	function _deposit_nft(uint256 _pool_id, uint256 _xnft_id) internal 
	{
		require(msg.sender != address(0), "get_deposit_list: Wrong sender address");

		address _address_user = msg.sender;
		PoolNFTInfo storage pool = pool_nft_info[_pool_id];
		UserNFTInfo storage user = pool.user_info[_address_user];

		// User -> Holder
		IERC1155 stake_token = IERC1155(address_nft);
		stake_token.safeTransferFrom(_address_user, address(this), _xnft_id, 1, "");

		uint256 boost_rate = _get_nft_boost_rate(_xnft_id);
		pool.tvl_boost_rate_e6 += boost_rate;

		if(user.used_xnft_ids.length == 0)
			pool.address_user_list.push(_address_user);

		user.xnft_exist[_xnft_id] = true;
		user.xnft_amount += 1;
		user.tvl_boost_rate_e6 += boost_rate;
		user.used_xnft_ids.push(_xnft_id);
	}

	function _deposit_nfts(uint256 _pool_id, uint256[] memory _xnft_ids) internal returns(uint256)
	{
		for(uint256 i=0; i<_xnft_ids.length; i++)
			_deposit_nft(_pool_id, _xnft_ids[i]);

		return _xnft_ids.length;
	}

	function _withdraw_nft(uint256 _pool_id, uint256 _xnft_id) internal
	{
		require(IERC1155(address_nft).balanceOf(address(this), _xnft_id) > 0, "_withdraw_nfts: does not own NFT");
		require(msg.sender != address(0), "_withdraw_nft: Wrong sender address");

		address _address_user = msg.sender;
		PoolNFTInfo storage pool = pool_nft_info[_pool_id];
		UserNFTInfo storage user = pool.user_info[_address_user];
		require(user.xnft_amount > 0, "_withdraw_nft: insufficient amount");

		// Holder -> User
		IERC1155 stake_token = IERC1155(address_nft);
		stake_token.safeTransferFrom(address(this), _address_user, _xnft_id, 1, "");

		uint256 boost_rate = _get_nft_boost_rate(_xnft_id);
		pool.tvl_boost_rate_e6 -= boost_rate;

		user.xnft_exist[_xnft_id] = false;
		user.xnft_amount -= 1;
		user.tvl_boost_rate_e6 -= boost_rate;
	}
	
	function _withdraw_nfts(uint256 _pool_id, uint256[] memory _xnft_ids) internal returns(uint256)
	{
		for(uint256 i=0; i<_xnft_ids.length; i++)
			_withdraw_nft(_pool_id, _xnft_ids[i]);

		return _xnft_ids.length;
	}
	
	function get_deposit_nft_list(uint256 _pool_id) public view returns(uint256[] memory) 
	{
		require(msg.sender != address(0), "get_deposit_list: Wrong sender address");

		address _address_user = msg.sender;
		PoolNFTInfo storage pool = pool_nft_info[_pool_id];
		UserNFTInfo storage user = pool.user_info[_address_user];
		if(user.xnft_amount == 0)
			return new uint256[](0);

		uint256 cur_len = 0;
		uint256[] memory id_list = new uint256[](user.xnft_amount);
		for(uint256 i=0; i<user.used_xnft_ids.length; i++)
		{
			uint256 nft_id = user.used_xnft_ids[i];
			if(user.xnft_exist[nft_id] == true)
			{
				id_list[cur_len] = nft_id;
				cur_len += 1;
			}
		}

		return id_list;
	}

	function emergency_withdraw_nft(uint256 _pool_id) internal
	{
		require(msg.sender != address(0), "get_deposit_list: Wrong sender address");

		address _address_user = msg.sender;
		PoolNFTInfo storage pool = pool_nft_info[_pool_id];
		UserNFTInfo storage user = pool.user_info[_address_user];
		require(user.xnft_amount > 0, "emergency_withdraw_nft: insufficient amount");

		IERC1155 stake_token = IERC1155(address_nft);
		uint256[] memory xnft_ids = get_deposit_nft_list(_pool_id);
		for(uint256 i=0; i<xnft_ids.length; i++)
		{
			// Holder -> User
			stake_token.safeTransferFrom(address(this), _address_user, xnft_ids[i], 1, "");
			user.xnft_exist[xnft_ids[i]] = false;
			
			uint256 boost_rate = _get_nft_boost_rate(xnft_ids[i]);
			pool.tvl_boost_rate_e6 -= boost_rate;
		}

		user.xnft_amount = 0;
		user.tvl_boost_rate_e6 = 0;
	}

	function handle_stuck_nft(address _address_user, address _address_nft, uint256 _nft_id, uint256 _amount) public onlyOperator
	{
		require(_address_user != address(0), "handle_stuck_nft: Wrong sender address");
		require(_address_nft != address_nft, "handle_stuck_nft: Wrong token address");
		require(_nft_id > 0, "handle_stuck_nft: Invalid NFT id");
		require(_amount > 0, "handle_stuck_nft: Invalid amount");

		IERC1155 nft = IERC1155(address_nft);

		require(nft.balanceOf(address(this), _nft_id) >= _amount, "handle_stuck_nft: does not own enough NFTs");
		require(nft.isApprovedForAll(address(this), address_nft) == true, "handle_stuck_nft: Not approved for all");
				
		nft.safeTransferFrom(address(this), _address_user, _nft_id, _amount, "");
	}

	//---------------------------------------------------------------
	// Variable Interfaces
	//---------------------------------------------------------------
	//function set_boost_rate_e6(uint256 grade, uint256 _tvl_boost_rate_e6) external onlyOperator whenPaused
	function set_boost_rate_e6(uint256 grade, uint256 _tvl_boost_rate_e6) external onlyOperator
	{
		GradeInfo storage cur_grade_info = grade_info[grade];
		cur_grade_info.grade_prefix = grade * 1e6;
		cur_grade_info.tvl_boost_rate_e6 = _tvl_boost_rate_e6;

		_refresh_pool_boost_rate();
	}

	function get_pool_tvl_boost_rate_e6(uint256 _pool_id) public view returns(uint256)
	{
		PoolNFTInfo storage pool = pool_nft_info[_pool_id];
		return pool.tvl_boost_rate_e6;
	}

	function get_user_tvl_boost_rate_e6(uint256 _pool_id, address _address_user) public view returns(uint256)
	{
		PoolNFTInfo storage pool = pool_nft_info[_pool_id];
		UserNFTInfo storage user = pool.user_info[_address_user];
		return user.tvl_boost_rate_e6;
	}
	
	function set_operator(address _new_operator) external onlyOperator
	{
		require(_new_operator != address(0), "set_operator: Wrong address");
		address_operator = _new_operator;
		emit SetOperatorCB(msg.sender, _new_operator);
	}

	//---------------------------------------------------------------
	// Internal Method
	//---------------------------------------------------------------
	function _get_nft_grade(uint256 _xnft_id) internal view returns(uint256)
	{
		for(uint256 grade=2; grade<127; grade++)
		{
			if(grade_info[grade].grade_prefix == 0 || grade_info[grade].grade_prefix > _xnft_id)
				return grade-1;
		}

		return 1;
	}

	function _get_nft_boost_rate(uint256 _xnft_id) internal view returns(uint256)
	{
		uint256 grade = _get_nft_grade(_xnft_id);
		return grade_info[grade].tvl_boost_rate_e6;
	}
	
	//function _refresh_pool_boost_rate() internal whenPaused
	function _refresh_pool_boost_rate() internal
	{
		for(uint256 _pool_id=0; _pool_id<MAX_POOL_COUNT; _pool_id++)
		{
			PoolNFTInfo storage pool = pool_nft_info[_pool_id];
			if(pool.address_user_list.length == 0)
				continue;
		
			pool.tvl_boost_rate_e6 = 0;
			for(uint256 i=0; i < pool.address_user_list.length; i++)
			{
				UserNFTInfo storage user = pool.user_info[pool.address_user_list[i]];
				if(user.xnft_amount == 0)
					continue;

				user.tvl_boost_rate_e6 = 0;
				for(uint256 j=0; j<user.used_xnft_ids.length; j++)
				{
					uint256 nft_id = user.used_xnft_ids[j];
					if(user.xnft_exist[nft_id] == true)
					{
						uint256 boost_rate = _get_nft_boost_rate(nft_id);
						user.tvl_boost_rate_e6 += boost_rate;
					}
				}
				
				pool.tvl_boost_rate_e6 += user.tvl_boost_rate_e6;
			}
		}
	}
}