//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/// @title Gracy Staking Contract
/// @notice This contract is used to stake GRACE tokens and earn rewards
/// @dev This contract is based on the ERC20 standard
contract GracyStaking is Ownable {
    using SafeCast for uint256;
    using SafeCast for int256;

    struct Pool {
        uint48 lastRewardedTimestamp;
        uint16 lastRewardsRangeIndex;
        uint96 stakedAmount;
        uint96 accumulatedRewardsPerShare;
        TimeRange[] timeRanges;
    }

    struct TimeRange {
        uint48 startTimestampDay;
        uint48 endTimestampDay;
        uint96 rewardsPerHour;
    }

    struct Position {
        uint256 stakedAmount;
        int256 rewardsDebt;
    }

    struct PublicPool {
        uint256 stakedAmount;
        TimeRange currentTimeRange;
    }

    struct DashboardStake {
        uint256 staked;
        uint256 unclaimed;
        uint256 rewardsDay;
    }

    mapping (address => Position) public addressPosition;

    IERC20 public immutable GRACY;
    uint256 private constant GRACY_PRECISION = 1e18;
    uint256 private MIN_STAKE_AMOUNT = 1 * GRACY_PRECISION;
    uint256 private constant SECONDS_PER_HOUR = 3600; 
    uint256 private constant SECONDS_PER_MINUTE = 60;

    Pool public pool;

    /** Custom Events **/
    event UpdatePool(
        uint256 lastRewardedBlock,
        uint256 stakedAmount,
        uint256 accumulatedRewardsPerShare
    );

    event Stake(
        address indexed user,
        uint64 timestamp,
        uint256 amount
    );

    event Withdraw(
        address indexed user,
        uint64 timestamp,
        uint256 amount
    );

    event ClaimRewards(
        address indexed user,
        uint64 timestamp,
        uint256 amount
    );

    event WithdrawAll(
        address indexed user,
        uint64 timestamp,
        uint256 amount,
        uint256 rewards
    );
    
    event ClaimReStake(
        address indexed user,
        uint64 timestamp,
        uint256 rewards
    );

    error StakeMoreThanOneGRACY();
    error StartMustEqualLastEnd();
    error ExceededWithdrawAmount();
    error MinAmountMoreThanZeroAmount();
    error TimeDiffMustBeMoreThan24Hours();

    constructor(address _GRACYTokenAddress) {
        GRACY = IERC20(_GRACYTokenAddress);
    }
    
    // Transaction Methods
    function stakeGRACY(uint256 _amount) private {
        if (_amount < MIN_STAKE_AMOUNT) revert StakeMoreThanOneGRACY();

        updatePool();
        Position storage position = addressPosition[msg.sender];
        _stake(position, _amount);

        GRACY.transferFrom(msg.sender, address(this), _amount);
        emit Stake(
            msg.sender,
            block.timestamp.toUint64(),
            _amount
        );
    }

    function stakeSelfGRACY(uint256 _amount) external {
        stakeGRACY(_amount);
    }

    function claimGRACY() private {
        updatePool();

        Position storage position = addressPosition[msg.sender];
        uint256 rewardsToBeClaimed = _claim(position, msg.sender);

        emit ClaimRewards(
            msg.sender,
            block.timestamp.toUint64(),
            rewardsToBeClaimed
        );
    }

    function claimSelfGRACY() external {
        claimGRACY();
    }

    function withdrawGRACY(uint256 _amount) private {
        updatePool();

        Position storage position = addressPosition[msg.sender];
        uint256 rewardsToBeClaimed;
        if (_amount == position.stakedAmount) rewardsToBeClaimed = _claim(position, msg.sender);

        _withdraw(position, _amount);

        GRACY.transfer(msg.sender, _amount);
        if (position.stakedAmount == 0) emit WithdrawAll(
            msg.sender,
            block.timestamp.toUint64(),
            _amount,
            rewardsToBeClaimed
        );
        else emit Withdraw(
            msg.sender,
            block.timestamp.toUint64(),
            _amount
        );
    }

    function withdrawSelfGRACY(uint256 _amount) external {
        withdrawGRACY(_amount);
    }

    function claimReStakeGRACY() private {
        updatePool();

        Position storage position = addressPosition[msg.sender];
        uint256 rewardsToBeClaimed = _claimReStake(position);

        emit ClaimReStake(
            msg.sender,
            block.timestamp.toUint64(),
            rewardsToBeClaimed
        );
    }

    function claimReStakeSelfGRACY() external {
        claimReStakeGRACY();
    }


    // Methods for time ranges
    function addTimeRange(
        uint256 _amount, 
        uint256 _startTimestampDay,
        uint256 _endTimestampDay
    ) external onlyOwner 
    {
        uint256 length = pool.timeRanges.length;
        if (length > 0) {
            if (_startTimestampDay != pool.timeRanges[length-1].endTimestampDay) revert StartMustEqualLastEnd();
        }
        if (_endTimestampDay - _startTimestampDay < (SECONDS_PER_HOUR * 24)) revert TimeDiffMustBeMoreThan24Hours();

        uint256 dayInSeconds = _endTimestampDay - _startTimestampDay;
        uint256 rewardsPerHour = _amount * SECONDS_PER_HOUR / dayInSeconds;

        TimeRange memory next = TimeRange(_startTimestampDay.toUint48(), _endTimestampDay.toUint48(), rewardsPerHour.toUint96());
        pool.timeRanges.push(next);
    }

    function removeLastTimeRange() external onlyOwner {
        pool.timeRanges.pop();
    }

    function getTimeRangeBy(uint256 _index) public view returns (TimeRange memory) {
        return pool.timeRanges[_index];
    }


    // Pool Methods
    function rewardsBy(uint256 _from, uint256 _to) public view returns (uint256, uint256) {

        uint256 currentIndex = pool.lastRewardsRangeIndex;
        if (_to < pool.timeRanges[0].startTimestampDay) return (0, currentIndex);
    
        while(_from > pool.timeRanges[currentIndex].endTimestampDay && _to > pool.timeRanges[currentIndex].endTimestampDay) {
            unchecked {
                ++currentIndex;
            }
        }

        uint256 rewards;
        TimeRange memory current;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 length = pool.timeRanges.length;
        for(uint256 i = currentIndex; i < length;) {
            current = pool.timeRanges[i];
            startTimestamp = _from <= current.startTimestampDay ? current.startTimestampDay : _from;
            endTimestamp = _to <= current.endTimestampDay ? _to : current.endTimestampDay;

            rewards = rewards + (endTimestamp - startTimestamp) * current.rewardsPerHour / SECONDS_PER_HOUR;

            if(_to <= endTimestamp) {
                return (rewards, i);
            }
            unchecked {
                ++i;
            }
        }
        return (rewards, length -1);
    }

    function updatePool() public {
        if (block.timestamp < pool.timeRanges[0].startTimestampDay) return;
        if (block.timestamp <= pool.lastRewardedTimestamp + SECONDS_PER_HOUR) return;
        

        uint48 lastTimestampDay = pool.timeRanges[pool.timeRanges.length -1].endTimestampDay;
        uint48 previousTimestamp = getPreviousTimestampHour().toUint48();

        if (pool.stakedAmount == 0) {
            pool.lastRewardedTimestamp = previousTimestamp > lastTimestampDay ? lastTimestampDay : previousTimestamp;
            return;
        }

        (uint256 rewards, uint256 index) = rewardsBy(pool.lastRewardedTimestamp, previousTimestamp);
        if (pool.lastRewardsRangeIndex != index) {
            pool.lastRewardsRangeIndex = index.toUint16();
        }
        if ((pool.accumulatedRewardsPerShare + (rewards * GRACY_PRECISION) / pool.stakedAmount) > type(uint96).max) return; //@audit-Louis

        pool.accumulatedRewardsPerShare = (pool.accumulatedRewardsPerShare + (rewards * GRACY_PRECISION) / pool.stakedAmount).toUint96();
        pool.lastRewardedTimestamp = previousTimestamp > lastTimestampDay ? lastTimestampDay : previousTimestamp;

        emit UpdatePool(
            pool.lastRewardedTimestamp,
            pool.stakedAmount,
            pool.accumulatedRewardsPerShare
        );
    }

    function setMinStakeAmount(uint256 _amount) external onlyOwner {
        if (_amount == 0) revert MinAmountMoreThanZeroAmount();
        MIN_STAKE_AMOUNT = _amount;
    }

    // Read Methods
    function getMinStakeAmount() external view returns (uint256) {
        return MIN_STAKE_AMOUNT;
    }

    function getCurrentTimeRangeIndex() private view returns (uint256) {
        uint256 current = pool.lastRewardsRangeIndex;

        if (block.timestamp < pool.timeRanges[current].startTimestampDay) return current;
        for (current = pool.lastRewardsRangeIndex; current < pool.timeRanges.length; ++current) {
            TimeRange memory currentTimeRange = pool.timeRanges[current];
            if (currentTimeRange.startTimestampDay <= block.timestamp && block.timestamp <= currentTimeRange.endTimestampDay) return current;
        }
        revert ('distribution ended');
    }

    function getPublicPool() external view returns (PublicPool memory) {
        uint256 current = getCurrentTimeRangeIndex();
        return PublicPool(pool.stakedAmount, pool.timeRanges[current]);
    }

    function stakedTotal(address _address) external view returns (uint256) {
        return addressPosition[_address].stakedAmount;
    }

    function stakedAPR() external view returns (uint256) {
        uint256 current = getCurrentTimeRangeIndex();
        TimeRange memory currentTimeRange = pool.timeRanges[current];
        // percent 100,m decimal 3
        return (uint256(currentTimeRange.rewardsPerHour) * 24 * 365 * 100 * 1000) / pool.stakedAmount;
    }

    function getGRACYStake(address _address) public view returns (DashboardStake memory) {
        uint256 staked = addressPosition[_address].stakedAmount;
        uint256 unclaimed = staked > 0 ? this.pendingRewards(_address) : 0;
        Position memory position = addressPosition[_address];
        TimeRange memory rewards = getTimeRangeBy(pool.lastRewardsRangeIndex);
        uint256 rewardsDay = staked > 0 ? _estimateDayRewards(position, rewards) : 0;
        return DashboardStake(staked, unclaimed, rewardsDay);
    }

    function _estimateDayRewards(Position memory position, TimeRange memory rewards) private view returns (uint256) {
        return (position.stakedAmount * uint256(rewards.rewardsPerHour) * 24) / uint256(pool.stakedAmount);
    }

    function getEstimateGRACYStake(uint256 _amount) public view returns (DashboardStake memory) {
        uint256 staked = _amount;
        uint256 unclaimed = _amount;
        Position memory position = Position(_amount, 0);
        TimeRange memory rewards = getTimeRangeBy(pool.lastRewardsRangeIndex);
        uint256 rewardsDay = _estimateDayRewardWithAmount(position, rewards);
        return DashboardStake(staked, unclaimed, rewardsDay);   
    }

    function _estimateDayRewardWithAmount(Position memory position, TimeRange memory rewards) private view returns (uint256) {
        return (position.stakedAmount * uint256(rewards.rewardsPerHour) * 24) / (uint256(pool.stakedAmount) + position.stakedAmount);
    }

    function pendingRewards(address _address) external view returns (uint256) {
        Position memory position = addressPosition[_address];

        (uint256 rewardsSinceLastCalculated,) = rewardsBy(pool.lastRewardedTimestamp, getPreviousTimestampHour());
        uint256 accumulatedRewardsPerShare = pool.accumulatedRewardsPerShare;

        if (block.timestamp > pool.lastRewardedTimestamp + SECONDS_PER_HOUR && pool.stakedAmount != 0) {
            accumulatedRewardsPerShare = accumulatedRewardsPerShare + rewardsSinceLastCalculated * GRACY_PRECISION / pool.stakedAmount;
        }
        return ((position.stakedAmount * accumulatedRewardsPerShare).toInt256() - position.rewardsDebt).toUint256() / GRACY_PRECISION;
    }

    // Convenience methods for timestamp 
    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function getPreviousTimestampHour() internal view returns (uint256) {
        return block.timestamp - (getMinute(block.timestamp) * 60 + getSecond(block.timestamp));
    }

    // Private Methods - shared logic
    function _stake(Position storage _position, uint256 _amount) private {
        _position.stakedAmount += _amount;
        pool.stakedAmount += _amount.toUint96();
        _position.rewardsDebt += (_amount * pool.accumulatedRewardsPerShare).toInt256();
    }

    function _claim(Position storage _position, address _recipient) private returns (uint256 rewardsToBeClaimed) {
        int256 accumulatedGRACYs = (_position.stakedAmount * uint256(pool.accumulatedRewardsPerShare)).toInt256();
        rewardsToBeClaimed = (accumulatedGRACYs - _position.rewardsDebt).toUint256() / GRACY_PRECISION;

        _position.rewardsDebt = accumulatedGRACYs;

        if (rewardsToBeClaimed != 0) {
            GRACY.transfer(_recipient, rewardsToBeClaimed);
        }
    }

    function _claimReStake(Position storage _position) private returns (uint256 rewardsToBeClaimed) {
        int256 accumulatedGRACYs = (_position.stakedAmount * uint256(pool.accumulatedRewardsPerShare)).toInt256();
        rewardsToBeClaimed = (accumulatedGRACYs - _position.rewardsDebt).toUint256() / GRACY_PRECISION;

        _position.rewardsDebt = accumulatedGRACYs;

        if (rewardsToBeClaimed != 0) {
            _stake(_position, rewardsToBeClaimed);
        }
    }

    function _withdraw(Position storage _position, uint256 _amount) private {
        if (_amount > _position.stakedAmount) revert ExceededWithdrawAmount();

        _position.stakedAmount -= _amount;
        pool.stakedAmount -= _amount.toUint96();
        _position.rewardsDebt -= (_amount * pool.accumulatedRewardsPerShare).toInt256();
    }
}