pragma solidity ^0.8.14;

// SPDX-License-Identifier: MIT

import "./IERC20.sol";

interface IDarwinMasterChef {
    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 rewardLockedUp;  // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        uint256 lockedAmount;   // The part of `amount` that is locked.
        uint256 lockEnd;        // Timestamp of end of lock of the locked amount.
        //
        // We do some fancy math here. Basically, any point in time, the amount of DARWINs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accDarwinPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accDarwinPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;             // Address of LP token contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. DARWINs to distribute per second.
        uint256 lastRewardTime;     // Last time DARWINs distribution occurs.
        uint256 accDarwinPerShare;  // Accumulated DARWINs per share, times 1e18. See below.
        uint16 depositFeeBP;        // Deposit fee in basis points.
        uint16 withdrawFeeBP;       // Withdraw fee in basis points.
        uint256 harvestInterval;    // Harvest interval in seconds.
    }

    function withdrawByLPToken(IERC20 lpToken, uint256 _amount) external returns (bool);
    function depositByLPToken(IERC20 lpToken, uint256 _amount, bool _lock, uint256 _lockDuration) external returns (bool);
    function pendingDarwin(uint256 _pid, address _user) external view returns (uint256);
    function poolLength() external view returns (uint256);
    function poolInfo() external view returns (PoolInfo[] memory);
    function poolExistence(IERC20) external view returns (bool);
    function userInfo(uint256, address) external view returns (UserInfo memory);
    function darwin() external view returns (IERC20);
    function dev() external view returns (address);

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 newEmissionRate);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event StartTimeChanged(uint256 oldStartTime, uint256 newStartTime);
}