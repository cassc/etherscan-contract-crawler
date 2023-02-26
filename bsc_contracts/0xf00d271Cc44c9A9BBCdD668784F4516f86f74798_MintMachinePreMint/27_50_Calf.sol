// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/ITokenXBaseV3.sol";
import "./interfaces/ICakeBaker.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract Calf is ReentrancyGuard, Pausable
{
	using SafeERC20 for IERC20;

	struct UserPhaseInfo
	{
		uint256 staked_amount;
		uint256 reward_amount;
		bool is_reward_received;
	}

	struct PoolInfo
	{
		address address_token_stake;

		uint256 alloc_point;
		uint256 reward_amount_per_share;
	}

	uint256 constant MAX_PHASE_INTERVAL = 24 hours;

	address public address_operator;
	address public address_cakebaker;
	address public address_token_reward;

	uint256 public phase_interval = 8 hours;
	uint256 public reward_amount_per_phase = 75;
	uint256 public phase_count = 12; // during 4 days 24 * 4 / 8

	uint256 public phase_start_block_id;
	uint256 public phase_start_timestamp;
	uint256 public last_mint_time;
	uint256 public phase_cur_serial;
	
	PoolInfo[] public pool_info; // pool_id / pool_info
	mapping(address => bool) public is_pool_exist;
	uint256 public total_alloc_point = 0; // sum of all pools

	// pool_id / user_adddress / phase_serial / user_info
	mapping(uint256 => mapping(address => mapping(uint256 => UserPhaseInfo))) public user_phase_info;

	//---------------------------------------------------------------
	// Front-end connectors
	//---------------------------------------------------------------
	event SetOperatorCB(address indexed operator, address _new_address);
	event SetCakeBakerCB(address indexed operator, address _new_address);
	event SetRewardAmountPerPhaseCB(address indexed operator, uint256 _amount);
	
	event MakePoolCB(address indexed operator, uint256 _new_pool_id);
	event SetPoolInfoCB(address indexed operator, uint256 _pool_id);

	event DepositCB(address indexed _user, uint256 _pool_id, uint256 _amount);
	event ClaimCB(address indexed _user, uint256 _pool_id, uint256 _amount);
	event ClaimtNotYetCB(address indexed _user, uint256 _pool_id, uint256 _amount);

	event GetPendingRewardAmountCB(address indexed operator, uint256 _pool_id, address _user, uint256 _phase_serial, uint256 _pending_total);
	event HandleStuckCB(address indexed _user, uint256 _amount);

	//---------------------------------------------------------------
	// Modifier
	//---------------------------------------------------------------
	modifier uniquePool(address _address_lp) { require(is_pool_exist[_address_lp] == false, "uniquePool: duplicated"); _; }
	modifier onlyOperator() { require(msg.sender == address_operator, "onlyOperator: Not authorized"); _; }

	//---------------------------------------------------------------
	// External Method
	//---------------------------------------------------------------
	constructor(address _address_token_reward)
	{
		address_operator = msg.sender;
		address_token_reward = _address_token_reward;
	}

	function make_pool(uint256 _alloc_point, address _address_token_stake, bool _update_all) external 
		onlyOperator uniquePool(_address_token_stake) returns(uint256)
	{
		if(_update_all)
			refresh_reward_per_share();

		is_pool_exist[_address_token_stake] = true;
		total_alloc_point += _alloc_point;

		pool_info.push(PoolInfo({
			address_token_stake: _address_token_stake,
			alloc_point: _alloc_point,
			reward_amount_per_share: 0
		}));

		uint256 new_pool_id = pool_info.length-1;
		emit MakePoolCB(msg.sender, new_pool_id);
		return new_pool_id;
	}

	function set_pool_info(uint256 _pool_id, uint256 _alloc_point, bool _update_all) public onlyOperator
	{
		if(_update_all)
			refresh_reward_per_share();

		total_alloc_point += _alloc_point;
		total_alloc_point -= pool_info[_pool_id].alloc_point;

		pool_info[_pool_id].alloc_point = _alloc_point;
		emit SetPoolInfoCB(msg.sender, _pool_id);
	}

	function deposit(uint256 _pool_id, uint256 _amount) public nonReentrant whenNotPaused
	{
		require(_pool_id < pool_info.length, "deposit: Wrong pool id");
		require(phase_cur_serial < phase_count, "deposit: All phase are finished.");

		_refresh_reward_per_share(_pool_id);

		address address_user = msg.sender;
		uint256 cur_phase = _get_cur_phase_by_block();

		PoolInfo storage pool = pool_info[_pool_id];
		UserPhaseInfo storage user = user_phase_info[_pool_id][address_user][cur_phase];
		
		if(_amount > 0)
		{
			// User -> Calf
			IERC20 lp_token = IERC20(pool.address_token_stake);
			lp_token.safeTransferFrom(address_user, address(this), _amount);

			// Calf -> CakeBaker
			ICakeBaker cakebaker = ICakeBaker(address_cakebaker);
			cakebaker.delegate(address(this), pool.address_token_stake, _amount);

			// Write down deposit amount on Calf's ledger
			user.staked_amount += _amount;
		}

		emit DepositCB(address_user, _pool_id, user.staked_amount);
	}

	function claim(uint256 _pool_id, uint256 _phase_serial) public nonReentrant
	{
		require(_pool_id < pool_info.length, "claim: Wrong pool id");
		require(_phase_serial < phase_count, "claim: Wrong phase serial");

		_refresh_reward_per_share(_pool_id);

		address address_user = msg.sender;
		UserPhaseInfo storage user = user_phase_info[_pool_id][address_user][_phase_serial];

		if(user.is_reward_received == true)
			return;
		
		if(_can_claim())
		{
			uint256 pending_reward = get_pending_reward_amount(_pool_id, address_user, _phase_serial);
			_safe_reward_transfer(address_user, pending_reward);
			user.is_reward_received = true;

			emit ClaimCB(address_user, _pool_id, user.staked_amount);
		}
		else
			emit ClaimtNotYetCB(address_user, _pool_id, user.staked_amount);
	}

	function refresh_reward_per_share() public nonReentrant
	{
		for(uint256 pool_id = 0; pool_id < pool_info.length; pool_id++)
			_refresh_reward_per_share(pool_id);
	}

	function get_pending_reward_amount(uint256 _pool_id, address _address_user,
		uint256 _phase_serial) public returns(uint256)
	{
		require(_pool_id < pool_info.length, "get_pending_reward_amount: Wrong pool id.");
		require(_phase_serial < phase_count, "claim: Wrong phase serial");

		UserPhaseInfo storage user = user_phase_info[_pool_id][_address_user][_phase_serial];
		if(user.is_reward_received == true)
			return 0;

		PoolInfo storage pool = pool_info[_pool_id];
		uint256 pending_total = user.staked_amount * pool.reward_amount_per_share / 1e12;

		emit GetPendingRewardAmountCB(msg.sender, _pool_id, _address_user, _phase_serial, pending_total);
		return pending_total;
	}

	function handle_stuck(address _address_token, uint256 _amount) public onlyOperator nonReentrant
	{
		require(_address_token != address_token_reward, "handle_stuck: Wrong token address");

		address address_user = msg.sender;

		IERC20 stake_token = IERC20(_address_token);
		stake_token.safeTransfer(address_user, _amount);
		
		emit HandleStuckCB(address_user, _amount);
	}

	//---------------------------------------------------------------
	// Variable Interfaces
	//---------------------------------------------------------------		
	function set_phase(uint256 _phase_start_block_id, uint256 _phase_count, uint256 _phase_interval_sec) external onlyOperator whenNotPaused
	{
		require(block.number <= _phase_start_block_id, "set_phase: Wrong block id");
		require(_phase_interval_sec <= MAX_PHASE_INTERVAL, "set_phase: Wrong interval value");
		require(_phase_count > 0, "set_phase: Wrong phase count");

		phase_start_block_id = _phase_start_block_id;
		phase_interval = _phase_interval_sec;
		phase_count = _phase_count;
	}

	function set_reward_amount_per_phase(uint256 _amount) external onlyOperator
	{
		refresh_reward_per_share();

		reward_amount_per_phase = _amount;
		emit SetRewardAmountPerPhaseCB(msg.sender, _amount);
	}

	function set_operator(address _new_address) external onlyOperator
	{
		require(_new_address != address(0), "set_operator: Wrong address");
		address_operator = _new_address;
		emit SetOperatorCB(msg.sender, _new_address);
	}

	function set_cakebaker(address _new_address) external onlyOperator
	{
		require(_new_address != address(0), "set_cakebaker: Wrong address");
		address_cakebaker = _new_address;
		emit SetCakeBakerCB(msg.sender, _new_address);
	}


	function get_pool_count() external view returns(uint256)
	{
		return pool_info.length;
	}

	function get_cur_phase() external view returns(uint256)
	{
		return phase_cur_serial;
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
	function _can_claim() internal view returns(bool)
	{
		return block.timestamp > (last_mint_time + phase_interval);
	}

	function _safe_reward_transfer(address _to, uint256 _amount) internal
	{
		IERC20 reward_token = IERC20(address_token_reward);
		uint256 cur_reward_balance = reward_token.balanceOf(address(this));

		if(_amount > cur_reward_balance)
			reward_token.safeTransfer(_to, cur_reward_balance);
		else
			reward_token.safeTransfer(_to, _amount);
	}

	function _get_cur_phase_by_block() internal view returns(uint256)
	{
		if(phase_start_timestamp == 0)
			return 0;
		else
			return (block.timestamp - phase_start_timestamp)/phase_interval;
	}

	function _refresh_reward_per_share(uint256 _pool_id) internal
	{
		if(phase_start_block_id == 0 || phase_start_timestamp == 0 && block.number < phase_start_block_id)
			return;
		
		if(last_mint_time == 0)
		{
			last_mint_time = block.timestamp; // skipping minting at the first phase
			return;
		}
		
		PoolInfo storage pool = pool_info[_pool_id];

		uint256 cur_phase = _get_cur_phase_by_block();
		uint256 accu_phase_count = cur_phase - phase_cur_serial;

		uint256 cur_stake_balance = IERC20(pool.address_token_stake).balanceOf(address(this));
		
		if(cur_stake_balance > 0 && accu_phase_count > 0 && pool.alloc_point > 0)
		{
			uint256 mint_reward_amount = accu_phase_count * reward_amount_per_phase * pool.alloc_point / total_alloc_point;
	
			// Mint native token -> Calf
			ITokenXBaseV3 reward_token = ITokenXBaseV3(address_token_reward);
			reward_token.mint(address(this), mint_reward_amount);

			pool.reward_amount_per_share = mint_reward_amount * 1e12 / cur_stake_balance;
		}
		else
			pool.reward_amount_per_share = 0;

		last_mint_time = block.timestamp;
		phase_cur_serial = cur_phase;
	}
}