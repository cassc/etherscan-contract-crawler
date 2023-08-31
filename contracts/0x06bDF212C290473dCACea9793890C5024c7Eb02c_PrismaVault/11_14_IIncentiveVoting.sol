// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IIncentiveVoting {
    struct Vote {
        uint256 id;
        uint256 points;
    }

    struct LockData {
        uint256 amount;
        uint256 weeksToUnlock;
    }

    event AccountWeightRegistered(
        address indexed account,
        uint256 indexed week,
        uint256 frozenBalance,
        LockData[] registeredLockData
    );
    event ClearedVotes(address indexed account, uint256 indexed week);
    event NewVotes(address indexed account, uint256 indexed week, Vote[] newVotes, uint256 totalPointsUsed);

    function clearRegisteredWeight(address account) external returns (bool);

    function clearVote(address account) external;

    function getReceiverVotePct(uint256 id, uint256 week) external returns (uint256);

    function getReceiverWeightWrite(uint256 idx) external returns (uint256);

    function getTotalWeightWrite() external returns (uint256);

    function registerAccountWeight(address account, uint256 minWeeks) external;

    function registerAccountWeightAndVote(address account, uint256 minWeeks, Vote[] calldata votes) external;

    function registerNewReceiver() external returns (uint256);

    function setDelegateApproval(address _delegate, bool _isApproved) external;

    function unfreeze(address account, bool keepVote) external returns (bool);

    function vote(address account, Vote[] calldata votes, bool clearPrevious) external;

    function MAX_LOCK_WEEKS() external view returns (uint256);

    function MAX_POINTS() external view returns (uint256);

    function getAccountCurrentVotes(address account) external view returns (Vote[] memory votes);

    function getAccountRegisteredLocks(
        address account
    ) external view returns (uint256 frozenWeight, LockData[] memory lockData);

    function getReceiverWeight(uint256 idx) external view returns (uint256);

    function getReceiverWeightAt(uint256 idx, uint256 week) external view returns (uint256);

    function getTotalWeight() external view returns (uint256);

    function getTotalWeightAt(uint256 week) external view returns (uint256);

    function getWeek() external view returns (uint256 week);

    function isApprovedDelegate(address owner, address caller) external view returns (bool isApproved);

    function receiverCount() external view returns (uint256);

    function receiverDecayRate(uint256) external view returns (uint32);

    function receiverUpdatedWeek(uint256) external view returns (uint16);

    function receiverWeeklyUnlocks(uint256, uint256) external view returns (uint32);

    function tokenLocker() external view returns (address);

    function totalDecayRate() external view returns (uint32);

    function totalUpdatedWeek() external view returns (uint16);

    function totalWeeklyUnlocks(uint256) external view returns (uint32);

    function vault() external view returns (address);
}