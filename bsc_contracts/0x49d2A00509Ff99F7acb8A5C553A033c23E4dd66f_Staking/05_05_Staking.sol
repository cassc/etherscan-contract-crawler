pragma solidity ^0.8.17;

import './interfaces/IStaking.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/Pausable.sol';


contract Staking is IStaking, Pausable {
    uint256 constant internal MAX_USER_STAKES = 100;
    address public owner;
    IERC20 public token;
    IERC20 public rewardToken;
    uint256 public override totalStaked;
    mapping(address => uint256) public totalUserStaked;
    uint256 public rewardDeadline;
    uint256 public maximumStakingRewards;

    mapping(address => Stake[]) private stakes;
    mapping(uint256 => uint256) public apy;
    mapping(uint256 => uint256) public tokensLocked;
    mapping(uint256 => uint256) public tokensLimits;
    uint256[] public lockLengths;
    mapping(uint256 => uint256) internal lastEarnedCalculation;
    mapping(uint256 => uint256) internal earnedPerLockTime;

    constructor(
        address _tokenAddress,
        address _rewardAddress,
        uint256[] memory _lockLengths,
        uint256[] memory _percentages,
        uint256[] memory _tokensLimits,
        uint256 _maximumStakingRewards
    ) {
        owner = msg.sender;
        if (_tokenAddress == address(0) || _rewardAddress == address(0)) {
            revert AddressZero();
        }
        token = IERC20(_tokenAddress);
        rewardToken = IERC20(_rewardAddress);
        maximumStakingRewards = _maximumStakingRewards;
        for (uint256 i = 0; i < _lockLengths.length; ) {
            apy[_lockLengths[i]] = _percentages[i];
            lockLengths.push(_lockLengths[i]);
            tokensLimits[_lockLengths[i]] = _tokensLimits[i];
            lastEarnedCalculation[_lockLengths[i]] = block.timestamp;

            unchecked {
                ++i;
            }
        }
        rewardDeadline = block.timestamp + (60 * 60 * 24 * 365); // 1 year from start

        _pause();
    }

    modifier onlyOwnerAccess() {
        if (msg.sender != owner) {
            revert OnlyOwnerAccess();
        }
        _;
    }

    modifier recalculateEarnings() {
        uint256 alreadyEarned = 0;
        uint256 rewardEnd = _getRewardEnd();
        for (uint256 i = 0; i < lockLengths.length; i++) {
            uint256 timePassed = rewardEnd - lastEarnedCalculation[lockLengths[i]];
            if (timePassed == 0) {
                alreadyEarned += earnedPerLockTime[lockLengths[i]];
                continue;
            }
            uint256 newReward = _calculateRewardIncrease(tokensLocked[lockLengths[i]], apy[lockLengths[i]], timePassed);
            lastEarnedCalculation[lockLengths[i]] = rewardEnd;
            earnedPerLockTime[lockLengths[i]] += newReward;

            alreadyEarned += earnedPerLockTime[lockLengths[i]];
        }

        emit TotalRewardsEarned(alreadyEarned);

        if (maximumStakingRewards <= alreadyEarned && rewardDeadline > block.timestamp) {
            rewardDeadline = block.timestamp;
        }
        _;
    }

    function updateTotalEarningsState() external recalculateEarnings {

    }

    function stakeTokens(uint256 _amount, uint256 _lockTime) public recalculateEarnings whenNotPaused {
        if (apy[_lockTime] == 0) {
            revert InvalidLockTime();
        }

        if (tokensLimits[_lockTime] != 0) {
            if (tokensLocked[_lockTime] + _amount > tokensLimits[_lockTime]) {
                revert TokensLimitReached();
            }
        }

        Stake memory newStake = Stake(_amount, 0, _lockTime, block.timestamp, 0);
        stakes[msg.sender].push(newStake);
        if (stakes[msg.sender].length > MAX_USER_STAKES) {
            revert TooMuchStakes();
        }

        totalStaked += _amount;
        totalUserStaked[msg.sender] += _amount;
        tokensLocked[_lockTime] += _amount;
        if (!token.transferFrom(msg.sender, address(this), _amount)) {
            revert TransferFailed();
        }
        emit Staked(msg.sender, _amount, _lockTime);
    }

    function _calculateRewardIncrease(uint256 _stakeAmount, uint256 _apy, uint256 _timePassed) internal pure returns(uint256) {
        return ((_stakeAmount * _apy * _timePassed) / (100 * 365 days));
    }

    function _calculateReward(Stake storage _stake) internal view returns (uint256) {
        if (rewardDeadline < _stake.startTime) {
            return 0;
        }
        uint256 timePassed = 0;
        if (_stake.claimedTime > 0) {
            timePassed = _min(_stake.claimedTime, rewardDeadline) - _stake.startTime;
        } else {
            timePassed = _getRewardEnd() - _stake.startTime;
        }

        return _calculateRewardIncrease(_stake.amount, apy[_stake.lockTime], timePassed) - _stake.claimedReward;
    }

    function calculateReward(address _user, uint256 _index) public view returns (uint256) {
        return _calculateReward(_getStake(_user, _index));
    }

    function claimReward(uint256 _index) public recalculateEarnings {
        Stake storage stake = _getStake(msg.sender, _index);
        if (block.timestamp <= stake.startTime + stake.lockTime) {
            revert LocktimeNotPassed();
        }
        uint256 reward = calculateReward(msg.sender, _index);
        if (reward == 0) {
            revert AlreadyClaimed();
        }
        stake.claimedReward += reward;
        if (address(token) == address(rewardToken)) {
            if (token.balanceOf(address(this)) < totalStaked + reward) {
                revert BalanceNotEnough();
            }
            if (!token.transfer(msg.sender, reward)) {
                revert TransferFailed();
            }
        } else {
            if (!rewardToken.transfer(msg.sender, reward)) {
                revert TransferFailed();
            }
        }

        emit ClaimedReward(msg.sender, reward);
    }

    function claimStakedAmount(uint256 _index) public recalculateEarnings {
        Stake storage stake = _getStake(msg.sender, _index);
        _checkStake(stake);
        totalStaked -= stake.amount;
        totalUserStaked[msg.sender] -= stake.amount;
        stake.claimedTime = block.timestamp;
        if (!token.transfer(msg.sender, stake.amount)) {
            revert TransferFailed();
        }
        emit ClaimedStakedAmount(msg.sender, stake.amount);
    }

    function claim(uint256 _index) public recalculateEarnings {
        Stake storage stake = _getStake(msg.sender, _index);
        _checkStake(stake);
        uint256 reward = calculateReward(msg.sender, _index);
        stake.claimedTime = block.timestamp;
        stake.claimedReward += reward;
        totalStaked -= stake.amount;
        totalUserStaked[msg.sender] -= stake.amount;
        if (address(token) == address(rewardToken)) {
            if (token.balanceOf(address(this)) < totalStaked + reward + stake.amount) {
                revert BalanceNotEnough();
            }
            if (!token.transfer(msg.sender, stake.amount + reward)) {
                revert TransferFailed();
            }
        } else {
            if (!token.transfer(msg.sender, stake.amount)) {
                revert TransferFailed();
            }
            if (!rewardToken.transfer(msg.sender, reward)) {
                revert TransferFailed();
            }
        }

        emit Claimed(msg.sender, stake.amount, reward);
    }

    function getStakes(address _user) public view override returns (Stake[] memory) {
        return stakes[_user];
    }

    function getStakesLen(address _user) external view override returns(uint256) {
        return stakes[_user].length;
    }

    function getUserSummary(address _user) external view override returns(UserData memory) {
        StakeView[] memory _stakes = new StakeView[](stakes[_user].length);
        uint256 _rewardToClaim = 0;
        for(uint256 i = 0; i < stakes[_user].length; ) {
            Stake storage s = stakes[_user][i];

            uint256 unlockTime = s.lockTime + s.startTime;
            uint256 _reward = _calculateReward(s);
            _rewardToClaim += _reward;

            _stakes[i] = StakeView({
                amount: s.amount,
                reward: _reward,
                timeLeft: block.timestamp < unlockTime ? unlockTime - block.timestamp : 0,
                stakeClaimed: s.claimedTime != 0,
                contractAddr: address(this),
                stakingIndex: i
            });

            unchecked {
                ++i;
            }
        }

        return UserData({
            stakes: _stakes,
            totalStaked: totalUserStaked[_user],
            rewardToClaim: _rewardToClaim
        });
    }

    function setOwner(address _owner) public onlyOwnerAccess {
        if (_owner == address(0)) {
            revert AddressZero();
        }
        address oldOwner = owner;
        owner = _owner;
        emit OwnerChanged(oldOwner, owner);
    }

    function _checkStake(Stake memory stake) internal view {
        if (stake.claimedTime > 0) {
            revert AlreadyClaimed();
        }
        if (block.timestamp <= stake.startTime + stake.lockTime) {
            revert LocktimeNotPassed();
        }
    }

    function _getStake(address _user, uint256 _index) internal view returns (Stake storage) {
        Stake[] storage userStakes = stakes[_user];
        if (userStakes.length == 0) {
            revert NotParticipated();
        }
        if (userStakes.length <= _index) {
            revert StakeNotExist();
        }
        Stake storage stake = userStakes[_index];
        return stake;
    }

    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a <= _b ? _a : _b;
    }

    function _getRewardEnd() internal view returns(uint256) {
        return _min(block.timestamp, rewardDeadline);
    }

    function getLockLengths() external view returns (uint256[] memory) {
        return lockLengths;
    }

    function pauseNewStakes() external onlyOwnerAccess {
        return _pause();
    }

    function unpauseNewStakes() external onlyOwnerAccess {
        return _unpause();
    }

    function withdrawReward(uint256 _amount) external onlyOwnerAccess {
        if (block.timestamp < rewardDeadline) {
            revert StakingInProgress();
        }

        if (address(token) == address(rewardToken)) {
            if (rewardToken.balanceOf(address(this)) < totalStaked + _amount) {
                revert BalanceNotEnough();
            }

        }
        if (!rewardToken.transfer(msg.sender, _amount)) {
            revert TransferFailed();
        }
    }

    function increaseMaxStakingReward(uint256 _increaseBy) external onlyOwnerAccess {
        maximumStakingRewards += _increaseBy;
    }

    function extendStakingTime(uint256 _newDeadline) external onlyOwnerAccess {
        if (_newDeadline <= rewardDeadline) {
            revert NotInTheFuture();
        }
        rewardDeadline = _newDeadline;
    }
}