// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ILockRewards {
    // Functions
    function balanceOf(address owner) external view returns (uint256);
    function balanceOfInEpoch(address owner, uint256 epochId) external view returns (uint256);
    function totalLocked() external view returns (uint256);
    function getCurrentEpoch()
        external
        view
        returns (uint256 start, uint256 finish, uint256 locked, uint256[] memory rewards, bool isSet);
    function getNextEpoch()
        external
        view
        returns (uint256 start, uint256 finish, uint256 locked, uint256[] memory rewards, bool isSet);
    function getEpoch(uint256 epochId)
        external
        view
        returns (uint256 start, uint256 finish, uint256 locked, uint256[] memory rewards, bool isSet);
    function getAccount(address owner)
        external
        view
        returns (uint256 balance, uint256 lockEpochs, uint256 lastEpochPaid, uint256[] memory rewards);
    function updateAccount()
        external
        returns (uint256 balance, uint256 lockEpochs, uint256 lastEpochPaid, uint256[] memory rewards);
    function deposit(uint256 amount) external;
    function redeposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function claimRewards() external returns (uint256[] memory);
    function claimReward(address reward) external returns (uint256);
    function exit() external returns (uint256[] memory);
    function emergencyExit() external returns (uint256[] memory);
    function setNextEpoch(uint256[] calldata values) external;
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
    function changeRecoverWhitelist(address tokenAddress, bool flag) external;
    function recoverERC721(address tokenAddress, uint256 tokenId) external;
    function changeEnforceTime(bool flag) external;

    // Events
    event Deposit(address indexed user, uint256 amount, uint256 lockedEpochs);
    event Relock(address indexed user, uint256 totalBalance, uint256 lockedEpochs);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address token, uint256 reward);
    event SetLockDuration(uint256 duration);
    event SetNextReward(uint256 indexed epochId, uint256[] values, uint256 start, uint256 finish);

    event RecoveredERC20(address token, uint256 amount);
    event RecoveredERC721(address token, uint256 tokenId);
    event ChangeERC20Whiltelist(address token, bool tokenState);
    event ChangeEnforceTime(uint256 indexed currentTime, bool flag);
    event ChangeMaxLockEpochs(uint256 indexed currentTime, uint256 oldEpochs, uint256 newEpochs);
    event NewRewardToken(address indexed rewardToken);
    event RemovedRewardToken(address indexed rewardToken);

    // Errors
    error InsufficientAmount();
    error InsufficientBalance();
    error InsufficientDeposit();
    error IncorrectLockDuration();
    error RewardTokenAlreadyExists(address token);
    error RewardTokenCannotBeLockToken(address token);
    error IncorrectRewards(uint256 provided, uint256 expected);
    error RewardTokenDoesNotExist(address token);
    error FundsInLockPeriod(uint256 balance);
    error InsufficientFundsForRewards(address token, uint256 available, uint256 rewardAmount);
    error LockEpochsMax(uint256 maxEpochs);
    error NotWhitelisted();
    error CannotWhitelistGovernanceToken(address governanceToken);
    error CannotWhitelistLockedToken(address lockedToken);
    error EpochMaxReached(uint256 maxEpochs);
    error EpochStartInvalid(uint256 epochStart, uint256 now);

    // Structs
    struct Account {
        uint256 balance;
        uint256 lockStart;
        uint256 lockEpochs;
        uint256 lastEpochPaid;
        mapping(address => uint256) rewards;
        address[] rewardTokens;
        uint256 activeRewards;
    }

    struct Epoch {
        mapping(address => uint256) balanceLocked;
        uint256 start;
        uint256 finish;
        uint256 totalLocked;
        address[] tokens;
        uint256[] rewards;
        bool isSet;
    }

    struct RewardToken {
        address addr;
        uint256 rewards;
        uint256 rewardsPaid;
    }
}