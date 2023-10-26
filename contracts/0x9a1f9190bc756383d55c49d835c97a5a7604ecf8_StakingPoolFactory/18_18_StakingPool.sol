// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IStakingPool.sol";
import "./RewardsDistributionRecipient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
 * Website: alacritylsd.com
 * X/Twitter: x.com/alacritylsd
 * Telegram: t.me/alacritylsd
 */

/*
 * Users can stake their tokens and earn rewards over a specified duration in a staking pool.
 * A pool is designed to distribute rewards in a fair and transparent manner.
 *
 * Each pool contract keeps track of the staked tokens and the corresponding rewards for each
 * user. It calculates the reward rate based on the total rewards available and the duration of
 * the staking period. Users can stake their tokens by calling the stake function, and an optional
 * deposit fee can be deducted before adding the tokens to the pool. Similarly, users can withdraw
 * their staked tokens by calling the withdraw function.
 *
 * Users can claim their earned rewards by calling the getReward function. The rewards are distributed
 * in the form of a separate ERC20 token specified by the rewardsToken variable (veALSD). The
 * distribution of rewards is controlled by a rewards distribution contract (StakingPoolFactory).
 */

contract StakingPool is
    IStakingPool,
    RewardsDistributionRecipient,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public immutable rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    IERC20 private immutable rewardsToken;
    IERC20 public immutable stakingToken;
    uint256 public periodFinish;
    uint256 public rewardRate;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    bool private isDepositFeeEnabled = true;
    uint256 public depositFee = 50;

    address public feeManager;

    constructor(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        uint256 _durationInDays,
        address _feeManager
    ) {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        rewardsDuration = uint256(_durationInDays).mul(3600 * 24);
        feeManager = _feeManager;
    }

    receive() external payable virtual {}

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
            );
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function earned(address account) public view returns (uint256) {
        return
            _balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function stake(
        uint256 amount
    ) external payable virtual nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Amount cannot be null");

        if (
            address(stakingToken) !=
            address(0x0000000000000000000000000000000000000000)
        ) {
            require(msg.value <= 0, "msg.value > 0");
        }
        if (
            isDepositFeeEnabled &&
            address(stakingToken) !=
            address(0x0000000000000000000000000000000000000000)
        ) {
            uint256 fee = amount.mul(depositFee).div(10000);
            _transferStakingTokenFee(fee);
            amount = amount.sub(fee);
        }
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _transferStakingToken(amount);
    }

    function withdraw(
        uint256 amount
    ) external virtual nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Amount cannot be null");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _withdrawStakingToken(amount);
    }

    function _withdrawStakingToken(uint256 amount) internal virtual {
        stakingToken.safeTransfer(msg.sender, amount);
    }

    function getReward() external nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
        }
    }

    function setFeeManager(address _feeManager) external onlyFeeManager {
        require(_feeManager != address(0), "Invalid address");

        feeManager = _feeManager;
    }

    function setDepositFee(uint256 _depositFee) external onlyFeeManager {
        require(_depositFee <= 100, "Must keep deposit fee at 1% or less");
        depositFee = _depositFee;
    }

    function notifyRewardAmount(
        uint256 reward
    ) external override onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "High reward rate");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
    }

    function setDepositFeeState(bool _state) external onlyFeeManager {
        isDepositFeeEnabled = _state;
    }

    function _transferStakingToken(uint256 amount) internal virtual {
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function _transferStakingTokenFee(uint256 amount) internal virtual {
        stakingToken.safeTransferFrom(msg.sender, feeManager, amount);
    }

    function withdrawExcess(
        address to
    ) external virtual nonReentrant onlyRewardsDistribution {
        require(block.timestamp >= periodFinish, "Not ready");

        uint256 balance = stakingToken.balanceOf(address(this));
        require(balance > _totalSupply);

        uint256 amount = balance - _totalSupply;
        stakingToken.safeTransfer(to, amount);
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyFeeManager() {
        require(
            msg.sender == feeManager,
            "Only fee manager can call this function."
        );
        _;
    }
}