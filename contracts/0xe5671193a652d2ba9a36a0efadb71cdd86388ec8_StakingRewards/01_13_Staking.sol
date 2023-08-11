// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/IStakingRewards.sol";
import "./interfaces/IMasterChef.sol";

contract StakingRewards is IStakingRewards, Ownable, Pausable, ReentrancyGuard {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	uint256 public immutable PID;

	IERC20 public rewardsTokenXFT;
	IERC20 public rewardsTokenSUSHI;
	IERC20 public stakingToken;
	IMasterChef public masterChef;

	PoolInfo public poolInfo;

	uint256 public periodFinish;
	uint256 public rewardRate;
	uint256 public rewardsDuration;
	uint256 public lastUpdateTime;
	uint256 public rewardPerTokenStored;

	mapping(address => UserInfo) public userInfo;
	mapping(address => uint256) public userRewardPerTokenPaid;
	mapping(address => uint256) public rewardsXFT;
	mapping(address => uint256) public rewardsSUSHI;

	uint256 private _totalStaked;

	modifier updateReward(address account) {
		rewardPerTokenStored = rewardPerToken();
		lastUpdateTime = lastTimeRewardApplicable();
		if (account != address(0)) {
			rewardsXFT[account] = earnedXFT(account);
			userRewardPerTokenPaid[account] = rewardPerTokenStored;

			updatePoolInfo();
			if (userInfo[account].amount > 0) {
				rewardsSUSHI[account] = earnedSushi(account);
			}
		}
		_;
	}

	constructor(
		address _rewardsTokenXFT,
		address _rewardsTokenSUSHI,
		address _stakingToken,
		address _masterChef,
		uint256 _pid
	) Ownable() {
		rewardsTokenXFT = IERC20(_rewardsTokenXFT);
		rewardsTokenSUSHI = IERC20(_rewardsTokenSUSHI);
		stakingToken = IERC20(_stakingToken);
		masterChef = IMasterChef(_masterChef);

		PID = _pid;
		periodFinish = 0;
		rewardRate = 0;
		rewardsDuration = 30 days;
	}

	function totalStaked() external view override returns (uint256) {
		return _totalStaked;
	}

	function balanceOf(address _account)
		external
		view
		override
		returns (uint256)
	{
		return userInfo[_account].amount;
	}

	function getRewardForDuration() external view override returns (uint256) {
		return rewardRate.mul(rewardsDuration);
	}

	function exit() external override {
		withdraw(userInfo[msg.sender].amount);
		getReward();
	}

	function notifyRewardAmount(uint256 _reward)
		external
		onlyOwner
		updateReward(address(0))
	{
		if (block.timestamp >= periodFinish) {
			rewardRate = _reward.div(rewardsDuration);
		} else {
			uint256 remaining = periodFinish.sub(block.timestamp);
			uint256 leftover = remaining.mul(rewardRate);
			rewardRate = _reward.add(leftover).div(rewardsDuration);
		}

		uint256 balance = rewardsTokenXFT.balanceOf(address(this));
		require(
			rewardRate <= balance.div(rewardsDuration),
			"Provided reward too high"
		);

		lastUpdateTime = block.timestamp;
		periodFinish = block.timestamp.add(rewardsDuration);
		emit RewardAdded(_reward);
	}

	function updatePeriodFinish(uint256 _timestamp)
		external
		onlyOwner
		updateReward(address(0))
	{
		periodFinish = _timestamp;
	}

	function stake(uint256 _amount)
		external
		override
		nonReentrant
		whenNotPaused
		updateReward(msg.sender)
	{
		require(_amount > 0, "Stake: cant stake 0");
		_totalStaked = _totalStaked.add(_amount);
		stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

		stakingToken.approve(address(masterChef), _amount);
		masterChef.deposit(PID, _amount);

		UserInfo storage user = userInfo[msg.sender];

		user.amount = user.amount.add(_amount);
		user.rewardDebt = user.amount
			.mul(poolInfo.accSushiPerShare)
			.div(1e12);

		emit Staked(msg.sender, _amount);
	}

	function withdraw(uint256 _amount)
		public
		override
		nonReentrant
		updateReward(msg.sender)
	{
		require(_amount > 0, "Withdraw: cant withdraw 0");

		UserInfo storage user = userInfo[msg.sender];
		require(user.amount >= _amount, "Withdraw: insufficient funds");

		_totalStaked = _totalStaked.sub(_amount);

		masterChef.withdraw(PID, _amount);

		user.amount = user.amount.sub(_amount);
		user.rewardDebt = user.amount
			.mul(poolInfo.accSushiPerShare)
			.div(1e12);

		stakingToken.safeTransfer(msg.sender, _amount);
		emit Withdrawn(msg.sender, _amount);
	}

	function getReward() public override nonReentrant updateReward(msg.sender) {
		uint256 rewardXFT = rewardsXFT[msg.sender];
		uint256 rewardSUSHI = rewardsSUSHI[msg.sender];

		if (rewardXFT > 0) {
			rewardsXFT[msg.sender] = 0;
			rewardsTokenXFT.safeTransfer(msg.sender, rewardXFT);
			emit XFTRewardPaid(msg.sender, rewardXFT);
		}

		if (rewardSUSHI > 0) {
			masterChef.deposit(PID, 0); // to get pending Sushi from onsen
			rewardsSUSHI[msg.sender] = 0;
			userInfo[msg.sender].rewardDebt = userInfo[msg.sender]
				.amount
				.mul(poolInfo.accSushiPerShare)
				.div(1e12);
			safeSushiTransfer(msg.sender, rewardSUSHI);
			emit SUSHIRewardPaid(msg.sender, rewardSUSHI);
		}
	}

	function lastTimeRewardApplicable() public view override returns (uint256) {
		return Math.min(block.timestamp, periodFinish);
	}

	function rewardPerToken() public view override returns (uint256) {
		if (_totalStaked == 0) {
			return rewardPerTokenStored;
		}
		return
			rewardPerTokenStored.add(
				lastTimeRewardApplicable()
					.sub(lastUpdateTime)
					.mul(rewardRate)
					.mul(1e18)
					.div(_totalStaked)
			);
	}

	function earnedXFT(address _account)
		public
		view
		override
		returns (uint256)
	{
		return
			userInfo[_account]
				.amount
				.mul(rewardPerToken().sub(userRewardPerTokenPaid[_account]))
				.div(1e18)
				.add(rewardsXFT[_account]);
	}

	function earnedSushi(address _account)
		public
		view
		override
		returns (uint256)
	{
		(
			address _lpToken,
			uint256 _allocPoint,
			uint256 _lastRewardBlock,
			uint256 _accSushiPerShare
		) = masterChef.poolInfo(PID);

		UserInfo storage user = userInfo[_account];
		if (user.amount == 0) return rewardsSUSHI[_account];
		uint256 lpSupply = IERC20(_lpToken).balanceOf(address(masterChef));
		if (block.number > _lastRewardBlock && lpSupply != 0) {
			uint256 multiplier =
				masterChef.getMultiplier(_lastRewardBlock, block.number);
			uint256 sushiReward =
				multiplier.mul(masterChef.sushiPerBlock()).mul(_allocPoint).div(
					masterChef.totalAllocPoint()
				);
			_accSushiPerShare = _accSushiPerShare.add(
				sushiReward.mul(1e12).div(lpSupply)
			);
		}
		return
			rewardsSUSHI[_account].add(
				user.amount.mul(_accSushiPerShare).div(1e12).sub(
					user.rewardDebt
				)
			);
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	function safeSushiTransfer(address _to, uint256 _amount) internal {
		uint256 sushiBal = rewardsTokenSUSHI.balanceOf(address(this));
		if (_amount > sushiBal) {
			rewardsTokenSUSHI.safeTransfer(_to, sushiBal);
		} else {
			rewardsTokenSUSHI.safeTransfer(_to, _amount);
		}
	}

	function updatePoolInfo() internal {
		masterChef.updatePool(PID);
		(
			address _lpToken,
			uint256 _allocPoint,
			uint256 _lastRewardBlock,
			uint256 _accSushiPerShare
		) = masterChef.poolInfo(PID);

		poolInfo = PoolInfo(
			IERC20(_lpToken),
			_allocPoint,
			_lastRewardBlock,
			_accSushiPerShare
		);
	}
}