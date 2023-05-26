// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./interfaces/IGensoMetaStakingPool.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GensoMetaStakingPool is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public rewardsToken;
    address public stakingToken;

    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public rewardAmount = 0;
    uint256 public rewardDuration = 0;
    uint256 public periodFinish = 0;
    uint256 public MINIMUM_CLAIMABLE_TIME = 3 days;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _depositTime;

    bool public initialize;
    bool public paused;

    /**
     * @dev Emitted when reward added.
     */
    event RewardAdded(uint256 reward, uint256 duration);

    /**
     * @dev Emitted when token staked.
     */
    event Staked(address indexed user, uint256 amount);

    /**
     * @dev Emitted when token withdraw.
     */
    event Withdrawn(address indexed user, uint256 amount);

    /**
     * @dev Emitted when reward paid.
     */
    event RewardPaid(address indexed user, uint256 reward);

    /**
     * @dev Emitted when admin recovered token.
     */
    event Recovered(address token, uint256 amount);

    /**
     * @dev Initializes the contract setting.
     */
    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = _stakingToken;
        rewardsToken = _rewardsToken;

        initialize = false;
    }

    /**
     * @dev initialize staking pool by setting `reward` and `duration` can only done by owner.
     */
    function init(uint256 reward, uint256 duration) external onlyOwner {
        notifyRewardAmount(reward, duration);
        initialize = true;
    }

    /**
     * @dev Get total stake amount
     *
     * Returns total amount staking at this contract
     *
     * @return uint256
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Get stake balance by `account`
     *
     * Returns user staking amount at this contract
     *
     * @return uint256
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Get last time reward applicable
     *
     * Returns last time reward applicable
     *
     * @return uint256
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return (block.timestamp < periodFinish) ? block.timestamp : periodFinish;
    }

    /**
     * @dev Get reward for duration
     *
     * Returns reward for duration
     *
     * @return uint256
     */
    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardDuration);
    }

    /**
     * @dev Get reward per token
     *
     * Returns reward per token
     *
     * @return uint256
     */
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return 0;
        }
        uint256 _rewardPerToken =
            rewardPerTokenStored.add(
                (lastTimeRewardApplicable().sub(lastUpdateTime)).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
        return _rewardPerToken;
    }

    /**
     * @dev Get earned token by `account`
     *
     * Returns earned token
     *
     * @return uint256
     */
    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    /**
     * @dev Update reward by `account`
     */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /**
     * @dev Stake `amount` token
     *
     * Emits an {Staked} event.
     */
    function stake(uint256 amount) external whenNotPaused updateReward(msg.sender) {
        require(initialize == true, "GensoMetaStakingPool: not initialized");
        require(amount > 0, "GensoMetaStakingPool: Cannot stake 0");
        _depositTime[msg.sender] = block.timestamp;
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Unstake `amount` token
     *
     * Emits an {Withdrawn} event.
     */
    function unstake(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(initialize == true, "GensoMetaStakingPool: not initialized");
        require(amount > 0, "GensoMetaStakingPool: Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        IERC20(stakingToken).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev Claim reward token
     *
     * Emits an {RewardPaid} event.
     */
    function claim() public nonReentrant updateReward(msg.sender) {
        require(initialize == true, "GensoMetaStakingPool: not initialized");
        require(block.timestamp > _depositTime[msg.sender].add(MINIMUM_CLAIMABLE_TIME), "GensoMetaStakingPool: not reach claimable time");
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            if(reward > IERC20(rewardsToken).balanceOf(address(this))) {
                reward = IERC20(rewardsToken).balanceOf(address(this));
            }
            IERC20(rewardsToken).safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /**
     * @dev Get deposit time by `account`
     *
     * Returns deposit time
     *
     * @return uint256
     */
    function depositTime(address account) public view returns (uint256) {
        return _depositTime[account];
    }

    /**
     * @dev Claim reward token and unstake token
     *
     * Emits {RewardPaid} {Withdrawn} event.
     */
    function exit() external {
        claim();
        unstake(_balances[msg.sender]);
    }

    /**
     * @dev Notify reward amount into staking contract, by pass `reward` and `duration`
     *
     * Emits {RewardAdded} event.
     */
    function notifyRewardAmount(uint256 reward, uint256 duration) public onlyOwner updateReward(address(0)) {
        uint256 balance = IERC20(rewardsToken).balanceOf(address(this));
        require(reward > 0, "GensoMetaStakingPool: reward must over zero");
        require(duration > 0, "GensoMetaStakingPool: duration must over zero");
        require(balance >= reward, "GensoMetaStakingPool: not enough reward balance");
        require(periodFinish <= block.timestamp, "GensoMetaStakingPool: reward in duration, must wait until finish");

        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(duration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        require(rewardRate <= balance.div(duration), "GensoMetaStakingPool: Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);
        rewardAmount = rewardAmount.add(reward);
        rewardDuration = rewardDuration.add(duration);
        emit RewardAdded(reward, duration);
    }

    /**
     * @dev Recover `tokenAddress` with `tokenAmount`, can only done by owner
     *
     * Emits an {Recovered} event.
     */
    function recover(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "GensoMetaStakingPool: Cannot withdraw the staking token");
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * @dev Throws if contract paused
     */
    modifier whenNotPaused {
        require(!paused, "GensoMetaStakingPool: This action cannot be performed while the contract is paused");
        _;
    }

    /**
     * @dev Set stake contract pause
     */
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }
}