//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Inheritance
import "../interfaces/IStakingRewards.sol";
import "../interfaces/Pausable.sol";
import "../interfaces/IBurnableToken.sol";
import "../interfaces/RewardsDistributionRecipient.sol";
import "../interfaces/OnDemandToken.sol";
import "../interfaces/LockSettings.sol";
import "../interfaces/SwappableTokenV2.sol";

/// @author  umb.network
/// @notice Math is based on synthetix staking contract
///         Contract allows to stake and lock tokens. For rUMB tokens only locking option is available.
///         When locking user choose period and based on period multiplier is apply to the amount (boost).
///         If pool is set for rUMB1->rUMB2, (rUmbPool) then rUMB2 can be locked as well
contract StakingLockable is LockSettings, RewardsDistributionRecipient, ReentrancyGuard, Pausable {
    struct Times {
        uint32 periodFinish;
        uint32 rewardsDuration;
        uint32 lastUpdateTime;
        uint96 totalRewardsSupply;
    }

    struct Balance {
        // total supply of UMB = 500_000_000e18, it can be saved using 89bits, so we good with 96 and above
        // user UMB balance
        uint96 umbBalance;
        // amount locked + virtual balance generated using multiplier when locking
        uint96 lockedWithBonus;
        uint32 nextLockIndex;
        uint160 userRewardPerTokenPaid;
        uint96 rewards;
    }

    struct Supply {
        // staked + raw locked
        uint128 totalBalance;
        // virtual balance
        uint128 totalBonus;
    }

    struct Lock {
        uint8 tokenId;
        // total supply of UMB can be saved using 89bits, so we good with 96 and above
        uint120 amount;
        uint32 lockDate;
        uint32 unlockDate;
        uint32 multiplier;
        uint32 withdrawnAt;
    }

    uint8 public constant UMB_ID = 2 ** 0;
    uint8 public constant RUMB1_ID = 2 ** 1;
    uint8 public constant RUMB2_ID = 2 ** 2;

    uint256 public immutable maxEverTotalRewards;

    address public immutable umb;
    address public immutable rUmb1;
    /// @dev this is reward token but we also allow to lock it
    address public immutable rUmb2;

    uint256 public rewardRate = 0;
    uint256 public rewardPerTokenStored;

    Supply public totalSupply;

    Times public timeData;

    /// @dev user => Balance
    mapping(address => Balance) public balances;

    /// @dev user => lock ID => Lock
    mapping(address => mapping(uint256 => Lock)) public locks;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount, uint256 bonus);

    event LockedTokens(
        address indexed user,
        address indexed token,
        uint256 lockId,
        uint256 amount,
        uint256 period,
        uint256 multiplier
    );

    event UnlockedTokens(address indexed user, address indexed token, uint256 lockId, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event FarmingFinished();
    event Swap1to2(uint256 swapped);

    modifier updateReward(address _account) virtual {
        uint256 newRewardPerTokenStored = rewardPerToken();
        rewardPerTokenStored = newRewardPerTokenStored;
        timeData.lastUpdateTime = uint32(lastTimeRewardApplicable());

        if (_account != address(0)) {
            balances[_account].rewards = uint96(earned(_account));
            balances[_account].userRewardPerTokenPaid = uint160(newRewardPerTokenStored);
        }

        _;
    }

    constructor(
        address _owner,
        address _rewardsDistribution,
        address _umb,
        address _rUmb1,
        address _rUmb2
    ) Owned(_owner) {
        require(
            (
                MintableToken(_umb).maxAllowedTotalSupply() +
                MintableToken(_rUmb1).maxAllowedTotalSupply() +
                MintableToken(_rUmb2).maxAllowedTotalSupply()
            ) * MAX_MULTIPLIER / RATE_DECIMALS <= type(uint96).max,
            "staking overflow"
        );

        require(
            MintableToken(_rUmb2).maxAllowedTotalSupply() * MAX_MULTIPLIER / RATE_DECIMALS <= type(uint96).max,
            "rewards overflow"
        );

        require(OnDemandToken(_rUmb2).ON_DEMAND_TOKEN(), "rewardsToken must be OnDemandToken");

        umb = _umb;
        rUmb1 = _rUmb1;
        rUmb2 = _rUmb2;

        rewardsDistribution = _rewardsDistribution;
        timeData.rewardsDuration = 2592000; // 30 days
        maxEverTotalRewards = MintableToken(_rUmb2).maxAllowedTotalSupply();
    }

    function lockTokens(address _token, uint256 _amount, uint256 _period) external {
        if (_token == rUmb2 && !SwappableTokenV2(rUmb2).isSwapStarted()) {
            revert("locking rUMB2 not available yet");
        }

        _lockTokens(msg.sender, _token, _amount, _period);
    }

    function unlockTokens(uint256[] calldata _ids) external {
        _unlockTokensFor(msg.sender, _ids, msg.sender);
    }

    function restart(uint256 _rewardsDuration, uint256 _reward) external {
        setRewardsDuration(_rewardsDuration);
        notifyRewardAmount(_reward);
    }

    // when farming was started with 1y and 12tokens
    // and we want to finish after 4 months, we need to end up with situation
    // like we were starting with 4mo and 4 tokens.
    function finishFarming() external onlyOwner {
        Times memory t = timeData;
        require(block.timestamp < t.periodFinish, "can't stop if not started or already finished");

        if (totalSupply.totalBalance != 0) {
            uint32 remaining = uint32(t.periodFinish - block.timestamp);
            timeData.rewardsDuration = t.rewardsDuration - remaining;
        }

        timeData.periodFinish = uint32(block.timestamp);

        emit FarmingFinished();
    }

    /// @notice one of the reasons this method can throw is, when we swap for UMB and somebody stake rUMB1 after that.
    ///         In that case execution of `swapForUMB()` is required (anyone can execute this method) before proceeding.
    function exit() external {
        _withdraw(type(uint256).max, msg.sender, msg.sender);
        _getReward(msg.sender, msg.sender);
    }

    /// @notice one of the reasons this method can throw is, when we swap for UMB and somebody stake rUMB1 after that.
    ///         In that case execution of `swapForUMB()` is required (anyone can execute this method) before proceeding.
    function exitAndUnlock(uint256[] calldata _lockIds) external {
        _withdraw(type(uint256).max, msg.sender, msg.sender);
        _unlockTokensFor(msg.sender, _lockIds, msg.sender);
        _getReward(msg.sender, msg.sender);
    }

    function stake(uint256 _amount) external {
        _stake(umb, msg.sender, _amount, 0);
    }

    function getReward() external {
        _getReward(msg.sender, msg.sender);
    }

    function swap1to2() public {
        if (!SwappableTokenV2(rUmb2).isSwapStarted()) return;

        uint256 myBalance = IERC20(rUmb1).balanceOf(address(this));
        if (myBalance == 0) return;

        IBurnableToken(rUmb1).burn(myBalance);
        OnDemandToken(rUmb2).mint(address(this), myBalance);

        emit Swap1to2(myBalance);
    }

    /// @dev when notifying about amount, we don't have to mint or send any tokens, reward tokens will be mint on demand
    ///         this method is used to restart staking
    function notifyRewardAmount(
        uint256 _reward
    ) override public onlyRewardsDistribution updateReward(address(0)) {
        // this method can be executed on its own as well, I'm including here to not need to remember about it
        swap1to2();

        Times memory t = timeData;
        uint256 newRewardRate;

        if (block.timestamp >= t.periodFinish) {
            newRewardRate = _reward / t.rewardsDuration;
        } else {
            uint256 remaining = t.periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            newRewardRate = (_reward + leftover) / t.rewardsDuration;
        }

        require(newRewardRate != 0, "invalid rewardRate");

        rewardRate = newRewardRate;

        // always increasing by _reward even if notification is in a middle of period
        // because leftover is included
        uint256 totalRewardsSupply = timeData.totalRewardsSupply + _reward;
        require(totalRewardsSupply <= maxEverTotalRewards, "rewards overflow");

        timeData.totalRewardsSupply = uint96(totalRewardsSupply);
        timeData.lastUpdateTime = uint32(block.timestamp);
        timeData.periodFinish = uint32(block.timestamp + t.rewardsDuration);

        emit RewardAdded(_reward);
    }

    function setRewardsDuration(uint256 _rewardsDuration) public onlyRewardsDistribution {
        require(_rewardsDuration != 0, "empty _rewardsDuration");

        require(
            block.timestamp > timeData.periodFinish,
            "Previous period must be complete before changing the duration"
        );

        timeData.rewardsDuration = uint32(_rewardsDuration);
        emit RewardsDurationUpdated(_rewardsDuration);
    }

    /// @notice one of the reasons this method can throw is, when we swap for UMB and somebody stake rUMB1 after that.
    ///         In that case execution of `swapForUMB()` is required (anyone can execute this method) before proceeding.
    function withdraw(uint256 _amount) public {
        _withdraw(_amount, msg.sender, msg.sender);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        uint256 periodFinish = timeData.periodFinish;
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256 perToken) {
        Supply memory s = totalSupply;

        if (s.totalBalance == 0) {
            return rewardPerTokenStored;
        }

        perToken = rewardPerTokenStored + (
            (lastTimeRewardApplicable() - timeData.lastUpdateTime) * rewardRate * 1e18 / (s.totalBalance + s.totalBonus)
        );
    }

    function earned(address _account) virtual public view returns (uint256) {
        Balance memory b = balances[_account];
        uint256 totalBalance = b.umbBalance + b.lockedWithBonus;
        return (totalBalance * (rewardPerToken() - b.userRewardPerTokenPaid) / 1e18) + b.rewards;
    }

    function calculateBonus(uint256 _amount, uint256 _multiplier) public pure returns (uint256 bonus) {
        if (_multiplier <= RATE_DECIMALS) return 0;

        bonus = _amount * _multiplier / RATE_DECIMALS - _amount;
    }

    /// @param _token token that we allow to stake, validator check should be do outside
    /// @param _user token owner
    /// @param _amount amount
    /// @param _bonus if bonus is 0, means we are staking, bonus > 0 means this is locking
    function _stake(address _token, address _user, uint256 _amount, uint256 _bonus)
        internal
        nonReentrant
        notPaused
        updateReward(_user)
    {
        uint256 amountWithBonus = _amount + _bonus;

        require(timeData.periodFinish > block.timestamp, "Stake period not started yet");
        require(amountWithBonus != 0, "Cannot stake 0");

        // TODO check if we ever need to separate balance and bonuses
        totalSupply.totalBalance += uint96(_amount);
        totalSupply.totalBonus += uint128(_bonus);

        if (_bonus == 0) {
            balances[_user].umbBalance += uint96(_amount);
        } else {
            balances[_user].lockedWithBonus += uint96(amountWithBonus);
        }

        // not using safe transfer, because we working with trusted tokens
        require(IERC20(_token).transferFrom(_user, address(this), _amount), "token transfer failed");

        emit Staked(_user, _amount, _bonus);
    }

    function _lockTokens(address _user, address _token, uint256 _amount, uint256 _period) internal notPaused {
        uint256 multiplier = multipliers[_token][_period];
        require(multiplier != 0, "invalid period or not supported token");

        uint256 stakeBonus = calculateBonus(_amount, multiplier);

        _stake(_token, _user, _amount, stakeBonus);
        _addLock(_user, _token, _amount, _period, multiplier);
    }

    function _addLock(address _user, address _token, uint256 _amount, uint256 _period, uint256 _multiplier) internal {
        uint256 newIndex = balances[_user].nextLockIndex;
        if (newIndex == type(uint32).max) revert("nextLockIndex overflow");

        balances[_user].nextLockIndex = uint32(newIndex + 1);

        Lock storage lock = locks[_user][newIndex];

        lock.amount = uint120(_amount);
        lock.multiplier = uint32(_multiplier);
        lock.lockDate = uint32(block.timestamp);
        lock.unlockDate = uint32(block.timestamp + _period);

        if (_token == rUmb2) lock.tokenId = RUMB2_ID;
        else if (_token == rUmb1) lock.tokenId = RUMB1_ID;
        else lock.tokenId = UMB_ID;

        emit LockedTokens(_user, _token, newIndex, _amount, _period, _multiplier);
    }

    // solhint-disable-next-line code-complexity
    function _unlockTokensFor(address _user, uint256[] calldata _indexes, address _recipient)
        internal
        returns (address token, uint256 totalRawAmount)
    {
        uint256 totalBonus;
        uint256 acceptedTokenId;
        bool isSwapStarted = SwappableTokenV2(rUmb2).isSwapStarted();

        for (uint256 i; i < _indexes.length; i++) {
            (uint256 amount, uint256 bonus, uint256 tokenId) = _markAsUnlocked(_user, _indexes[i]);
            if (amount == 0) continue;

            if (acceptedTokenId == 0) {
                acceptedTokenId = tokenId;
                token = _idToToken(tokenId);

                // if token is already rUmb2 means swap started already

                if (token == rUmb1 && isSwapStarted) {
                    token = rUmb2;
                    acceptedTokenId = RUMB2_ID;
                }
            } else if (acceptedTokenId != tokenId) {
                if (acceptedTokenId == RUMB2_ID && tokenId == RUMB1_ID) {
                    // this lock is for rUMB1 but swap 1->2 is started so we unlock as rUMB2
                } else revert("batch unlock possible only for the same tokens");
            }

            emit UnlockedTokens(_user, token, _indexes[i], amount);

            totalRawAmount += amount;
            totalBonus += bonus;
        }

        if (totalRawAmount == 0) revert("nothing to unlock");
        _withdrawUnlockedTokens(_user, token, _recipient, totalRawAmount, totalBonus);
    }

    function _withdrawUnlockedTokens(
        address _user,
        address _token,
        address _recipient,
        uint256 _totalRawAmount,
        uint256 _totalBonus
    )
        internal
    {
        uint256 amountWithBonus = _totalRawAmount + _totalBonus;

        balances[_user].lockedWithBonus -= uint96(amountWithBonus);

        totalSupply.totalBalance -= uint96(_totalRawAmount);
        totalSupply.totalBonus -= uint128(_totalBonus);

        // note: there is one case when this transfer can fail:
        // when swap is started by we did not swap rUmb1 -> rUmb2,
        // in that case we have to execute `swap1to2`
        // to save gas I'm not including it here, because it is unlikely case
        require(IERC20(_token).transfer(_recipient, _totalRawAmount), "withdraw unlocking failed");
    }

    function _markAsUnlocked(address _user, uint256 _index)
        internal
        returns (uint256 amount, uint256 bonus, uint256 tokenId)
    {
        // TODO will storage save gas?
        Lock memory lock = locks[_user][_index];

        if (lock.withdrawnAt != 0) revert("DepositAlreadyWithdrawn");
        if (block.timestamp < lock.unlockDate) revert("DepositLocked");

        if (lock.amount == 0) return (0, 0, 0);

        locks[_user][_index].withdrawnAt = uint32(block.timestamp);

        return (lock.amount, calculateBonus(lock.amount, lock.multiplier), lock.tokenId);
    }

    /// @param _amount tokens to withdraw
    /// @param _user address
    /// @param _recipient address, where to send tokens, if we migrating token address can be zero
    function _withdraw(uint256 _amount, address _user, address _recipient) internal nonReentrant updateReward(_user) {
        Balance memory balance = balances[_user];

        if (_amount == type(uint256).max) _amount = balance.umbBalance;
        else require(balance.umbBalance >= _amount, "withdraw amount to high");

        if (_amount == 0) return;

        // not using safe math, because there is no way to overflow because of above check
        totalSupply.totalBalance -= uint120(_amount);
        balances[_user].umbBalance = uint96(balance.umbBalance - _amount);

        // not using safe transfer, because we working with trusted tokens
        require(IERC20(umb).transfer(_recipient, _amount), "token transfer failed");

        emit Withdrawn(_user, _amount);
    }

    /// @param _user address
    /// @param _recipient address, where to send reward
    function _getReward(address _user, address _recipient)
        internal
        nonReentrant
        updateReward(_user)
        returns (uint256 reward)
    {
        reward = balances[_user].rewards;

        if (reward != 0) {
            balances[_user].rewards = 0;
            OnDemandToken(address(rUmb2)).mint(_recipient, reward);
            emit RewardPaid(_user, reward);
        }
    }

    function _idToToken(uint256 _tokenId) internal view returns (address token) {
        if (_tokenId == RUMB2_ID) token = rUmb2;
        else if (_tokenId == RUMB1_ID) token = rUmb1;
        else if (_tokenId == UMB_ID) token = umb;
        else return address(0);
    }
}