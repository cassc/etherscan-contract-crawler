// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '../Interfaces/IMintableToken.sol';
import '../Interfaces/IMasterXFinance.sol';
import '../Interfaces/IStrategy.sol';
import '../utils/PriceCalculator.sol';
import '../ContractWhitelisted.sol';

/*
 * @dev Farm contract for the launch of the charge ecosystem
 *
 * This contract accepts staked tokens and rewards users with reward tokens.
 * The contract has features to deposit the staked token in external farms to earn yield.
 * Yield management is handled by strategy contracts
 */
abstract contract MasterXFinance is
	AccessControlEnumerable,
	ReentrancyGuard,
	PriceCalculator,
	IMasterXFinance,
	ContractWhitelisted
{
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	using SafeERC20 for IERC20Metadata;

	uint256 public blocksPerYear = 10512000;

	// The block number when reward mining ends.
	uint256 public bonusEndBlock;

	// The block number when reward mining starts.
	uint256 public startBlock;

	// reward tokens created per block.
	uint256 public rewardPerBlock;

	// dev rewards in basis points of total rewards
	uint256 public devRewardPoint;

	// dev reward address for rewards.
	address public devAddress;

	// project rewards in basis points of total rewards
	uint256 public projectRewardPoint;

	// project reward address for rewards.
	address public projectAddress;

	// The precision factor
	uint256 public PRECISION_FACTOR;

	// The reward token
	IERC20Metadata public rewardToken;

	// The path to convert reward to stable
	address[] public rewardToStablePath;

	// Router to compute prices
	IUniswapV2Router02 public router;

	// Total allocation points. Must be the sum of all allocation points
	uint256 public totalAllocPoint = 0;

	// Info of each user that stakes tokens (stakedToken)
	mapping(uint256 => mapping(address => UserInfo)) public override userInfo;

	// Info of each staking pool
	PoolInfo[] public poolInfo;

	struct UserInfo {
		uint256 amount; // How many staked tokens the user has provided
		uint256 rewardDebt; // Reward debt
	}

	struct PoolInfo {
		IERC20 stakedToken; // The staked token
		uint256 allocPoint; // How many allocation points assigned to this pool.
		uint256 lastRewardBlock; // The block number of the last pool update
		uint256 accTokenPerShare; // Accrued token per share
		IStrategy strategy; // The staking strategy
	}

	// Funds reward tokens
	function _fundRewardTokens(address recipient, uint256 amount)
		internal
		virtual;

	event AddPool(address indexed stakedToken, uint256 allocPoint);
	event UpdatePool(uint256 indexed pid, uint256 allocPoint);
	event AdminTokenRecovery(address tokenRecovered, uint256 amount);
	event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
	event EmergencyWithdraw(
		address indexed user,
		uint256 indexed pid,
		uint256 amount
	);
	event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
	event NewRewardPerBlock(uint256 rewardPerBlock);
	event NewDevRewardPoint(uint256 point);
	event NewDevAddress(address indexed newAddress);
	event NewProjectRewardPoint(uint256 point);
	event NewProjectAddress(address indexed newAddress);
	event NewBlocksPerYear(uint256 blocksPerYear);
	event RewardsStop(uint256 blockNumber);
	event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

	constructor(
		IERC20Metadata _rewardToken,
		uint256 _rewardPerBlock,
		uint256 _startBlock,
		uint256 _bonusEndBlock,
		IUniswapV2Router02 _router,
		address[] memory _rewardToStablePath
	) {
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

		rewardToken = _rewardToken;
		rewardPerBlock = _rewardPerBlock;
		startBlock = _startBlock;
		bonusEndBlock = _bonusEndBlock;

		uint256 decimalsRewardToken = uint256(rewardToken.decimals());
		require(decimalsRewardToken < 30, 'Must be inferior to 30');

		PRECISION_FACTOR = uint256(10**(uint256(30).sub(decimalsRewardToken)));

		router = _router;
		rewardToStablePath = _rewardToStablePath;
	}

	modifier poolExists(uint256 pid) {
		require(pid < poolInfo.length, 'Pool does not exist');
		_;
	}

	/*
	 * @notice Deposit staked tokens and collect reward tokens (if any)
	 * @param _amount: amount to deposit (in stakedToken)
	 * @param _pid: The id of the pool
	 */
	function deposit(uint256 _amount, uint256 _pid)
		external
		override
		nonReentrant
		poolExists(_pid)
		isAllowedContract(msg.sender)
	{
		UserInfo storage user = userInfo[_pid][msg.sender];
		PoolInfo storage pool = poolInfo[_pid];

		_updatePool(_pid);

		if (user.amount > 0) {
			uint256 pending = user
				.amount
				.mul(pool.accTokenPerShare)
				.div(PRECISION_FACTOR)
				.sub(user.rewardDebt);
			if (pending > 0) {
				_safeRewardTransfer(address(msg.sender), pending);
			}
		}

		if (_amount > 0) {
			pool.stakedToken.safeTransferFrom(
				address(msg.sender),
				address(this),
				_amount
			);
			uint256 amountDeposit = pool.strategy.deposit(_amount);
			user.amount = user.amount.add(amountDeposit);
		}

		user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(
			PRECISION_FACTOR
		);

		emit Deposit(msg.sender, _pid, _amount);
	}

	/*
	 * @notice Withdraw staked tokens and collect reward tokens
	 * @param _amount: amount to withdraw (in stakedToken)
	 * @param _pid: The id of the pool
	 */
	function withdraw(uint256 _amount, uint256 _pid)
		external
		override
		nonReentrant
		poolExists(_pid)
	{
		UserInfo storage user = userInfo[_pid][msg.sender];
		PoolInfo storage pool = poolInfo[_pid];

		require(user.amount >= _amount, 'Amount to withdraw too high');

		uint256 stakedTokenSupply = pool.strategy.stakedLockedTotal();
		require(stakedTokenSupply > 0, 'Strategy has 0 tokens');

		_updatePool(_pid);

		uint256 pending = user
			.amount
			.mul(pool.accTokenPerShare)
			.div(PRECISION_FACTOR)
			.sub(user.rewardDebt);

		if (_amount > 0) {
			uint256 amountRemove = pool.strategy.withdraw(_amount);
			user.amount = amountRemove > user.amount
				? 0
				: user.amount.sub(amountRemove);

			_amount = Math.min(
				_amount,
				pool.stakedToken.balanceOf(address(this))
			);
			pool.stakedToken.safeTransfer(address(msg.sender), _amount);
		}

		if (pending > 0) {
			_safeRewardTransfer(address(msg.sender), pending);
		}

		user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(
			PRECISION_FACTOR
		);

		emit Withdraw(msg.sender, _pid, _amount);
	}

	/*
	 * @notice Withdraw staked tokens without caring about rewards
	 * @param _pid: The id of the pool
	 * @dev Needs to be for emergency.
	 */
	function emergencyWithdraw(uint256 _pid)
		external
		override
		nonReentrant
		poolExists(_pid)
	{
		UserInfo storage user = userInfo[_pid][msg.sender];
		PoolInfo storage pool = poolInfo[_pid];

		uint256 amountToTransfer = user.amount;
		user.amount = 0;
		user.rewardDebt = 0;

		if (amountToTransfer > 0) {
			pool.strategy.withdraw(amountToTransfer);
			pool.stakedToken.safeTransfer(
				address(msg.sender),
				amountToTransfer
			);
		}

		emit EmergencyWithdraw(msg.sender, _pid, user.amount);
	}

	// Update reward variables for all pools. Be careful of gas spending!
	function massUpdatePools() public {
		uint256 length = poolInfo.length;
		for (uint256 pid = 0; pid < length; ++pid) {
			_updatePool(pid);
		}
	}

	/**
	 * @notice It allows the admin to recover wrong tokens sent to the contract
	 * @param _tokenAddress: the address of the token to withdraw
	 * @param _tokenAmount: the number of tokens to withdraw
	 * @dev This function is only callable by admin.
	 */
	function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(
			_tokenAddress != address(rewardToken),
			'Cannot be reward token'
		);

		IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

		emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
	}

	/*
	 * @notice Stop rewards
	 * @dev Only callable by owner
	 */
	function stopReward() external onlyRole(DEFAULT_ADMIN_ROLE) {
		bonusEndBlock = block.number;
	}

	/**
	 * @notice Allows admin to add a pool
	 * @param _allocPoint: the allocation points for the pool
	 * @param _stakedToken: the staking token
	 * @param _strategy: the staking strategy
	 * @param _withUpdate: weather to update pools
	 * @dev This function is only callable by admin. Do not call more than once for a single token
	 */
	function addPool(
		uint256 _allocPoint,
		IERC20 _stakedToken,
		IStrategy _strategy,
		bool _withUpdate
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(
			address(_strategy.stakedToken()) == address(_stakedToken),
			'Mismatch staked token'
		);
		if (_withUpdate) {
			massUpdatePools();
		}
		uint256 lastRewardBlock = block.number > startBlock
			? block.number
			: startBlock;
		totalAllocPoint = totalAllocPoint.add(_allocPoint);
		poolInfo.push(
			PoolInfo({
				stakedToken: _stakedToken,
				allocPoint: _allocPoint,
				lastRewardBlock: lastRewardBlock,
				accTokenPerShare: 0,
				strategy: _strategy
			})
		);

		//approve strategy to spend master tokens
		_stakedToken.approve(address(_strategy), type(uint256).max);
		emit AddPool(address(_stakedToken), _allocPoint);
	}

	/**
	 * @notice Allows admin to update a pool
	 * @param _pid: pool id
	 * @param _allocPoint: the allocation points for the pool
	 * @param _withUpdate: weather to update pools
	 * @dev This function is only callable by admin
	 */
	function updatePool(
		uint256 _pid,
		uint256 _allocPoint,
		bool _withUpdate
	) external onlyRole(DEFAULT_ADMIN_ROLE) poolExists(_pid) {
		if (_withUpdate) {
			massUpdatePools();
		}
		totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
			_allocPoint
		);
		poolInfo[_pid].allocPoint = _allocPoint;
		emit UpdatePool(_pid, _allocPoint);
	}

	/*
	 * @notice Update reward per block
	 * @dev Only callable by owner.
	 * @param _rewardPerBlock: the reward per block
	 */
	function updateRewardPerBlock(uint256 _rewardPerBlock)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		rewardPerBlock = _rewardPerBlock;
		emit NewRewardPerBlock(_rewardPerBlock);
	}

	/*
	 * @notice Update dev reward point
	 * @dev Only callable by owner.
	 * @param _devRewardPoint: the dev reward points of total rewards
	 */
	function updateDevRewardPoint(uint256 _devRewardPoint)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		devRewardPoint = _devRewardPoint;
		emit NewDevRewardPoint(_devRewardPoint);
	}

	/*
	 * @notice Update project reward point
	 * @dev Only callable by owner.
	 * @param _projectRewardPoint: the project reward points of total rewards
	 */
	function updateProjectRewardPoint(uint256 _projectRewardPoint)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		projectRewardPoint = _projectRewardPoint;
		emit NewProjectRewardPoint(_projectRewardPoint);
	}

	/*
	 * @notice Update dev address
	 * @dev Only callable by owner.
	 * @param _devAddress: the new address
	 */
	function updateDevAddress(address _devAddress)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(_devAddress != devAddress, 'Same address');
		require(_devAddress != address(0), 'Cannot be burn address');

		emit NewDevAddress(_devAddress);
		devAddress = _devAddress;
	}

	/*
	 * @notice Update project reward address
	 * @dev Only callable by owner.
	 * @param _projectAddress: the new address
	 */
	function updateProjectAddress(address _projectAddress)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(_projectAddress != projectAddress, 'Same address');
		require(_projectAddress != address(0), 'Cannot be burn address');

		emit NewProjectAddress(_projectAddress);
		projectAddress = _projectAddress;
	}

	/**
	 * @notice It allows the admin to update start and end blocks
	 * @dev This function is only callable by owner.
	 * @param _startBlock: the new start block
	 * @param _bonusEndBlock: the new end block
	 */
	function updateStartAndEndBlocks(
		uint256 _startBlock,
		uint256 _bonusEndBlock
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(block.number < startBlock, 'Pool has started');
		require(
			_startBlock < _bonusEndBlock,
			'New startBlock must be lower than new endBlock'
		);
		require(
			block.number < _startBlock,
			'New startBlock must be higher than current block'
		);

		startBlock = _startBlock;
		bonusEndBlock = _bonusEndBlock;

		// Set the lastRewardBlock as the startBlock
		uint256 length = poolInfo.length;
		for (uint256 pid = 0; pid < length; ++pid) {
			poolInfo[pid].lastRewardBlock = startBlock;
		}

		emit NewStartAndEndBlocks(_startBlock, _bonusEndBlock);
	}

	/*
	 * @notice Update number of blocks per year
	 * @dev Only callable by owner.
	 * @param _blocksPerYear: the new number of blocks
	 */
	function updateBlocksPerYear(uint256 _blocksPerYear)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(_blocksPerYear != blocksPerYear, 'Same number');

		emit NewBlocksPerYear(_blocksPerYear);
		blocksPerYear = _blocksPerYear;
	}

	/*
	 * @notice View function to see pending reward on frontend.
	 * @param _user: user address
	 * @param _pid: pool id
	 * @return Pending reward for a given user
	 */
	function pendingReward(address _user, uint256 _pid)
		external
		view
		returns (uint256)
	{
		UserInfo storage user = userInfo[_pid][_user];
		PoolInfo storage pool = poolInfo[_pid];
		uint256 stakedTokenSupply = pool.strategy.stakedLockedTotal();
		if (block.number > pool.lastRewardBlock && stakedTokenSupply != 0) {
			uint256 multiplier = _getMultiplier(
				pool.lastRewardBlock,
				block.number
			);
			uint256 reward = multiplier
				.mul(rewardPerBlock)
				.mul(pool.allocPoint)
				.div(totalAllocPoint);
			uint256 adjustedTokenPerShare = pool.accTokenPerShare.add(
				reward.mul(PRECISION_FACTOR).div(stakedTokenSupply)
			);
			return
				user
					.amount
					.mul(adjustedTokenPerShare)
					.div(PRECISION_FACTOR)
					.sub(user.rewardDebt);
		} else {
			return
				user
					.amount
					.mul(pool.accTokenPerShare)
					.div(PRECISION_FACTOR)
					.sub(user.rewardDebt);
		}
	}

	/*
	 * @notice View function to see APR on frontend.
	 * @param _pid: pool id
	 * @return APR for pool
	 */
	function APR(uint256 _pid) external view override returns (uint256) {
		if (block.number > bonusEndBlock) {
			return 0;
		}

		PoolInfo storage pool = poolInfo[_pid];

		uint256 reward = blocksPerYear
			.mul(rewardPerBlock)
			.mul(pool.allocPoint)
			.div(totalAllocPoint);

		return
			TVL(_pid) > 0
				? (reward * _getTokenPrice(router, rewardToStablePath)) /
					TVL(_pid)
				: 0;
	}

	/*
	 * @notice View function to see TVL on frontend.
	 * @param _pid: pool id
	 * @return TVL for pool
	 */
	function TVL(uint256 _pid) public view override returns (uint256) {
		PoolInfo storage pool = poolInfo[_pid];

		return
			pool
				.strategy
				.stakedLockedTotal()
				.mul(pool.strategy.stakedTokenPrice())
				.div(1e18);
	}

	/*
	 * @notice View function to get staked token price on frontend.
	 * @param _pid: pool id
	 * @return Price of staked token
	 */
	function stakedTokenPrice(uint256 _pid)
		public
		view
		override
		returns (uint256)
	{
		PoolInfo storage pool = poolInfo[_pid];
		return pool.strategy.stakedTokenPrice();
	}

	/*
	 * @notice View function to see number of pools.
	 * @return Number of pools
	 */
	function numPools() external view returns (uint256) {
		return poolInfo.length;
	}

	/*
	 * @notice Update reward variables of the given pool to be up-to-date.
	 * @param _pid: The pool id
	 */
	function _updatePool(uint256 _pid) internal {
		PoolInfo storage pool = poolInfo[_pid];
		if (block.number <= pool.lastRewardBlock) {
			return;
		}

		uint256 stakedTokenSupply = pool.strategy.stakedLockedTotal();

		if (stakedTokenSupply == 0) {
			pool.lastRewardBlock = block.number;
			return;
		}

		uint256 multiplier = _getMultiplier(pool.lastRewardBlock, block.number);
		uint256 reward = multiplier
			.mul(rewardPerBlock)
			.mul(pool.allocPoint)
			.div(totalAllocPoint);
		pool.accTokenPerShare = pool.accTokenPerShare.add(
			reward.mul(PRECISION_FACTOR).div(stakedTokenSupply)
		);
		pool.lastRewardBlock = block.number;

		if (reward > 0) {
			// fund pool
			_fundRewardTokens(address(this), reward);

			if (devAddress != address(0) && devRewardPoint > 0) {
				// fund dev wallet
				_fundRewardTokens(
					devAddress,
					reward.mul(devRewardPoint).div(10000)
				);
			}

			if (projectAddress != address(0) && projectRewardPoint > 0) {
				// fund project wallet
				_fundRewardTokens(
					projectAddress,
					reward.mul(projectRewardPoint).div(10000)
				);
			}
		}
	}

	/*
	 * @notice Safe transfer function, just in case if rounding error causes pool to not have enough
	 */
	function _safeRewardTransfer(address _to, uint256 _amount) internal {
		_amount = Math.min(_amount, rewardToken.balanceOf(address(this)));
		rewardToken.safeTransfer(_to, _amount);
	}

	/*
	 * @notice Return reward multiplier over the given _from to _to block.
	 * @param _from: block to start
	 * @param _to: block to finish
	 */
	function _getMultiplier(uint256 _from, uint256 _to)
		internal
		view
		returns (uint256)
	{
		if (_to <= bonusEndBlock) {
			return _to.sub(_from);
		} else if (_from >= bonusEndBlock) {
			return 0;
		} else {
			return bonusEndBlock.sub(_from);
		}
	}
}