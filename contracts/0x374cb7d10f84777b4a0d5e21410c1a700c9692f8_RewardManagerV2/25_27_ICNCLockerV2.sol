// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "MerkleProof.sol";

interface ICNCLockerV2 {
    event Locked(address indexed account, uint256 amount, uint256 unlockTime, bool relocked);
    event UnlockExecuted(address indexed account, uint256 amount);
    event Relocked(address indexed account, uint256 amount);
    event KickExecuted(address indexed account, address indexed kicker, uint256 amount);
    event FeesReceived(address indexed sender, uint256 crvAmount, uint256 cvxAmount);
    event FeesClaimed(address indexed claimer, uint256 crvAmount, uint256 cvxAmount);
    event AirdropBoostClaimed(address indexed claimer, uint256 amount);
    event Shutdown();
    event TokenRecovered(address indexed token);

    struct VoteLock {
        uint256 amount;
        uint64 unlockTime;
        uint128 boost;
        uint64 id;
    }

    function lock(uint256 amount, uint64 lockTime) external;

    function lock(uint256 amount, uint64 lockTime, bool relock) external;

    function lockFor(uint256 amount, uint64 lockTime, bool relock, address account) external;

    function relock(uint64 lockId, uint64 lockTime) external;

    function relock(uint64 lockTime) external;

    function relockMultiple(uint64[] calldata lockIds, uint64 lockTime) external;

    function totalBoosted() external view returns (uint256);

    function shutDown() external;

    function recoverToken(address token) external;

    function executeAvailableUnlocks() external returns (uint256);

    function executeAvailableUnlocksFor(address dst) external returns (uint256);

    function executeUnlocks(address dst, uint64[] calldata lockIds) external returns (uint256);

    function claimAirdropBoost(uint256 amount, MerkleProof.Proof calldata proof) external;

    // This will need to include the boosts etc.
    function balanceOf(address user) external view returns (uint256);

    function unlockableBalance(address user) external view returns (uint256);

    function unlockableBalanceBoosted(address user) external view returns (uint256);

    function kick(address user, uint64 lockId) external;

    function receiveFees(uint256 amountCrv, uint256 amountCvx) external;

    function claimableFees(
        address account
    ) external view returns (uint256 claimableCrv, uint256 claimableCvx);

    function claimFees() external returns (uint256 crvAmount, uint256 cvxAmount);

    function computeBoost(uint128 lockTime) external view returns (uint128);

    function airdropBoost(address account) external view returns (uint256);

    function claimedAirdrop(address account) external view returns (bool);

    function totalVoteBoost(address account) external view returns (uint256);

    function totalRewardsBoost(address account) external view returns (uint256);

    function userLocks(address account) external view returns (VoteLock[] memory);
}