// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract GaugeMultiRewards is ReentrancyGuard, Pausable {
	using SafeERC20 for IERC20;

	/* ========== STATE VARIABLES ========== */

	struct Reward {
		address rewardsDistributor;
		uint256 rewardsDuration;
		uint256 periodFinish;
		uint256 rewardRate;
		uint256 lastUpdateTime;
		uint256 rewardPerTokenStored;
	}

	IERC20 public stakingToken;

	mapping(address => Reward) public rewardData;

	address public governance;
	address[] public rewardTokens;

	// user -> reward token -> amount
	mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
	mapping(address => mapping(address => uint256)) public rewards;

	uint256 private _totalSupply;
	uint256 public derivedSupply;

	mapping(address => uint256) private _balances;
	mapping(address => uint256) public derivedBalances;

	/* ========== CONSTRUCTOR ========== */

	constructor(
		address _stakingToken
	) {
		governance = msg.sender;
		stakingToken = IERC20(_stakingToken);
	}

	function addReward(
		address _rewardsToken,
		address _rewardsDistributor,
		uint256 _rewardsDuration
	) public onlyGovernance {
		require(rewardData[_rewardsToken].rewardsDuration == 0);
		rewardTokens.push(_rewardsToken);
		rewardData[_rewardsToken].rewardsDistributor = _rewardsDistributor;
		rewardData[_rewardsToken].rewardsDuration = _rewardsDuration;
	}

	/* ========== VIEWS ========== */

	function totalSupply() external view returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) external view returns (uint256) {
		return _balances[account];
	}

	function lastTimeRewardApplicable(address _rewardsToken) public view returns (uint256) {
		return Math.min(block.timestamp, rewardData[_rewardsToken].periodFinish);
	}

	function rewardPerToken(address _rewardsToken) public view returns (uint256) {
		if (_totalSupply == 0) {
			return rewardData[_rewardsToken].rewardPerTokenStored;
		}
		return rewardData[_rewardsToken].rewardPerTokenStored
                    + (((lastTimeRewardApplicable(_rewardsToken)
					- rewardData[_rewardsToken].lastUpdateTime)
					* rewardData[_rewardsToken].rewardRate
                    * 1e6) // from 1e18
                    / _totalSupply
                );
	}

	function earned(address _account, address _rewardsToken) public view returns (uint256) {
		uint256 userBalance = _balances[_account];

		return
			userBalance * (rewardPerToken(_rewardsToken) - userRewardPerTokenPaid[_account][_rewardsToken]) / 1e6 + rewards[_account][_rewardsToken];
	}

	function getRewardForDuration(address _rewardsToken) external view returns (uint256) {
		return rewardData[_rewardsToken].rewardRate * rewardData[_rewardsToken].rewardsDuration;
	}

	/* ========== MUTATIVE FUNCTIONS ========== */

	function setRewardsDistributor(address _rewardsToken, address _rewardsDistributor) external onlyGovernance {
		rewardData[_rewardsToken].rewardsDistributor = _rewardsDistributor;
	}

	function _stake(uint256 amount, address account) internal nonReentrant whenNotPaused updateReward(account) {
		require(amount > 0, "Cannot stake 0");
		_totalSupply = _totalSupply + amount;
		_balances[account] = _balances[account] + amount;
		stakingToken.safeTransferFrom(msg.sender, address(this), amount);
		emit Staked(account, amount);
	}

	function _withdraw(uint256 amount, address account) internal nonReentrant updateReward(account) {
		require(amount > 0, "Cannot withdraw 0");
		_totalSupply = _totalSupply - amount;
		_balances[account] = _balances[account] - amount;
		stakingToken.safeTransfer(msg.sender, amount);
		emit Withdrawn(account, amount);
	}

	function stake(uint256 amount) external {
		_stake(amount, msg.sender);
	}

	function stakeFor(address account, uint256 amount) external {
		_stake(amount, account);
	}

	function withdraw(uint256 amount) external {
		_withdraw(amount, msg.sender);
	}

	function withdrawFor(address account, uint256 amount) external {
		require(tx.origin == account, "withdrawFor: account != tx.origin");
		_withdraw(amount, account);
	}

	function getRewardFor(address account) public nonReentrant updateReward(account) {
		for (uint256 i; i < rewardTokens.length; i++) {
			address _rewardsToken = rewardTokens[i];
			uint256 reward = rewards[account][_rewardsToken];
			if (reward > 0) {
				rewards[account][_rewardsToken] = 0;
				IERC20(_rewardsToken).safeTransfer(account, reward);
				emit RewardPaid(account, _rewardsToken, reward);
			}
		}
	}

	/* ========== RESTRICTED FUNCTIONS ========== */

	function setGovernance(address _governance) public onlyGovernance {
		governance = _governance;
	}

	function notifyRewardAmount(address _rewardsToken, uint256 reward) external updateReward(address(0)) {
		require(rewardData[_rewardsToken].rewardsDistributor == msg.sender);
		// handle the transfer of reward tokens via `transferFrom` to reduce the number
		// of transactions required and ensure correctness of the reward amount
		IERC20(_rewardsToken).safeTransferFrom(msg.sender, address(this), reward);

		if (block.timestamp >= rewardData[_rewardsToken].periodFinish) {
			rewardData[_rewardsToken].rewardRate = reward / rewardData[_rewardsToken].rewardsDuration;
		} else {
			uint256 remaining = rewardData[_rewardsToken].periodFinish - block.timestamp;
			uint256 leftover = remaining * rewardData[_rewardsToken].rewardRate;
			rewardData[_rewardsToken].rewardRate = (reward + leftover) / rewardData[_rewardsToken].rewardsDuration;
		}

		rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
		rewardData[_rewardsToken].periodFinish = block.timestamp + rewardData[_rewardsToken].rewardsDuration;
		emit RewardAdded(reward);
	}

	function recoverERC20(
		address tokenAddress,
		uint256 tokenAmount,
		address destination
	) external onlyGovernance {
		require(tokenAddress != address(stakingToken), "Cannot withdraw staking token");
		require(rewardData[tokenAddress].lastUpdateTime == 0, "Cannot withdraw reward token");
		IERC20(tokenAddress).safeTransfer(destination, tokenAmount);
		emit Recovered(tokenAddress, tokenAmount);
	}

	function setRewardsDuration(address _rewardsToken, uint256 _rewardsDuration) external {
		require(block.timestamp > rewardData[_rewardsToken].periodFinish, "Reward period still active");
		require(rewardData[_rewardsToken].rewardsDistributor == msg.sender);
		require(_rewardsDuration > 0, "Reward duration must be non-zero");
		rewardData[_rewardsToken].rewardsDuration = _rewardsDuration;
		emit RewardsDurationUpdated(_rewardsToken, rewardData[_rewardsToken].rewardsDuration);
	}

	/* ========== MODIFIERS ========== */

	modifier updateReward(address account) {
		for (uint256 i; i < rewardTokens.length; i++) {
			address token = rewardTokens[i];
			rewardData[token].rewardPerTokenStored = rewardPerToken(token);
			rewardData[token].lastUpdateTime = lastTimeRewardApplicable(token);
			if (account != address(0)) {
				rewards[account][token] = earned(account, token);
				userRewardPerTokenPaid[account][token] = rewardData[token].rewardPerTokenStored;
			}
		}
		_;
	}

	modifier onlyGovernance() {
		require(msg.sender == governance, "!gov");
		_;
	}

	/* ========== EVENTS ========== */

	event RewardAdded(uint256 reward);
	event Staked(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RewardPaid(address indexed user, address indexed rewardsToken, uint256 reward);
	event RewardsDurationUpdated(address token, uint256 newDuration);
	event Recovered(address token, uint256 amount);
}