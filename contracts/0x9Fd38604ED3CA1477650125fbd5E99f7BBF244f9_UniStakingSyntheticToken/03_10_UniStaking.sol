// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "openzeppelin-solidity/contracts/math/Math.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./AttoDecimal.sol";
import "./TwoStageOwnable.sol";
import "./UniStakingTokensStorage.sol";

contract UniStaking is TwoStageOwnable, UniStakingTokensStorage {
    using SafeMath for uint256;
    using AttoDecimalLib for AttoDecimal;

    struct PaidRate {
        AttoDecimal rate;
        bool active;
    }

    function getTimestamp() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    uint256 public constant MAX_DISTRIBUTION_DURATION = 90 days;

    mapping(address => uint256) public rewardUnlockingTime;

    uint256 private _lastUpdatedAt;
    uint256 private _perSecondReward;
    uint256 private _distributionEndsAt;
    uint256 private _initialStrategyStartsAt;
    AttoDecimal private _initialStrategyRewardPerToken;
    AttoDecimal private _rewardPerToken;
    mapping(address => PaidRate) private _paidRates;

    function getRewardUnlockingTime() public virtual pure returns (uint256) {
        return 8 days;
    }

    function lastUpdatedAt() public view returns (uint256) {
        return _lastUpdatedAt;
    }

    function perSecondReward() public view returns (uint256) {
        return _perSecondReward;
    }

    function distributionEndsAt() public view returns (uint256) {
        return _distributionEndsAt;
    }

    function initialStrategyStartsAt() public view returns (uint256) {
        return _initialStrategyStartsAt;
    }

    function getRewardPerToken() internal view returns (AttoDecimal memory) {
        uint256 lastRewardLockedAt = Math.min(getTimestamp(), _distributionEndsAt.add(1));
        if (lastRewardLockedAt <= _lastUpdatedAt) return _rewardPerToken;
        return _getRewardPerToken(lastRewardLockedAt);
    }

    function _getRewardPerToken(uint256 forTimestamp) internal view returns (AttoDecimal memory) {
        if (_initialStrategyStartsAt >= forTimestamp) return AttoDecimal(0);
        uint256 totalSupply_ = totalSupply();
        if (totalSupply_ == 0) return AttoDecimalLib.convert(0);
        uint256 totalReward = forTimestamp
            .sub(Math.max(_lastUpdatedAt, _initialStrategyStartsAt))
            .mul(_perSecondReward);
        AttoDecimal memory newRewardPerToken = AttoDecimalLib.div(totalReward, totalSupply_);
        return _rewardPerToken.add(newRewardPerToken);
    }

    function rewardPerToken()
        external
        view
        returns (
            uint256 mantissa,
            uint256 base,
            uint256 exponentiation
        )
    {
        return (getRewardPerToken().mantissa, AttoDecimalLib.BASE, AttoDecimalLib.EXPONENTIATION);
    }

    function paidRateOf(address account)
        external
        view
        returns (
            uint256 mantissa,
            uint256 base,
            uint256 exponentiation
        )
    {
        return (_paidRates[account].rate.mantissa, AttoDecimalLib.BASE, AttoDecimalLib.EXPONENTIATION);
    }

    function earnedOf(address account) public view returns (uint256) {
        PaidRate memory userRate = _paidRates[account];
        if (getTimestamp() <= _initialStrategyStartsAt || !userRate.active) return 0;
        AttoDecimal memory rewardPerToken_ = getRewardPerToken();
        AttoDecimal memory initRewardPerToken = _initialStrategyRewardPerToken.mantissa > 0
            ? _initialStrategyRewardPerToken
            : _getRewardPerToken(_initialStrategyStartsAt.add(1));
        AttoDecimal memory rate = userRate.rate.lte((initRewardPerToken)) ? initRewardPerToken : userRate.rate;
        uint256 balance = balanceOf(account);
        if (balance == 0) return 0;
        if (rewardPerToken_.lte(rate)) return 0;
        AttoDecimal memory ratesDiff = rewardPerToken_.sub(rate);
        return ratesDiff.mul(balance).floor();
    }

    event RewardStrategyChanged(uint256 perSecondReward, uint256 duration);
    event InitialRewardStrategySetted(uint256 startsAt, uint256 perSecondReward, uint256 duration);
    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);
    event Claimed(address indexed account, uint256 amount, uint256 rewardUnlockingTime);
    event Withdrawed(address indexed account, uint256 amount);

    constructor(
        IERC20 rewardsToken_,
        IERC20 stakingToken_,
        address owner_
    ) public TwoStageOwnable(owner_) UniStakingTokensStorage(rewardsToken_, stakingToken_) {
    }

    function stake(uint256 amount) public onlyPositiveAmount(amount) {
        address sender = msg.sender;
        _lockRewards(sender);
        _stake(sender, amount);
        emit Staked(sender, amount);
    }

    function unstake(uint256 amount) public onlyPositiveAmount(amount) {
        address sender = msg.sender;
        require(amount <= balanceOf(sender), "Unstaking amount exceeds staked balance");
        _lockRewards(sender);
        _unstake(sender, amount);
        emit Unstaked(sender, amount);
    }

    function claim(uint256 amount) public onlyPositiveAmount(amount) {
        address sender = msg.sender;
        _lockRewards(sender);
        require(amount <= rewardOf(sender), "Claiming amount exceeds received rewards");
        uint256 rewardUnlockingTime_ = getTimestamp().add(getRewardUnlockingTime());
        rewardUnlockingTime[sender] = rewardUnlockingTime_;
        _claim(sender, amount);
        emit Claimed(sender, amount, rewardUnlockingTime_);
    }

    function withdraw(uint256 amount) public onlyPositiveAmount(amount) {
        address sender = msg.sender;
        require(getTimestamp() >= rewardUnlockingTime[sender], "Reward not unlocked yet");
        require(amount <= claimedOf(sender), "Withdrawing amount exceeds claimed balance");
        _withdraw(sender, amount);
        emit Withdrawed(sender, amount);
    }

    function setInitialRewardStrategy(
        uint256 startsAt,
        uint256 perSecondReward_,
        uint256 duration
    ) public onlyOwner returns (bool succeed) {
        uint256 currentTimestamp = getTimestamp();
        require(_initialStrategyStartsAt == 0, "Initial reward strategy already setted");
        require(currentTimestamp < startsAt, "Initial reward strategy starting timestamp less than current");
        _initialStrategyStartsAt = startsAt;
        _setRewardStrategy(currentTimestamp, startsAt, perSecondReward_, duration);
        emit InitialRewardStrategySetted(startsAt, perSecondReward_, duration);
        return true;
    }

    function setRewardStrategy(uint256 perSecondReward_, uint256 duration) public onlyOwner returns (bool succeed) {
        uint256 currentTimestamp = getTimestamp();
        require(_initialStrategyStartsAt > 0, "Set initial reward strategy first");
        require(currentTimestamp >= _initialStrategyStartsAt, "Wait for initial reward strategy start");
        _setRewardStrategy(currentTimestamp, currentTimestamp, perSecondReward_, duration);
        emit RewardStrategyChanged(perSecondReward_, duration);
        return true;
    }

    function lockRewards() public {
        _lockRewards(msg.sender);
    }

    function _moveStake(
        address from,
        address to,
        uint256 amount
    ) internal {
        _lockRewards(from);
        _lockRewards(to);
        _transferBalance(from, to, amount);
    }

    function _lastRatesLockedAt(uint256 timestamp) private {
        _rewardPerToken = _getRewardPerToken(timestamp);
        _lastUpdatedAt = timestamp;
    }

    function _lockRates(uint256 timestamp) private {
        uint256 totalSupply_ = totalSupply();
        if (_initialStrategyStartsAt <= timestamp && _initialStrategyRewardPerToken.mantissa == 0 && totalSupply_ > 0)
            _initialStrategyRewardPerToken = AttoDecimalLib.div(_perSecondReward, totalSupply_);
        if (_perSecondReward > 0 && timestamp >= _distributionEndsAt) {
            _lastRatesLockedAt(_distributionEndsAt);
            _perSecondReward = 0;
        }
        _lastRatesLockedAt(timestamp);
    }

    function _lockRewards(address account) private {
        uint256 currentTimestamp = getTimestamp();
        _lockRates(currentTimestamp);
        uint256 earned = earnedOf(account);
        if (earned > 0) _addReward(account, earned);
        _paidRates[account].rate = _rewardPerToken;
        _paidRates[account].active = true;
    }

    function _setRewardStrategy(
        uint256 currentTimestamp,
        uint256 startsAt,
        uint256 perSecondReward_,
        uint256 duration
    ) private {
        require(duration > 0, "Duration is zero");
        require(duration <= MAX_DISTRIBUTION_DURATION, "Distribution duration too long");
        _lockRates(currentTimestamp);
        uint256 nextDistributionRequiredPool = perSecondReward_.mul(duration);
        uint256 notDistributedReward = _distributionEndsAt <= currentTimestamp
            ? 0
            : _distributionEndsAt.sub(currentTimestamp).mul(_perSecondReward);
        if (nextDistributionRequiredPool > notDistributedReward) {
            _increaseRewardPool(owner, nextDistributionRequiredPool.sub(notDistributedReward));
        } else if (nextDistributionRequiredPool < notDistributedReward) {
            _reduceRewardPool(owner, notDistributedReward.sub(nextDistributionRequiredPool));
        }
        _perSecondReward = perSecondReward_;
        _distributionEndsAt = startsAt.add(duration);
    }

    modifier onlyPositiveAmount(uint256 amount) {
        require(amount > 0, "Amount is not positive");
        _;
    }
}