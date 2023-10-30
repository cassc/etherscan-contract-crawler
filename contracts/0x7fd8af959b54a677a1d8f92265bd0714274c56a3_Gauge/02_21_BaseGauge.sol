// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IBaseGauge.sol";

abstract contract BaseGauge is IBaseGauge, OwnableUpgradeable {
    IERC20 public immutable REWARD_TOKEN;
    //// @notice rewards are distributed over `duration` seconds when queued.
    uint256 public duration;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    /**
    @notice that are queued to be distributed on a `queueNewRewards` call
    @dev rewards are queued when an account `_updateReward`.
    */
    uint256 public queuedRewards;
    uint256 public currentRewards;
    uint256 public historicalRewards;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardsAdded(
        uint256 currentRewards,
        uint256 lastUpdateTime,
        uint256 periodFinish,
        uint256 rewardRate,
        uint256 historicalRewards
    );

    event RewardsQueued(address indexed from, uint256 amount);

    event RewardPaid(address indexed user, uint256 reward);
    event UpdatedRewards(
        address indexed account,
        uint256 rewardPerTokenStored,
        uint256 lastUpdateTime,
        uint256 rewards,
        uint256 userRewardPerTokenPaid
    );
    event Sweep(address indexed token, uint256 amount);

    event DurationUpdated(
        uint256 duration,
        uint256 rewardRate,
        uint256 periodFinish
    );

    function _newEarning(address) internal view virtual returns (uint256);

    function _updateReward(address) internal virtual;

    function _rewardPerToken() internal view virtual returns (uint256);

    modifier updateReward(address account) {
        _updateReward(account);
        _;
    }

    constructor(address _rewardsToken) {
        require(
            address(_rewardsToken) != address(0x0),
            "rewardsToken 0x0 address"
        );
        REWARD_TOKEN = IERC20(_rewardsToken);
    }

    function __initialize(address _owner) internal {
        require(_owner != address(0), "_owner 0x0 address");
        duration = 14 days;
        _transferOwnership(_owner);
    }

    /**
    @notice set the duration of the reward distribution.
    @param _newDuration duration in seconds. 
     */
    function setDuration(
        uint256 _newDuration
    ) external onlyOwner updateReward(address(0)) {
        require(_newDuration != 0, "duration should be greater than zero");
        if (block.timestamp < periodFinish) {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = leftover / _newDuration;
            periodFinish = block.timestamp + _newDuration;
        }
        duration = _newDuration;
        emit DurationUpdated(_newDuration, rewardRate, periodFinish);
    }

    /**
     *  @return timestamp until rewards are distributed
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /** @notice reward per token deposited
     *  @dev gives the total amount of rewards distributed since the inception of the pool.
     *  @return rewardPerToken
     */
    function rewardPerToken() external view returns (uint256) {
        return _rewardPerToken();
    }

    function _protectedTokens(
        address _token
    ) internal view virtual returns (bool) {
        return _token == address(REWARD_TOKEN);
    }

    /** @notice sweep tokens that are airdropped/transferred into the gauge.
     *  @dev sweep can only be done on non-protected tokens.
     *  @return _token to sweep
     */
    function sweep(address _token) external onlyOwner returns (bool) {
        require(_protectedTokens(_token) == false, "protected token");
        uint256 amount = IERC20(_token).balanceOf(address(this));

        SafeERC20.safeTransfer(IERC20(_token), owner(), amount);
        emit Sweep(_token, amount);
        return true;
    }

    /** @notice earnings for an account
     *  @dev earnings are based on lock duration and boost
     *  @return amount of tokens earned
     */
    function earned(address _account) external view virtual returns (uint256) {
        return _newEarning(_account);
    }

    /**
     * @notice
     * Add new rewards to be distributed over a week
     * @dev Trigger reward rate recalculation using `_amount` and queue rewards
     * @param _amount token to add to rewards
     * @return true
     */
    function queueNewRewards(uint256 _amount) external override returns (bool) {
        require(_amount != 0, "==0");
        SafeERC20.safeTransferFrom(
            IERC20(REWARD_TOKEN),
            msg.sender,
            address(this),
            _amount
        );
        emit RewardsQueued(msg.sender, _amount);
        _amount = _amount + queuedRewards;

        if (block.timestamp >= periodFinish) {
            _notifyRewardAmount(_amount);
            queuedRewards = 0;
            return true;
        }
        uint256 elapsedSinceBeginingOfPeriod = block.timestamp -
            (periodFinish - duration);
        uint256 distributedSoFar = elapsedSinceBeginingOfPeriod * rewardRate;
        // we only restart a new period if _amount is 120% of distributedSoFar.

        if ((distributedSoFar * 12) / 10 < _amount) {
            _notifyRewardAmount(_amount);
            queuedRewards = 0;
        } else {
            queuedRewards = _amount;
        }
        return true;
    }

    function _notifyRewardAmount(
        uint256 _reward
    ) internal updateReward(address(0)) {
        historicalRewards = historicalRewards + _reward;

        if (block.timestamp >= periodFinish) {
            rewardRate = _reward / duration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            _reward = _reward + leftover;
            rewardRate = _reward / duration;
        }
        currentRewards = _reward;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + duration;
        emit RewardsAdded(
            currentRewards,
            lastUpdateTime,
            periodFinish,
            rewardRate,
            historicalRewards
        );
    }
}