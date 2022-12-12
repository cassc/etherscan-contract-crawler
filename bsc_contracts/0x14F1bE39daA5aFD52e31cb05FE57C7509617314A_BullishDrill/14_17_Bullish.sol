// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;
// You don't need SafeMath library for Solidity 0.8+. 

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./interfaces/ITokenXBaseV3.sol";
import "./interfaces/ICakeBaker.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract Bullish is ReentrancyGuard, Pausable, ERC1155Holder
{
	using SafeERC20 for IERC20;

	struct PoolInfo
	{
		address address_stake_token;
		address address_reward_token;
		
		uint256 harvest_interval;
		uint256 alloc_point;
		uint256 total_staked_amount;

		uint256 accu_reward_amount_per_share_e12;
		uint256 total_xnft_boost_rate_e4;
	}

	struct FeeInfo
	{
		uint256 deposit_e4; // 300 is 3%
		uint256 withdrawal_max_e4;
		uint256 withdrawal_min_e4;
		uint256 withdrawal_period; // decrease time from max to min
	}

	struct RewardInfo
	{
		uint256 start_block_id;
		uint256 last_rewarded_block_id;	
		uint256 emission_per_block;

		uint256 total_alloc_point;
		uint256 total_locked_amount;
	}

	struct UserInfo
	{
		uint256 staked_amount;
		uint256 paid_reward_amount;
		uint256 locked_reward_amount;

		uint256 last_deposit_time;
		uint256 next_harvest_time;

		uint256[] xnft_id_list; // APR booster
		uint256 xnft_boost_rate_e4; // 300 is 3%
	}

	uint256 public constant MAX_HARVEST_INTERVAL = 14 days;
	uint256 public constant MAX_DEPOSIT_FEE_E4 = 2000; // 20%
	uint256 public constant MIN_WITHDRAWAL_FEE_E4 = 0; // 0%
	uint256 public constant MAX_WITHDRAWAL_FEE_E4 = 2000; // 20%

	address public address_chick; // for tax
	address public address_operator;
	address public address_cakebaker; // for delegate farming at pancakeswap

	address public address_xnft;
	uint256[] xnft_level_prefix = [1000000, 2000000, 3000000];
	uint256[] xnft_boost_rate_e4 = [300, 600, 900];

	PoolInfo[] public pool_info; // pool_id / pool_info
	FeeInfo[] public fee_info; // pool_id / fee_info
	mapping(address => bool) public is_pool_exist;
	mapping(uint256 => mapping(address => UserInfo)) public user_info; // pool_id / user_adddress / user_info
	mapping(address => RewardInfo) public reward_info; // reward_address / reward_info

	//---------------------------------------------------------------
	// Front-end connectors
	//---------------------------------------------------------------
	event PauseCB(address indexed operator);
	event ResumeCB(address indexed operator);
	event SetChickCB(address indexed operator, address _controller);
	event SetCakeBakerCB(address indexed operator, address _controller);
	event UpdateEmissionRateCB(address indexed operator, uint256 _reward_per_block);
	event SetOperatorCB(address indexed operator, address _new_operator);
	event SetNFTBoosterCB(address indexed operator, address _address_xnft);
	event MakePoolCB(address indexed operator, uint256 new_pool_id);
	event SetPoolInfoCB(address indexed operator, uint256 _pool_id);
	
	event DepositCB(address indexed user, uint256 _pool_id, uint256 _amount);
	event WithdrawCB(address indexed user, uint256 _pool_id, uint256 _amount);
	event HarvestCB(address indexed user, uint256 _pool_id, uint256 _pending_reward_amount);
	event HarvestNotYetCB(address indexed user, uint256 _pool_id, uint256 _pending_reward_amount);

	event AddNFTBoosterCB(address indexed user, uint256 _nft_id);
	event RemoveNFTBoosterCB(address indexed user, uint256 _nft_id);
	event GetNFTBoosterListCB(address indexed user, uint256 _pool_id, uint256[] nft_id_list);
	event GetPendingRewardAmountCB(address indexed user, uint256 _pool_id, address _address_user, uint256 _pending_amount);
	
	event EmergencyWithdrawCB(address indexed user, uint256 _pool_id, uint256 _amount);
	event HandleStuckCB(address indexed user, uint256 _amount);

	//---------------------------------------------------------------
	// Modifier
	//---------------------------------------------------------------
	modifier uniquePool(address _address_lp) { require(is_pool_exist[_address_lp] == false, "uniquePool: duplicated"); _; }
	modifier onlyOperator() { require(msg.sender == address_operator, "onlyOperator: Not authorized"); _; }

	//---------------------------------------------------------------
	// Variable Interfaces
	//---------------------------------------------------------------
	function set_chick(address _new_address) external onlyOperator
	{
		require(_new_address != address(0), "set_chick: Wrong address");

		address_chick = _new_address;
		for(uint256 i=0; i<pool_info.length; i++)
		{
			ITokenXBaseV3 reward_token = ITokenXBaseV3(pool_info[i].address_reward_token);
			reward_token.set_chick(address_chick);
		}

		emit SetChickCB(msg.sender, _new_address);
	}

	function set_cakebaker(address _new_address) external onlyOperator
	{
		require(_new_address != address(0), "set_cakebaker: Wrong address");
		address_cakebaker = _new_address;
		
		emit SetCakeBakerCB(msg.sender, _new_address);
	}

	function set_operator(address _new_operator) external onlyOperator
	{
		require(_new_operator != address(0), "set_operator: Wrong address");
		address_operator = _new_operator;
		emit SetOperatorCB(msg.sender, _new_operator);
	}

	function set_xnft_address(address _address_xnft) external onlyOperator
	{
		require(_address_xnft != address(0), "set_xnft_address: Wrong address");
		address_xnft = _address_xnft;
		emit SetNFTBoosterCB(msg.sender, _address_xnft);
	}

	function get_pool_count() external view returns(uint256)
	{
		return pool_info.length;
	}

	function set_deposit_fee(uint256 _pool_id, uint16 _fee_e4) external onlyOperator
	{
		require(_pool_id < pool_info.length, "set_deposit_fee: Wrong pool id.");
		require(_fee_e4 <= MAX_DEPOSIT_FEE_E4, "set_deposit_fee: Maximun deposit fee exceeded.");

		FeeInfo storage cur_fee = fee_info[_pool_id];
		cur_fee.deposit_e4 = _fee_e4;
	}

	function set_withdrawal_fee(uint256 _pool_id, uint16 _fee_max_e4, uint16 _fee_min_e4, uint256 _period_sec) external onlyOperator
	{
		require(_pool_id < pool_info.length, "set_withdrawal_fee: Wrong pool id.");
		require(_fee_min_e4 >= MIN_WITHDRAWAL_FEE_E4, "set_withdrawal_fee: Minimun fee exceeded.");
		require(_fee_max_e4 <= MAX_WITHDRAWAL_FEE_E4, "set_withdrawal_fee: Maximun fee exceeded.");
		require(_fee_min_e4 <= _fee_max_e4, "set_withdrawal_fee: Wrong withdrawal fee");

		FeeInfo storage cur_fee = fee_info[_pool_id];
		cur_fee.withdrawal_max_e4 = _fee_max_e4;
		cur_fee.withdrawal_min_e4 = _fee_min_e4;
		cur_fee.withdrawal_period = _period_sec;
	}

	function set_alloc_point(uint256 _pool_id, uint256 _alloc_point, bool _update_all) external onlyOperator
	{
		require(_pool_id < pool_info.length, "set_alloc_point: Wrong pool id.");

		if(_update_all)
			refresh_reward_per_share();

		PoolInfo storage pool = pool_info[_pool_id];
		RewardInfo storage reward = reward_info[pool.address_reward_token];

		reward.total_alloc_point += _alloc_point;
		reward.total_alloc_point -= pool.alloc_point;

		pool.alloc_point = _alloc_point;
	}

	function set_emission_per_block(address _address_reward, uint256 _emission_per_block) external onlyOperator
	{
		require(_address_reward != address(0), "set_emission_per_block: Wrong address");

		refresh_reward_per_share();

		reward_info[_address_reward].emission_per_block = _emission_per_block;
		emit UpdateEmissionRateCB(msg.sender, _emission_per_block);
	}

	//---------------------------------------------------------------
	// External Method
	//---------------------------------------------------------------
	constructor(address _address_chick, address _address_xnft)
	{
		address_operator = msg.sender;
		
		address_chick = _address_chick;
		address_xnft = _address_xnft;
	}

	function make_reward(address _address_reward_token, uint256 _reward_mint_start_block_id, uint256 _emission_per_block) external
	{
		require(_address_reward_token != address(0), "make_pool: Wrong address");

		RewardInfo storage reward = reward_info[_address_reward_token];
		reward.emission_per_block = _emission_per_block;
		reward.start_block_id = _reward_mint_start_block_id;
		reward.last_rewarded_block_id = (block.number > _reward_mint_start_block_id)?
			block.number : _reward_mint_start_block_id;

		ITokenXBaseV3 reward_token = ITokenXBaseV3(_address_reward_token);
		reward_token.set_chick(address_chick);
	}

	function make_pool(address _address_stake_token, address _address_reward_token, uint256 _alloc_point,
		uint256 _harvest_interval, bool _refresh_reward)
		public onlyOperator uniquePool(_address_stake_token) returns(uint256)
	{
		require(_address_stake_token != address(0), "make_pool: Wrong address");
		require(_address_reward_token != address(0), "make_pool: Wrong address");
		require(_harvest_interval <= MAX_HARVEST_INTERVAL, "make_pool: Invalid harvest interval");

		if(_refresh_reward)
			refresh_reward_per_share();

		RewardInfo storage reward = reward_info[_address_reward_token];
		require(reward.last_rewarded_block_id != 0, "make_pool: Invalid reward token");
		
		is_pool_exist[_address_stake_token] = true;

		reward.total_alloc_point += _alloc_point;

		pool_info.push(PoolInfo({
			address_stake_token: _address_stake_token,
			address_reward_token: _address_reward_token,

			harvest_interval: _harvest_interval,
			alloc_point: _alloc_point,
			total_staked_amount: 0,

			accu_reward_amount_per_share_e12: 0,
			total_xnft_boost_rate_e4: 0
		}));

		fee_info.push(FeeInfo({
			deposit_e4: 0,
			withdrawal_max_e4: 0,
			withdrawal_min_e4: 0,
			withdrawal_period: 0
		}));

		uint new_pool_id = pool_info.length-1;
		emit MakePoolCB(msg.sender, new_pool_id);
		return new_pool_id;
	}

	function refresh_reward_per_share() public
	{
		for(uint256 i=0; i < pool_info.length; i++)
			_refresh_reward_per_share(pool_info[i], reward_info[pool_info[i].address_reward_token]);
	}

	function deposit_nft(uint256 _pool_id, uint256 _xnft_id) public whenNotPaused nonReentrant
	{
		require(_pool_id < pool_info.length, "deposit_nft: Wrong pool id");

		PoolInfo storage pool = pool_info[_pool_id];
		RewardInfo storage reward = reward_info[pool.address_reward_token];
		
		_refresh_reward_per_share(pool, reward);

		require(pool.address_stake_token == address_xnft, "deposit_nft: Wrong pool id for NFT");

		address address_user = msg.sender;
		UserInfo storage user = user_info[_pool_id][address_user];

		require(_is_exist_xnft_in_list(user, _xnft_id) == false, "deposit_nft: Already using NFT");

		_collect_reward(pool, user, address_user);

		// User -> Bullish
		IERC1155 stake_token = IERC1155(pool.address_stake_token);
		stake_token.safeTransferFrom(address_user, address(this), _xnft_id, 1, "");

		// Write down deposit amount on Bullish's ledger
		user.staked_amount += 1;
		_add_xnft_to_list(user, _xnft_id);

		emit DepositCB(address_user, _pool_id, user.staked_amount);
	}

	function withdraw_nft(uint256 _pool_id, uint256 _xnft_id) public nonReentrant
	{
		require(_pool_id < pool_info.length, "withdraw_nft: Wrong pool id.");

		PoolInfo storage pool = pool_info[_pool_id];
		RewardInfo storage reward = reward_info[pool.address_reward_token];
		_refresh_reward_per_share(pool, reward);

		require(pool.address_stake_token != address_xnft, "withdraw_nft: Wrong pool id");

		address address_user = msg.sender;
		UserInfo storage user = user_info[_pool_id][address_user];

		require(_is_exist_xnft_in_list(user, _xnft_id) == true, "withdraw_nft: No NFT found");

		if(user.next_harvest_time == 0)
			user.next_harvest_time = block.timestamp + pool.harvest_interval;

		_collect_reward(pool, user, address_user);

		// Bullish -> User
		IERC1155 stake_token = IERC1155(pool.address_stake_token);
		stake_token.safeTransferFrom(address(this), address_user, _xnft_id, 1, "");

		user.staked_amount -= 1;
		_remove_xnft_from_list(user, _xnft_id);

		emit WithdrawCB(address_user, _pool_id, user.staked_amount);
	}

	function deposit(uint256 _pool_id, uint256 _amount) public whenNotPaused nonReentrant
	{
		require(_pool_id < pool_info.length, "deposit: Wrong pool id");

		PoolInfo storage pool = pool_info[_pool_id];
		RewardInfo storage reward = reward_info[pool.address_reward_token];
		_refresh_reward_per_share(pool, reward);

		require(pool.address_stake_token != address_xnft, "deposit_nft: Wrong pool id");

		address address_user = msg.sender;
		UserInfo storage user = user_info[_pool_id][address_user];

		_collect_reward(pool, user, address_user);

		if(_amount > 0)
		{
			// User -> Bullish
			IERC20 stake_token = IERC20(pool.address_stake_token);
			stake_token.safeTransferFrom(address_user, address(this), _amount);

			uint256 deposit_fee = 0;
			if(fee_info[_pool_id].deposit_e4 > 0)
			{
				// Bullish -> Chick for Fee
				deposit_fee = _amount * fee_info[_pool_id].deposit_e4 / 1e4;
				stake_token.safeTransfer(address_chick, deposit_fee);				
			}

			uint256 deposit_amount = _amount - deposit_fee;

			// Bullish -> CakeBaker for Deposit to delecate farming
			if(address_cakebaker != address(0x0))
			{
				ICakeBaker cakebaker = ICakeBaker(address_cakebaker);
				cakebaker.delegate(address(this), pool.address_stake_token, deposit_amount);
			}

			// Write down deposit amount on Bullish's ledger
			user.staked_amount += deposit_amount;
			pool.total_staked_amount += deposit_amount;
		}

		emit DepositCB(address_user, _pool_id, user.staked_amount);
	}

	function withdraw(uint256 _pool_id, uint256 _amount) public nonReentrant
	{
		require(_pool_id < pool_info.length, "withdraw: Wrong pool id.");

		PoolInfo storage pool = pool_info[_pool_id];
		RewardInfo storage reward = reward_info[pool.address_reward_token];
		_refresh_reward_per_share(pool, reward);

		require(pool.address_stake_token != address_xnft, "withdraw: Wrong pool id");

		address address_user = msg.sender;
		UserInfo storage user = user_info[_pool_id][address_user];

		require(user.staked_amount >= _amount, "withdraw: user.staked_amount >= _amount");

		if(user.next_harvest_time == 0)
			user.next_harvest_time = block.timestamp + pool.harvest_interval;

		_collect_reward(pool, user, address_user);

		if(_amount > 0)
		{
			// CakeBaker -> Bullish
			if(address_cakebaker != address(0x0))
			{
				ICakeBaker cakebaker = ICakeBaker(address_cakebaker);
				cakebaker.retain(address(this), pool.address_stake_token, _amount);
			}

			IERC20 stake_token = IERC20(pool.address_stake_token);

			uint256 withdraw_fee = 0;
 			uint256 withdraw_fee_rate_e4 = _get_cur_withdraw_fee_e4(user, fee_info[_pool_id]);
			if(withdraw_fee_rate_e4 > 0)
			{
				// Bullish -> Chick for Fee
				withdraw_fee = _amount * withdraw_fee_rate_e4 / 1e4;
				stake_token.safeTransfer(address_chick, withdraw_fee);				
			}

			uint256 withdraw_amount = _amount - withdraw_fee;

			stake_token.safeTransfer(address_user, withdraw_amount);

			user.staked_amount -= _amount;
			pool.total_staked_amount -= withdraw_amount;
		}

		emit WithdrawCB(address_user, _pool_id, user.staked_amount);
	}

	function harvest(uint256 _pool_id) public whenNotPaused nonReentrant
	{
		require(_pool_id < pool_info.length, "harvest: Wrong pool id.");

		PoolInfo storage pool = pool_info[_pool_id];
		RewardInfo storage reward = reward_info[pool.address_reward_token];
		_refresh_reward_per_share(pool, reward);

		address address_user = msg.sender;
		UserInfo storage user = user_info[_pool_id][address_user];

		uint256 pending_reward_amount = _get_pending_reward_amount(pool, reward, user);
		if(pending_reward_amount == 0)
		{
			emit HarvestNotYetCB(address_user, _pool_id, pending_reward_amount);
		}		
		else if(_can_harvest(user))
		{
			_collect_reward(pool, user, address_user);
			_safe_reward_transfer(pool, address_user, pending_reward_amount);

			user.locked_reward_amount = 0;
			reward.total_locked_amount -= pending_reward_amount;

			user.paid_reward_amount += pending_reward_amount;
			user.next_harvest_time = block.timestamp + pool.harvest_interval;
			
			emit HarvestCB(address_user, _pool_id, pending_reward_amount);
		}
		else
		{
			user.locked_reward_amount += pending_reward_amount;
			reward.total_locked_amount += pending_reward_amount;

			emit HarvestNotYetCB(address_user, _pool_id, pending_reward_amount);
		}
	}

	function add_nft_booster(uint256 _pool_id, uint256 _nft_id) external whenNotPaused
	{
		require(_pool_id < pool_info.length, "add_nft_booster: Wrong pool id.");
		
		PoolInfo storage pool = pool_info[_pool_id];
		RewardInfo storage reward = reward_info[pool.address_reward_token];
		_refresh_reward_per_share(pool, reward);

		require(pool.address_stake_token != address_xnft, "add_nft_booster: NFT pool doesn't support booster.");

		address address_user = msg.sender;
		UserInfo storage user = user_info[_pool_id][address_user];

		require(_is_exist_xnft_in_list(user, _nft_id) == false, "add_nft_booster: Already using nft id");

		// User -> Bullish
		IERC1155 stake_token = IERC1155(address_xnft);
		stake_token.safeTransferFrom(address_user, address(this), _nft_id, 1, "");

		uint16 grade = _get_nft_grade(_nft_id);
		user.xnft_boost_rate_e4 += xnft_boost_rate_e4[grade-1];
		pool.total_xnft_boost_rate_e4 += xnft_boost_rate_e4[grade-1];

		_add_xnft_to_list(user, _nft_id);

		emit AddNFTBoosterCB(msg.sender, _nft_id);
	}

	function remove_nft_booster(uint256 _pool_id, uint256 _nft_id) external
	{
		require(_pool_id < pool_info.length, "remove_nft_booster: Wrong pool id.");

		PoolInfo storage pool = pool_info[_pool_id];
		RewardInfo storage reward = reward_info[pool.address_reward_token];
		_refresh_reward_per_share(pool, reward);

		require(pool.address_stake_token != address_xnft, "remove_nft_booster: NFT pool doesn't support booster.");

		address address_user = msg.sender;
		UserInfo storage user = user_info[_pool_id][address_user];

		require(_is_exist_xnft_in_list(user, _nft_id) == true, "remove_nft_booster: No NFT found");

		// Bullish -> User
		IERC1155 stake_token = IERC1155(address_xnft);
		stake_token.safeTransferFrom(address(this), address_user, _nft_id, 1, "");

		uint16 grade = _get_nft_grade(_nft_id);
		user.xnft_boost_rate_e4 -= xnft_boost_rate_e4[grade-1];
		pool.total_xnft_boost_rate_e4 -= xnft_boost_rate_e4[grade-1];

		_remove_xnft_from_list(user, _nft_id);

		emit RemoveNFTBoosterCB(msg.sender, _nft_id);
	}

	function get_nft_booster_list(uint256 _pool_id) external returns(uint256[] memory)
	{
		address address_user = msg.sender;
		uint256[] memory id_list = user_info[_pool_id][address_user].xnft_id_list;
		emit GetNFTBoosterListCB(msg.sender, _pool_id, id_list);
		return id_list;
	}

	function has_nft(address _address_user) external view returns(bool)
	{
		for(uint256 i=0; i<pool_info.length; i++)
		{
			UserInfo storage user = user_info[i][_address_user];
			if(user.xnft_id_list.length > 0)
				return true;
		}

		return false;
	}

	function get_pending_reward_amount(uint256 _pool_id, address _address_user) external returns(uint256)
	{
		require(_pool_id < pool_info.length, "get_pending_reward_amount: Wrong pool id.");

		PoolInfo storage pool = pool_info[_pool_id];
		UserInfo storage user = user_info[_pool_id][_address_user];
		RewardInfo storage reward = reward_info[pool.address_reward_token];

		uint256 pending_amount = _get_pending_reward_amount(pool, reward, user);

		emit GetPendingRewardAmountCB(msg.sender, _pool_id, _address_user, pending_amount);
		return pending_amount;
	}

	function emergency_withdraw(uint256 _pool_id) public nonReentrant
	{
		require(_pool_id < pool_info.length, "emergency_withdraw: Wrong pool id.");

		address address_user = msg.sender;
		PoolInfo storage pool = pool_info[_pool_id];

		require(pool.address_stake_token != address_xnft, "emergency_withdraw: NFT pool doesn't support.");

		UserInfo storage user = user_info[_pool_id][address_user];

		uint256 amount = user.staked_amount;
		user.staked_amount = 0;
		user.paid_reward_amount = 0;

		IERC20 stake_token = IERC20(pool.address_stake_token);
		stake_token.safeTransfer(address_user, amount);

		emit EmergencyWithdrawCB(address_user, _pool_id, amount);
	}

	function handle_stuck(address _token, uint256 _amount) public onlyOperator nonReentrant
	{
		require(_token != address_xnft, "handle_stuck: NFT pool doesn't support.");

		address address_user = msg.sender;

		IERC20 stake_token = IERC20(_token);
		stake_token.safeTransfer(address_user, _amount);
		
		emit HandleStuckCB(address_user, _amount);
	}

	function pause() external onlyOperator
	{ 
		_pause(); 
		emit PauseCB(msg.sender);
	}
	
	function resume() external onlyOperator
	{ 
		_unpause();
		emit ResumeCB(msg.sender);
	}

	//---------------------------------------------------------------
	// Internal Method
	//---------------------------------------------------------------
	function _can_harvest(UserInfo storage user) private view returns(bool)
	{
		return block.timestamp >= user.next_harvest_time;
	}

	function _safe_reward_transfer(PoolInfo storage _pool, address _to, uint256 _amount) internal
	{
		IERC20 reward_token = IERC20(_pool.address_reward_token);
		uint256 cur_reward_balance = reward_token.balanceOf(address(this));

		if(_amount > cur_reward_balance)
			reward_token.safeTransfer(_to, cur_reward_balance);
		else
			reward_token.safeTransfer(_to, _amount);
	}

	function _collect_reward(PoolInfo storage _pool, UserInfo storage _user, address _adress_user) private returns(uint256)
	{
		if(_user.staked_amount == 0)
			return 0;
		
		uint256 user_share = _user.staked_amount * _user.xnft_boost_rate_e4 / 1e4;
		uint256 accu_reward_amount = user_share * _pool.accu_reward_amount_per_share_e12 / 1e12;
		
		uint256 pending_reward_amount = accu_reward_amount - _user.paid_reward_amount;
		if(pending_reward_amount > 0)
		{
			_safe_reward_transfer(_pool, _adress_user, pending_reward_amount);
			_user.paid_reward_amount = accu_reward_amount;
		}

		return pending_reward_amount;
	}

	function _get_pending_reward_amount(PoolInfo storage _pool, RewardInfo storage _reward, UserInfo storage _user) internal returns(uint256)
	{
		uint256 elapsed_block_count = block.number - _reward.last_rewarded_block_id;
		if(elapsed_block_count == 0)
			return 0;

		_refresh_reward_per_share(_pool, _reward);
		
		uint256 accu_rps_e12 = _pool.accu_reward_amount_per_share_e12;
		if(_pool.total_staked_amount > 0 && _pool.alloc_point > 0 && elapsed_block_count > 0)
		{
			uint256 new_reward_per_pool = _get_new_rewards_amount(_pool, _reward, elapsed_block_count);
			accu_rps_e12 += new_reward_per_pool * 1e12 / _pool.total_staked_amount;
		}

		uint256 user_boosted_amount_e16 = accu_rps_e12 * _user.staked_amount * 
			(10000 + _user.xnft_boost_rate_e4) / _pool.total_staked_amount;

		uint256 pending_total = user_boosted_amount_e16 / 1e16 - _user.paid_reward_amount;
		return pending_total;
	}

	function _get_new_rewards_amount(PoolInfo storage _pool, RewardInfo storage _reward, uint256 _block_count) internal view returns(uint256)
	{
		uint256 new_reward_per_pool = _block_count * _reward.emission_per_block * _pool.alloc_point / _reward.total_alloc_point;
		return new_reward_per_pool;
	}

	function _refresh_reward_per_share(PoolInfo storage _pool, RewardInfo storage _reward) internal
	{		
		uint256 elapsed_block_count = block.number - _reward.last_rewarded_block_id;
		if(_pool.total_staked_amount == 0 || _pool.alloc_point == 0 || elapsed_block_count == 0)
			return;

		uint256 mint_reward_amount = _get_new_rewards_amount(_pool, _reward, elapsed_block_count);

		// add more rewards for the nft boosters
		mint_reward_amount += (mint_reward_amount * (10000 + _pool.total_xnft_boost_rate_e4) / 1e4);

		// Mint native token -> Bullish
		ITokenXBaseV3 reward_token = ITokenXBaseV3(_pool.address_reward_token);
		reward_token.mint(address(this), mint_reward_amount);

		_pool.accu_reward_amount_per_share_e12 += (mint_reward_amount * 1e12 / _pool.total_staked_amount);
		_reward.last_rewarded_block_id = block.number;
	}

	function _get_nft_grade(uint256 _xnft_id) internal view returns(uint16)
	{
		require(_xnft_id > xnft_level_prefix[0], "get_grade: Wrong ID");

		if(_xnft_id < xnft_level_prefix[1]) return 1;
		else if(_xnft_id < xnft_level_prefix[2]) return 2;
		else return 3;
	}

	function _is_exist_xnft_in_list(UserInfo storage _user, uint256 _nft_id) view internal returns(bool)
	{
		bool check_ownership = false;
		for(uint256 i=0; i < _user.xnft_id_list.length; i++)
		{
			if(_user.xnft_id_list[i] == _nft_id)
				check_ownership = true;
		}

		return check_ownership;
	}

	function _add_xnft_to_list(UserInfo storage user, uint256 _nft_id) internal
	{
		for(uint256 i=0; i<user.xnft_id_list.length; i++)
			require(user.xnft_id_list[i] != _nft_id, "add_nft_booster: Already using nft id");

		user.xnft_id_list.push(_nft_id);
	}

	function _remove_xnft_from_list(UserInfo storage user, uint256 _nft_id) internal
	{
		for(uint256 i=0; i<user.xnft_id_list.length; i++)
		{
			if(user.xnft_id_list[i] == _nft_id)
			{
				user.xnft_id_list[i] = user.xnft_id_list[user.xnft_id_list.length-1];
				user.xnft_id_list.pop();
				break;
			}
		}
	}

	function _min(uint256 a, uint256 b) internal pure returns (uint256)
	{
    	return a <= b ? a : b;
	}
	
	function _get_cur_withdraw_fee_e4(UserInfo storage _user, FeeInfo storage _fee) internal view returns(uint256)
	{
		uint256 time_diff = block.timestamp - _user.last_deposit_time;
		uint256 reduction_rate_e4 = _min(time_diff * 1e4 / _fee.withdrawal_period, 10000);
		uint256 final_fee_e4 = _fee.withdrawal_min_e4 + (_fee.withdrawal_max_e4-_fee.withdrawal_min_e4) * reduction_rate_e4 / 1e4;
		return final_fee_e4;
	}
}