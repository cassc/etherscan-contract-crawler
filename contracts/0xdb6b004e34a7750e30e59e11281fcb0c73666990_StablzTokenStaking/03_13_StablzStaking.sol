//SPDX-License-Identifier: Unlicense
pragma solidity = 0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Stablz staking
abstract contract StablzStaking is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    address public immutable stakingToken;
    address public immutable rewardToken;
    uint public immutable totalRewards;
    uint public totalAvailable;
    bool public initialized;
    bool public isDepositingEnabled;

    uint public minimumDeposit;

    uint public immutable apr1Month;
    uint public immutable apr3Month;
    uint public immutable apr6Month;
    uint public immutable apr12Month;
    uint internal constant APR_DENOMINATOR = 1000;

    struct Stake {
        uint lockUpPeriodType;
        uint stakedAt;
        uint amount;
        uint amountWithdrawn;
        uint allocatedRewards;
        uint claimedRewards;
    }

    mapping(address => Stake[]) private _userStakes;

    /// @param _lockUpPeriodType Lock up period type
    modifier onlyValidLockPeriod(uint _lockUpPeriodType) {
        require(_lockUpPeriodType <= 3, "StablzStaking: Invalid lock period");
        _;
    }

    /// @param _user User address
    /// @param _stakeId Stake ID
    modifier onlyValidStakeId(address _user, uint _stakeId) {
        Stake[] memory stakes = _userStakes[_user];
        require(_stakeId < stakes.length && stakes[_stakeId].amount != 0, "StablzStaking: Invalid stake ID");
        _;
    }

    modifier onlyIfInitialized() {
        require(initialized, "StablzStaking: Contract not initialized");
        _;
    }

    event Deposit(address user, uint stakeId, uint amount, uint lockUpPeriodType);
    event Withdraw(address user, uint stakeId, uint amount);
    event RewardsClaimed(address user, uint stakeId, uint rewards);
    event Initialized();
    event DepositingEnabled();
    event DepositingDisabled();
    event MinimumDepositUpdated(uint minimumDeposit);

    /// @param _stakingToken Token used for staking
    /// @param _rewardToken Token used for rewards
    /// @param _totalRewards Total rewards allocated for the contract
    /// @param _minimumDeposit Minimum deposit amount
    /// @param _apr1Month APR for 1 month to 1 d.p. e.g. 80 = 8%
    /// @param _apr3Month APR for 3 month to 1 d.p. e.g. 120 = 12%
    /// @param _apr6Month APR for 6 month to 1 d.p. e.g. 200 = 20%
    /// @param _apr12Month APR for 12 month to 1 d.p. e.g. 365 = 36.5%
    constructor(address _stakingToken, address _rewardToken, uint _totalRewards, uint _minimumDeposit, uint _apr1Month, uint _apr3Month, uint _apr6Month, uint _apr12Month) {
        require(_stakingToken != address(0), "StablzStaking: _stakingToken cannot be the zero address");
        require(_rewardToken != address(0), "StablzStaking: _rewardToken cannot be the zero address");
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        totalRewards = _totalRewards;
        minimumDeposit = _minimumDeposit;
        apr1Month = _apr1Month;
        apr3Month = _apr3Month;
        apr6Month = _apr6Month;
        apr12Month = _apr12Month;
    }

    /// @notice Initialize the contract by funding it with rewards, requires approval prior to calling
    function initialize() external onlyOwner {
        require(!initialized, "StablzStaking: Already initialized");
        initialized = true;
        totalAvailable = totalRewards;
        uint rewardBalance = IERC20(rewardToken).balanceOf(address(this));
        if (rewardBalance < totalRewards) {
            IERC20(rewardToken).safeTransferFrom(_msgSender(), address(this), totalRewards - rewardBalance);
        }
        emit Initialized();
    }

    /// @notice Enable depositing
    function enableDepositing() external onlyOwner onlyIfInitialized {
        isDepositingEnabled = true;
        emit DepositingEnabled();
    }

    /// @notice Disable depositing
    function disableDepositing() external onlyOwner onlyIfInitialized {
        isDepositingEnabled = false;
        emit DepositingDisabled();
    }

    /// @notice Set minimum deposit
    /// @param _minimumDeposit Minimum deposit amount
    function setMinimumDeposit(uint _minimumDeposit) external onlyOwner {
        minimumDeposit = _minimumDeposit;
        emit MinimumDepositUpdated(_minimumDeposit);
    }

    /// @notice Stake tokens for a given lock up period
    /// @param _amount Amount to stake
    /// @param _lockUpPeriodType Lock up period (0 = 30 days, 1 = 90 days, 2 = 180 days, 3 = 365 days)
    function deposit(uint _amount, uint _lockUpPeriodType) external nonReentrant onlyIfInitialized onlyValidLockPeriod(_lockUpPeriodType) {
        require(isDepositingEnabled, "StablzStaking: Depositing is not allowed at this time");
        require(_amount >= minimumDeposit && _amount > 0, "StablzStaking: Amount is not valid");
        uint forecastRewards = _calculateReward(_amount, _lockUpPeriodType);
        require(forecastRewards <= totalAvailable, "StablzStaking: Forecast rewards exceeds available rewards");
        totalAvailable -= forecastRewards;
        uint stakeId = _userStakes[_msgSender()].length;
        _userStakes[_msgSender()].push(
            Stake(
                _lockUpPeriodType,
                block.timestamp,
                _amount,
                0,
                forecastRewards,
                0
            )
        );
        IERC20(stakingToken).safeTransferFrom(_msgSender(), address(this), _amount);
        _giveReceipt(_msgSender(), _amount);
        emit Deposit(_msgSender(), stakeId, _amount, _lockUpPeriodType);
    }

    /// @notice Withdraws specific stake only after the lock up period and claims any unclaimed rewards
    /// @param _stakeId Stake ID
    /// @param _amount Amount of tokens to withdraw
    function withdraw(uint _stakeId, uint _amount) external nonReentrant onlyValidStakeId(_msgSender(), _stakeId) {
        Stake storage stake = _userStakes[_msgSender()][_stakeId];
        uint period = getLockUpPeriod(stake.lockUpPeriodType);
        require(block.timestamp >= stake.stakedAt + period, "StablzStaking: You cannot unstake before the lock up period");
        require(_amount > 0, "StablzStaking: You cannot withdraw zero tokens");
        require(stake.amountWithdrawn < stake.amount, "StablzStaking: Already withdrawn full amount");
        require(_amount <= stake.amount - stake.amountWithdrawn, "StablzStaking: Insufficient stake balance");

        stake.amountWithdrawn += _amount;

        if (stake.claimedRewards < stake.allocatedRewards) {
            uint unclaimedRewards = stake.allocatedRewards - stake.claimedRewards;
            stake.claimedRewards = stake.allocatedRewards;
            IERC20(rewardToken).safeTransfer(_msgSender(), unclaimedRewards);
            emit RewardsClaimed(_msgSender(), _stakeId, unclaimedRewards);
        }
        _takeReceipt(_msgSender(), _amount);
        IERC20(stakingToken).safeTransfer(_msgSender(), _amount);
        emit Withdraw(_msgSender(), _stakeId, _amount);
    }

    /// @notice Claim rewards for a given stake, can be called before or after lockup period ends as long as there are unclaimed rewards
    /// @param _stakeId Stake ID
    function claimRewards(uint _stakeId) external nonReentrant onlyValidStakeId(_msgSender(), _stakeId) {
        Stake storage stake = _userStakes[_msgSender()][_stakeId];
        require(stake.claimedRewards < stake.allocatedRewards, "StablzStaking: You have already claimed your rewards");
        uint period = getLockUpPeriod(stake.lockUpPeriodType);
        uint rewards;
        if (block.timestamp >= stake.stakedAt + period) {
            rewards = stake.allocatedRewards - stake.claimedRewards;
        } else {
            uint timeDifference = block.timestamp - stake.stakedAt;
            uint rewardsToDate = stake.allocatedRewards * timeDifference / period;
            rewards = rewardsToDate - stake.claimedRewards;
        }
        stake.claimedRewards += rewards;
        IERC20(rewardToken).safeTransfer(_msgSender(), rewards);
        emit RewardsClaimed(_msgSender(), _stakeId, rewards);
    }

    /// @notice Get a list of a given user's stakes between two indexes
    /// @param _user User address
    /// @param _startIndex Start index
    /// @param _endIndex End index
    /// @return list Page of user stakes
    function getUserStakes(address _user, uint _startIndex, uint _endIndex) external view returns (Stake[] memory list) {
        uint totalUserStakes = getTotalUserStakes(_user);

        require(_startIndex <= _endIndex, "StablzStaking: Start index must be less than or equal to end index");
        require(_startIndex < totalUserStakes, "StablzStaking: Invalid start index");
        require(_endIndex < totalUserStakes, "StablzStaking: Invalid end index");

        list = new Stake[](_endIndex - _startIndex + 1);
        uint listIndex;
        for (uint stakeId = _startIndex; stakeId <= _endIndex; stakeId++) {
            list[listIndex] = _userStakes[_user][stakeId];
            listIndex++;
        }
        return list;
    }

    /// @notice Get total number of user stakes
    /// @param _user User address
    /// @return uint Total number of user stakes
    function getTotalUserStakes(address _user) public view returns (uint) {
        return _userStakes[_user].length;
    }

    /// @notice Calculate the rewards earned at the end of the lockup period for a given amount
    /// @param _amount Amount to stake
    /// @param _lockUpPeriodType Lock up period (0-3)
    /// @return reward Calculated reward
    function calculateReward(uint _amount, uint _lockUpPeriodType) external view onlyValidLockPeriod(_lockUpPeriodType) returns (uint reward) {
        return _calculateReward(_amount, _lockUpPeriodType);
    }

    /// @notice Get APR for a given lock up period
    /// @param _lockUpPeriodType Lock up period (0-3)
    /// @return apr APR to 1 d.p.
    function getAPR(uint _lockUpPeriodType) public view onlyValidLockPeriod(_lockUpPeriodType) returns (uint apr) {
        if (_lockUpPeriodType == 0) {
            apr = apr1Month;
        } else if (_lockUpPeriodType == 1) {
            apr = apr3Month;
        } else if (_lockUpPeriodType == 2) {
            apr = apr6Month;
        } else {
            apr = apr12Month;
        }
    }

    /// @notice Get the length of a lock up period in seconds
    /// @param _lockUpPeriodType Lock up period (0-3)
    /// @return time Lock up period in seconds
    function getLockUpPeriod(uint _lockUpPeriodType) public pure onlyValidLockPeriod(_lockUpPeriodType) returns (uint time) {
        if (_lockUpPeriodType == 0) {
            time = 30 days;
        } else if (_lockUpPeriodType == 1) {
            time = 90 days;
        } else if (_lockUpPeriodType == 2) {
            time = 180 days;
        } else {
            time = 365 days;
        }
    }

    function _giveReceipt(address _user, uint _amount) internal virtual;

    function _takeReceipt(address _user, uint _amount) internal virtual;

    function _calculateReward(uint _amount, uint _lockPeriodType) internal virtual view returns (uint reward);
}