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

    function getBlockNumber() internal virtual view returns (uint256) {
        return block.number;
    }

    function getTimestamp() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    uint256 public constant SECONDS_PER_BLOCK = 15;
    uint256 public constant BLOCKS_PER_DAY = 1 days / SECONDS_PER_BLOCK;
    uint256 public constant MAX_DISTRIBUTION_DURATION = 90 * BLOCKS_PER_DAY;

    mapping(address => uint256) public rewardUnlockingTime;

    uint256 private _lastUpdateBlockNumber;
    uint256 private _perBlockReward;
    uint256 private _blockNumberOfDistributionEnding;
    uint256 private _initialStrategyStartBlockNumber;
    AttoDecimal private _initialStrategyRewardPerToken;
    AttoDecimal private _rewardPerToken;
    mapping(address => PaidRate) private _paidRates;

    function getRewardUnlockingTime() public virtual pure returns (uint256) {
        return 8 days;
    }

    function lastUpdateBlockNumber() public view returns (uint256) {
        return _lastUpdateBlockNumber;
    }

    function perBlockReward() public view returns (uint256) {
        return _perBlockReward;
    }

    function blockNumberOfDistributionEnding() public view returns (uint256) {
        return _blockNumberOfDistributionEnding;
    }

    function initialStrategyStartBlockNumber() public view returns (uint256) {
        return _initialStrategyStartBlockNumber;
    }

    function getRewardPerToken() internal view returns (AttoDecimal memory) {
        uint256 lastRewardBlockNumber = Math.min(getBlockNumber(), _blockNumberOfDistributionEnding.add(1));
        if (lastRewardBlockNumber <= _lastUpdateBlockNumber) return _rewardPerToken;
        return _getRewardPerToken(lastRewardBlockNumber);
    }

    function _getRewardPerToken(uint256 forBlockNumber) internal view returns (AttoDecimal memory) {
        if (_initialStrategyStartBlockNumber >= forBlockNumber) return AttoDecimal(0);
        uint256 totalSupply_ = totalSupply();
        if (totalSupply_ == 0) return AttoDecimalLib.convert(0);
        uint256 totalReward = forBlockNumber
            .sub(Math.max(_lastUpdateBlockNumber, _initialStrategyStartBlockNumber))
            .mul(_perBlockReward);
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
        uint256 currentBlockNumber = getBlockNumber();
        PaidRate memory userRate = _paidRates[account];
        if (currentBlockNumber <= _initialStrategyStartBlockNumber || !userRate.active) return 0;
        AttoDecimal memory rewardPerToken_ = getRewardPerToken();
        AttoDecimal memory initRewardPerToken = _initialStrategyRewardPerToken.mantissa > 0
            ? _initialStrategyRewardPerToken
            : _getRewardPerToken(_initialStrategyStartBlockNumber.add(1));
        AttoDecimal memory rate = userRate.rate.lte((initRewardPerToken)) ? initRewardPerToken : userRate.rate;
        uint256 balance = balanceOf(account);
        if (balance == 0) return 0;
        if (rewardPerToken_.lte(rate)) return 0;
        AttoDecimal memory ratesDiff = rewardPerToken_.sub(rate);
        return ratesDiff.mul(balance).floor();
    }

    event RewardStrategyChanged(uint256 perBlockReward, uint256 duration);
    event InitialRewardStrategySetted(uint256 startBlockNumber, uint256 perBlockReward, uint256 duration);
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
        uint256 startBlockNumber,
        uint256 perBlockReward_,
        uint256 duration
    ) public onlyOwner returns (bool succeed) {
        uint256 currentBlockNumber = getBlockNumber();
        require(_initialStrategyStartBlockNumber == 0, "Initial reward strategy already setted");
        require(currentBlockNumber < startBlockNumber, "Initial reward strategy start block number less than current");
        _initialStrategyStartBlockNumber = startBlockNumber;
        _setRewardStrategy(currentBlockNumber, startBlockNumber, perBlockReward_, duration);
        emit InitialRewardStrategySetted(startBlockNumber, perBlockReward_, duration);
        return true;
    }

    function setRewardStrategy(uint256 perBlockReward_, uint256 duration) public onlyOwner returns (bool succeed) {
        uint256 currentBlockNumber = getBlockNumber();
        require(_initialStrategyStartBlockNumber > 0, "Set initial reward strategy first");
        require(currentBlockNumber >= _initialStrategyStartBlockNumber, "Wait for initial reward strategy start");
        _setRewardStrategy(currentBlockNumber, currentBlockNumber, perBlockReward_, duration);
        emit RewardStrategyChanged(perBlockReward_, duration);
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

    function _lockRatesForBlock(uint256 blockNumber) private {
        _rewardPerToken = _getRewardPerToken(blockNumber);
        _lastUpdateBlockNumber = blockNumber;
    }

    function _lockRates(uint256 blockNumber) private {
        uint256 totalSupply_ = totalSupply();
        if (_initialStrategyStartBlockNumber <= blockNumber && _initialStrategyRewardPerToken.mantissa == 0 && totalSupply_ > 0)
            _initialStrategyRewardPerToken = AttoDecimalLib.div(_perBlockReward, totalSupply_);
        if (_perBlockReward > 0 && blockNumber >= _blockNumberOfDistributionEnding) {
            _lockRatesForBlock(_blockNumberOfDistributionEnding);
            _perBlockReward = 0;
        }
        _lockRatesForBlock(blockNumber);
    }

    function _lockRewards(address account) private {
        uint256 currentBlockNumber = getBlockNumber();
        _lockRates(currentBlockNumber);
        uint256 earned = earnedOf(account);
        if (earned > 0) _addReward(account, earned);
        _paidRates[account].rate = _rewardPerToken;
        _paidRates[account].active = true;
    }

    function _setRewardStrategy(
        uint256 currentBlockNumber,
        uint256 startBlockNumber,
        uint256 perBlockReward_,
        uint256 duration
    ) private {
        require(duration > 0, "Duration is zero");
        require(duration <= MAX_DISTRIBUTION_DURATION, "Distribution duration too long");
        _lockRates(currentBlockNumber);
        uint256 nextDistributionRequiredPool = perBlockReward_.mul(duration);
        uint256 notDistributedReward = _blockNumberOfDistributionEnding <= currentBlockNumber
            ? 0
            : _blockNumberOfDistributionEnding.sub(currentBlockNumber).mul(_perBlockReward);
        if (nextDistributionRequiredPool > notDistributedReward) {
            _increaseRewardPool(owner, nextDistributionRequiredPool.sub(notDistributedReward));
        } else if (nextDistributionRequiredPool < notDistributedReward) {
            _reduceRewardPool(owner, notDistributedReward.sub(nextDistributionRequiredPool));
        }
        _perBlockReward = perBlockReward_;
        _blockNumberOfDistributionEnding = startBlockNumber.add(duration);
    }

    modifier onlyPositiveAmount(uint256 amount) {
        require(amount > 0, "Amount is not positive");
        _;
    }
}