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
		
		uint256 deposit_time; // block timestamp unit is seconds
		uint256 withdraw_locking_period;
	}

	struct PoolInfo
	{
		address address_stake_token; // Target
		address address_reward_token; // Arrow or BUSD

		uint256 last_rewarded_block_id;
		uint256 accu_reward_amount_per_share_e12;
		uint256 reward_per_block_min;
		uint256 reward_per_block_max;
	}

	address public address_operator;
	uint256 public reward_mint_start_block_id;

	// withdraw_locking_period
	// 디파짓이 0일때만 기간 설정 가능
	// 추가로 돈 넣으면 여태 지나간 시간 리셋

	uint256 constant MAX_WITHDRAW_LOCK = 30 days;

	uint256 public locking_period_mim = 7 days;
	uint256 public locking_period_max = 30 days;
	
	PoolInfo[] public pool_info; // pool_id / pool_info, reward_info
	mapping(address => mapping(address => bool)) public is_pool_exist; // stake / reward
	mapping(uint256 => mapping(address => UserInfo)) public user_info; // pool_id / user_adddress / user_info

	//---------------------------------------------------------------
	// Front-end connectors
	//---------------------------------------------------------------
	event PauseCB(address indexed operator);
	event ResumeCB(address indexed operator);
	event SetOperatorCB(address indexed operator, address _new_operator);
	event UpdateEmissionRateCB(address indexed operator, uint256 _reward_per_block_min, uint256 _reward_per_block_max);
	event SetLockingPeriodCB(address indexed operator, uint256 _min_time, uint256 _max_time);
	event MakePoolCB(address indexed operator, uint256 _new_pool_id);
	event DepositCB(address indexed _user, uint256 _pool_id, uint256 _amount);
	event WithdrawCB(address indexed _user, uint256 _pool_id, uint256 _amount);
	event HarvestCB(address indexed _user, uint256 _pool_id, uint256 _amount);
	event HandleStuckCB(address indexed _user, uint256 _amount);

	//---------------------------------------------------------------
	// Modifier
	//---------------------------------------------------------------
	modifier uniquePool(address _address_stake_token, address _address_reward_token) {
		require(is_pool_exist[_address_stake_token][_address_reward_token] == false, "uniquePool: duplicated"); _; }
	modifier onlyOperator() { require(msg.sender == address_operator, "onlyOperator: Not authorized"); _; }

	//---------------------------------------------------------------
	// Variable Interfaces
	//---------------------------------------------------------------
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

	function set_operator(address _new_operator) external onlyOperator
	{
		require(_new_operator != address(0), "set_address_reward_token: Wrong address");
		address_operator = _new_operator;
		emit SetOperatorCB(msg.sender, _new_operator);
	}

	function update_emission_rate(uint256 _pool_id, uint256 _reward_per_block_min,
		uint256 _reward_per_block_max) public onlyOperator
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

	//---------------------------------------------------------------
	// External Methodd
	//---------------------------------------------------------------
	constructor(uint256 _reward_mint_start_block_id)
	{
		address_operator = msg.sender;
		reward_mint_start_block_id = _reward_mint_start_block_id;
	}

	function make_pool(address _address_stake_token, address _address_reward_token,
		uint256 _reward_per_block_min, uint256 _reward_per_block_max, bool _update_all)
		public onlyOperator uniquePool(_address_stake_token, _address_reward_token) returns (uint256)
	{
		if(_update_all)
			refresh_reward_per_share_all();

		is_pool_exist[_address_stake_token][_address_reward_token] = true;

		uint256 _last_rewarded_block_id = (block.number > reward_mint_start_block_id)? block.number : reward_mint_start_block_id;
		pool_info.push(PoolInfo({
			address_stake_token: _address_stake_token,
			address_reward_token: _address_reward_token,
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
		refresh_reward_per_share(_pool_id);

		require(_period >= locking_period_mim, "deposit: Wrong locking period");
		require(_period <= locking_period_max, "deposit: Wrong locking period");

		address address_user = msg.sender;
		UserInfo storage user = user_info[_pool_id][address_user];
		PoolInfo storage pool = pool_info[_pool_id];

		_collect_reward(pool, user, address_user);

		if(_amount > 0)
		{
			require(_period != user.withdraw_locking_period && user.staked_amount < 100, "deposit: Unstake previous all amount first."); // 100 wei is nearly zero.

			// User -> Rooster
			IERC20 lp_token = IERC20(pool.address_stake_token);
			lp_token.safeTransferFrom(address_user, address(this), _amount);

			// Write down deposit amount on Rooter's ledger
			user.staked_amount += _amount;
			user.deposit_time = block.timestamp;
			user.withdraw_locking_period = _period;
		}

		emit DepositCB(address_user, _pool_id, user.staked_amount);
	}

	function withdraw(uint256 _pool_id, uint256 _amount) public nonReentrant whenNotPaused
	{
		require(_pool_id < pool_info.length, "withdraw: Wrong pool id.");

		refresh_reward_per_share(_pool_id);

		address address_user = msg.sender;
		PoolInfo storage pool = pool_info[_pool_id];
		UserInfo storage user = user_info[_pool_id][address_user];

		require(user.staked_amount >= _amount, "withdraw: insufficient amount");

		uint256 unlock_time = user.deposit_time + user.withdraw_locking_period;
		require(block.timestamp >= unlock_time, "withdraw: withdraw is locked.");

		_collect_reward(pool, user, address_user);

		if(_amount > 0)
		{
			user.staked_amount -= _amount;
			IERC20(pool.address_stake_token).safeTransfer(address(address_user), _amount);
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

		PoolInfo storage pool = pool_info[_pool_id];
		if(block.number <= pool.last_rewarded_block_id)
			return;

		uint256 elapsed_block_count = block.number - pool.last_rewarded_block_id;
		uint256 total_staked_amount = IERC20(pool.address_stake_token).balanceOf(address(this));
		if(total_staked_amount > 0 && elapsed_block_count > 0)
		{
			uint256 max_reward_amount = elapsed_block_count * pool.reward_per_block_max;
			pool.accu_reward_amount_per_share_e12 += (max_reward_amount * 1e12 / total_staked_amount);
			pool.last_rewarded_block_id = block.number;
		}
	}

	function harvest(uint256 _pool_id) public nonReentrant whenNotPaused
	{
		require(_pool_id < pool_info.length, "harvest: Wrong pool id.");

		refresh_reward_per_share(_pool_id);

		address address_user = msg.sender;
		PoolInfo storage pool = pool_info[_pool_id];
		UserInfo storage user = user_info[_pool_id][address_user];

		uint256 amount = _collect_reward(pool, user, address_user);
		
		emit HarvestCB(address_user, _pool_id, amount);
	}

	function handle_stuck(address _address_token, uint256 _amount) public onlyOperator nonReentrant
	{
		address address_user = msg.sender;
		IERC20(_address_token).safeTransfer(address_user, _amount);
		emit HandleStuckCB(address_user, _amount);
	}

	//---------------------------------------------------------------
	// Internal Method
	//---------------------------------------------------------------
	function _collect_reward(PoolInfo storage _pool, UserInfo storage _user, address _address_user) internal returns(uint256)
	{
		if(_user.staked_amount == 0)
			return 0;
		
		uint256 min_max_ratio_e12 = _pool.reward_per_block_max * 1e12 / _pool.reward_per_block_min;
		uint256 period_weight_e12 = min_max_ratio_e12 * _user.withdraw_locking_period / locking_period_max;

		uint256 total_user_reward_amount = _user.staked_amount * _pool.accu_reward_amount_per_share_e12 / 1e12;
		total_user_reward_amount = (total_user_reward_amount * period_weight_e12) / 1e12;

		uint256 pending_reward_amount = total_user_reward_amount - _user.paid_reward_amount;
		if(pending_reward_amount > 0)
		{
			if(_pool.address_reward_token != address(0x0))
				_safe_reward_transfer(_pool.address_reward_token, _address_user, pending_reward_amount);

			_user.paid_reward_amount += pending_reward_amount;
		}

		return pending_reward_amount;
	}

	function _safe_reward_transfer(address _address_reward_token, address _to, uint256 _amount) internal
	{
		// Rooster -> User
		IERC20 reward_token = IERC20(_address_reward_token);
		uint256 cur_reward_balance = reward_token.balanceOf(address(this));

		if(_amount > cur_reward_balance)
			reward_token.safeTransfer(_to, cur_reward_balance);
		else
			reward_token.safeTransfer(_to, _amount);
	}
}