// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITokenLocker {
    struct LockData {
        uint256 amount;
        uint256 weeksToUnlock;
    }
    struct ExtendLockData {
        uint256 amount;
        uint256 currentWeeks;
        uint256 newWeeks;
    }

    event LockCreated(address indexed account, uint256 amount, uint256 _weeks);
    event LockExtended(address indexed account, uint256 amount, uint256 _weeks, uint256 newWeeks);
    event LocksCreated(address indexed account, LockData[] newLocks);
    event LocksExtended(address indexed account, ExtendLockData[] locks);
    event LocksFrozen(address indexed account, uint256 amount);
    event LocksUnfrozen(address indexed account, uint256 amount);
    event LocksWithdrawn(address indexed account, uint256 withdrawn, uint256 penalty);

    function extendLock(uint256 _amount, uint256 _weeks, uint256 _newWeeks) external returns (bool);

    function extendMany(ExtendLockData[] calldata newExtendLocks) external returns (bool);

    function freeze() external;

    function getAccountWeightWrite(address account) external returns (uint256);

    function getTotalWeightWrite() external returns (uint256);

    function lock(address _account, uint256 _amount, uint256 _weeks) external returns (bool);

    function lockMany(address _account, LockData[] calldata newLocks) external returns (bool);

    function setPenaltyWithdrawalsEnabled(bool _enabled) external returns (bool);

    function unfreeze(bool keepIncentivesVote) external;

    function withdrawExpiredLocks(uint256 _weeks) external returns (bool);

    function withdrawWithPenalty(uint256 amountToWithdraw) external returns (uint256);

    function MAX_LOCK_WEEKS() external view returns (uint256);

    function PRISMA_CORE() external view returns (address);

    function getAccountActiveLocks(
        address account,
        uint256 minWeeks
    ) external view returns (LockData[] memory lockData, uint256 frozenAmount);

    function getAccountBalances(address account) external view returns (uint256 locked, uint256 unlocked);

    function getAccountWeight(address account) external view returns (uint256);

    function getAccountWeightAt(address account, uint256 week) external view returns (uint256);

    function getTotalWeight() external view returns (uint256);

    function getTotalWeightAt(uint256 week) external view returns (uint256);

    function getWeek() external view returns (uint256 week);

    function getWithdrawWithPenaltyAmounts(
        address account,
        uint256 amountToWithdraw
    ) external view returns (uint256 amountWithdrawn, uint256 penaltyAmountPaid);

    function guardian() external view returns (address);

    function incentiveVoter() external view returns (address);

    function lockToTokenRatio() external view returns (uint256);

    function lockToken() external view returns (address);

    function owner() external view returns (address);

    function penaltyWithdrawalsEnabled() external view returns (bool);

    function prismaCore() external view returns (address);

    function totalDecayRate() external view returns (uint32);

    function totalUpdatedWeek() external view returns (uint16);
}