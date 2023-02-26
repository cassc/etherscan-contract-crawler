// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract Rooster is ReentrancyGuard, Pausable
{
	using SafeERC20 for IERC20;

	struct UserInfo
	{
		uint256 staked_amount;
		uint256 locked_reward_amount;
		uint256 paid_reward_amount;
		uint256 next_harvest_time;
		
		uint256 last_deposit_time; // block timestamp unit is seconds
		uint256 withdraw_locking_period;
	}

	struct PoolInfo
	{
		address address_token_stake; // Target
		address address_token_reward; // Arrow or BUSD

		uint256 last_rewarded_block_id;
		uint256 accu_reward_amount_per_share_e12;
		uint256 reward_per_block_min;
		uint256 reward_per_block_max;
	}

	address public address_operator;

	uint256 public emit_start_block_id;
	uint256 public emit_end_block_id;
	
	uint256 public locking_period_mim = 7 days;
	uint256 public locking_period_max = 30 days;
	uint256 constant MAX_WITHDRAW_LOCK = 30 days;
	
	PoolInfo[] public pool_info; // pool_id / pool_info, reward_info
	mapping(address => mapping(address => bool)) public is_pool_exist; // stake / reward
	mapping(uint256 => mapping(address => UserInfo)) public user_info; // pool_id / user_adddress / user_info

	//---------------------------------------------------------------
	// Front-end connectors
	//---------------------------------------------------------------
	event SetOperatorCB(address indexed operator, address _new_operator);
	event UpdateEmissionRateCB(address indexed operator, uint256 _reward_per_block_min, uint256 _reward_per_block_max);
	event SetLockingPeriodCB(address indexed operator, uint256 _min_time, uint256 _max_time);
	event MakePoolCB(address indexed operator, uint256 _new_pool_id);
	event DepositCB(address indexed _user, uint256 _pool_id, uint256 _amount);
	event WithdrawCB(address indexed _user, uint256 _pool_id, uint256 _amount);
	event HarvestCB(address indexed _user, uint256 _pool_id, uint256 _amount);

	event EmergencyWithdrawCB(address indexed user, uint256 _pool_id, uint256 _amount);
	event HandleStuckCB(address indexed _user, uint256 _amount);
	event SetPeriodCB(uint256 _emit_start_block_id, uint256 _emit_end_block_id);

	//---------------------------------------------------------------
	// Modifier
	//---------------------------------------------------------------
	modifier uniquePool(address _address_token_stake, address _address_token_reward) {
		require(is_pool_exist[_address_token_stake][_address_token_reward] == false, "uniquePool: duplicated"); _; }
	modifier onlyOperator() { require(msg.sender == address_operator, "onlyOperator: Not authorized"); _; }
	
	//---------------------------------------------------------------
	// External Methodd
	//---------------------------------------------------------------
	constructor()
	{
		address_operator = msg.sender;
	}

	function make_pool(address _address_token_stake, address _address_token_reward,
		uint256 _reward_per_block_min, uint256 _reward_per_block_max, bool _refresh_reward)
		public onlyOperator uniquePool(_address_token_stake, _address_token_reward) returns(uint256)
	{
		if(_refresh_reward)
			refresh_reward_per_share_all();

		is_pool_exist[_address_token_stake][_address_token_reward] = true;

		uint256 _last_rewarded_block_id = (block.number > emit_start_block_id)? block.number : emit_start_block_id;
		pool_info.push(PoolInfo({
			address_token_stake: _address_token_stake,
			address_token_reward: _address_token_reward,
			last_rewarded_block_id: _last_rewarded_block_id,
			accu_reward_amount_per_share_e12: 0,
			reward_per_block_min: _reward_per_block_min,
			reward_per_block_max: _reward_per_block_max
		}));

		uint new_pool_id = pool_info.length-1;
		emit MakePoolCB(msg.sender, new_pool_id);
		return new_pool_id;
	}

	function deposit(uint256 _pool_id, uint256 _amount, uint256 _period) public nonReentrant whenNotPaused
	{
		require(_pool_id < pool_info.length, "deposit: Wrong pool id");
		_refresh_reward_per_share(_pool_id);

		require(_period >= locking_period_mim, "deposit: Wrong locking period");
		require(_period <= locking_period_max, "deposit: Wrong locking period");

		address address_user = msg.sender;
		UserInfo storage user = user_info[_pool_id][address_user];
		PoolInfo storage pool = pool_info[_pool_id];

		_collect_reward(pool, user, address_user);

		if(_amount > 0)
		{
			// 디파짓이 0일때만 기간 설정 가능
			require(_period != user.withdraw_locking_period && user.staked_amount < 100, "deposit: Unstake previous all amount first."); // 100 wei is nearly zero.

			// User -> Rooster
			IERC20 lp_token = IERC20(pool.address_token_stake);
			lp_token.safeTransferFrom(address_user, address(this), _amount);

			// Write down deposit amount on Rooster's ledger
			user.staked_amount += _amount;
			user.last_deposit_time = block.timestamp; // 추가로 돈 넣으면 여태 지나간 시간 리셋
			user.withdraw_locking_period = _period;
		}

		emit DepositCB(address_user, _pool_id, user.staked_amount);
	}

	function withdraw(uint256 _pool_id, uint256 _amount) public nonReentrant
	{
		require(_pool_id < pool_info.length, "withdraw: Wrong pool id.");

		_refresh_reward_per_share(_pool_id);

		address address_user = msg.sender;
		PoolInfo storage pool = pool_info[_pool_id];
		UserInfo storage user = user_info[_pool_id][address_user];

		require(user.staked_amount >= _amount, "withdraw: insufficient amount");

		uint256 unlock_time = user.last_deposit_time + user.withdraw_locking_period;
		require(block.timestamp >= unlock_time, "withdraw: withdraw is locked.");

		_collect_reward(pool, user, address_user);

		if(_amount > 0)
		{
			user.staked_amount -= _amount;
			IERC20(pool.address_token_stake).safeTransfer(address(address_user), _amount);
		}

		emit WithdrawCB(address_user, _pool_id, _amount);
	}

	function refresh_reward_per_share_all() public
	{
		for(uint256 pid = 0; pid < pool_info.length; pid++)
			refresh_reward_per_share(pid);
	}

	function refresh_reward_per_share(uint256 _pool_id) public
	{
		require(_pool_id < pool_info.length, "refresh_reward_per_share: Wrong pool id.");
		if(emit_start_block_id == 0) return;
 
		PoolInfo storage pool = pool_info[_pool_id];
		if(block.number <= pool.last_rewarded_block_id)
			return;

		uint256 cur_block_id = (block.number > emit_end_block_id)? emit_end_block_id : block.number;
		uint256 elapsed_block_count = cur_block_id - pool.last_rewarded_block_id;
		uint256 total_staked_amount = IERC20(pool.address_token_stake).balanceOf(address(this));
		if(total_staked_amount > 0 && elapsed_block_count > 0)
		{
			uint256 max_reward_amount = elapsed_block_count * pool.reward_per_block_max;
			pool.accu_reward_amount_per_share_e12 += (max_reward_amount * 1e12 / total_staked_amount);
			pool.last_rewarded_block_id = cur_block_id;
		}
	}

	function harvest(uint256 _pool_id) public nonReentrant
	{
		require(_pool_id < pool_info.length, "harvest: Wrong pool id.");

		_refresh_reward_per_share(_pool_id);

		address address_user = msg.sender;
		PoolInfo storage pool = pool_info[_pool_id];
		UserInfo storage user = user_info[_pool_id][address_user];

		uint256 amount = _collect_reward(pool, user, address_user);
		
		emit HarvestCB(address_user, _pool_id, amount);
	}

	function emergency_withdraw(uint256 _pool_id) public nonReentrant
	{
		require(_pool_id < pool_info.length, "emergency_withdraw: Wrong pool id.");

		address address_user = msg.sender;
		PoolInfo storage pool = pool_info[_pool_id];
		UserInfo storage user = user_info[_pool_id][address_user];

		uint256 amount = user.staked_amount;
		user.staked_amount = 0;
		user.paid_reward_amount = 0;

		IERC20 stake_token = IERC20(pool.address_token_stake);
		stake_token.safeTransfer(address_user, amount);

		emit EmergencyWithdrawCB(address_user, _pool_id, amount);
	}

	function handle_stuck(address _address_token, uint256 _amount) public onlyOperator nonReentrant
	{
		for(uint256 i=0; i<pool_info.length; i++)
			require(_address_token != pool_info[i].address_token_reward, "handle_stuck: Wrong token address");

		address address_user = msg.sender;
		IERC20(_address_token).safeTransfer(address_user, _amount);
		emit HandleStuckCB(address_user, _amount);
	}

	function pause() external onlyOperator
	{ 
		_pause(); 
	}
	
	function resume() external onlyOperator
	{ 
		_unpause();
	}

	//---------------------------------------------------------------
	// Internal Method
	//---------------------------------------------------------------
	function _refresh_reward_per_share(uint256 _pool_id) internal
	{
		require(_pool_id < pool_info.length, "_refresh_reward_per_share: Wrong pool id.");

		PoolInfo storage pool = pool_info[_pool_id];
		if(block.number <= pool.last_rewarded_block_id)
			return;

		uint256 elapsed_block_count = block.number - pool.last_rewarded_block_id;
		uint256 total_staked_amount = IERC20(pool.address_token_stake).balanceOf(address(this));
		if(total_staked_amount > 0 && elapsed_block_count > 0)
		{
			uint256 max_reward_amount = elapsed_block_count * pool.reward_per_block_max;
			pool.accu_reward_amount_per_share_e12 += (max_reward_amount * 1e12 / total_staked_amount);
			pool.last_rewarded_block_id = block.number;
		}
	}

	function _collect_reward(PoolInfo storage _pool, UserInfo storage _user, address _address_user) internal returns(uint256)
	{
		if(_user.staked_amount == 0)
			return 0;
		
		uint256 min_max_ratio_e12 = _pool.reward_per_block_max * 1e12 / _pool.reward_per_block_min;
		uint256 period_weight_e12 = min_max_ratio_e12 * _user.withdraw_locking_period / locking_period_max;

		uint256 user_share = _user.staked_amount * _pool.accu_reward_amount_per_share_e12 / 1e12;
		uint256 final_user_reward = user_share * period_weight_e12 / 1e12;

		uint256 pending_reward_amount = final_user_reward - _user.paid_reward_amount;
		if(pending_reward_amount > 0)
		{
			if(_pool.address_token_reward != address(0))
				_safe_reward_transfer(_pool.address_token_reward, _address_user, pending_reward_amount);

			_user.paid_reward_amount += pending_reward_amount;
		}

		return pending_reward_amount;
	}

	function _safe_reward_transfer(address _address_token_reward, address _to, uint256 _amount) internal
	{
		// Rooster -> User
		IERC20 reward_token = IERC20(_address_token_reward);
		uint256 cur_reward_balance = reward_token.balanceOf(address(this));

		if(_amount > cur_reward_balance)
			reward_token.safeTransfer(_to, cur_reward_balance);
		else
			reward_token.safeTransfer(_to, _amount);
	}
		
	//---------------------------------------------------------------
	// Variable Interfaces
	//---------------------------------------------------------------
	function set_operator(address _new_operator) external onlyOperator
	{
		require(_new_operator != address(0), "set_address_reward_token: Wrong address");
		address_operator = _new_operator;
		emit SetOperatorCB(msg.sender, _new_operator);
	}
	
	function set_period(uint256 _mint_start_block_id, uint256 _mint_end_block_id) external onlyOperator whenPaused
	{
		require(_mint_start_block_id < _mint_end_block_id, "set_period: Wrong block id");
		emit_start_block_id = (block.number > _mint_start_block_id)? block.number : _mint_start_block_id;
		emit_end_block_id = _mint_end_block_id;
		emit SetPeriodCB(_mint_start_block_id, _mint_end_block_id);
	}

	function update_emission_rate(uint256 _pool_id, uint256 _reward_per_block_min, uint256 _reward_per_block_max) public onlyOperator
	{
		require(_pool_id < pool_info.length, "update_emission_rate: Wrong pool id.");
		require(_reward_per_block_min <= _reward_per_block_max, "update_emission_rate: Wrong reward amount");

		refresh_reward_per_share_all();

		pool_info[_pool_id].reward_per_block_min = _reward_per_block_min;
		pool_info[_pool_id].reward_per_block_max = _reward_per_block_max;
		emit UpdateEmissionRateCB(msg.sender, _reward_per_block_min, _reward_per_block_max);
	}

	function get_pool_count() external view returns(uint256)
	{
		return pool_info.length;
	}

	function set_locking_period_range(uint256 _min_time, uint256 _max_time) external onlyOperator
	{
		require(_max_time <= MAX_WITHDRAW_LOCK, "set_locking_period: Wrong locking period");
		locking_period_mim = _min_time;
		locking_period_max = _max_time;
		emit SetLockingPeriodCB(msg.sender, _min_time, _max_time);
	}

}