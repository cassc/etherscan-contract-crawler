//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ITarget } from "../libraries/Adapter.sol";
import { Rewarder } from "../libraries/SafeRewarder.sol";

interface IMasterMind {
    struct UserInfo {
        uint256 rewardableDeposit;
        uint256 lastDepositBlock;
    }

    struct PoolInfo {
        ITarget target;
        address adapter;
        uint256 targetPoolId; // recompoundingDeposits should be calculated as lockedAmount(pool) - pool.rewardableDeposits
        uint256 rewardableDeposits;
    }

    struct RolesSlot {
        address owner;
        address service;
    }
    
    struct DrainProtectionSlot {
        mapping (address => bool) allowedDrainers;
        bool enabled;
    }

    struct DrainAddressSlot {
        address value;
    }

    struct RewarderSlot {
        Rewarder value;
    }

    struct UserInfoSlot {
        mapping (uint256 => mapping (address => UserInfo)) users;
    }

    struct PoolInfoSlot {
        mapping(uint256 => PoolInfo) pools;
        uint256 count;
    }

    event  Deposit(address indexed user, uint256 indexed poolId, uint256 rewardableAmount);
    event Withdraw(address indexed user, uint256 indexed poolId,  uint256 rewardableAmount);
    event Drain(uint256 indexed poolId, address indexed token, uint256 claimedAmount);
    event Add(uint256 indexed poolId);
    event AddBulk(uint256 indexed start, uint256 indexed finish);
    event UpdateTargetInfo(uint256 indexed poolId);
    event UpdateAdapter(uint256 indexed poolId);
    
    /* Views */
    function owner() external view returns (address);
    function service() external view returns (address);
    function drainProtectionEnabled() external view returns (bool);
    function allowedDrainer(address drainer) external view returns (bool);
    function drainAddress() external view returns (address);
    function rewarder() external view returns (address);
    function userInfo(uint256 poolId, address user) external view returns (UserInfo memory);
    function poolInfo(uint256 poolId) external view returns (PoolInfo memory);
    function poolCount() external view returns (uint256);
    function lockableToken(uint256 poolId) external view returns(address);
    function userDeposits(uint256 poolId, address userAddress) external view returns (uint256 rewardableDeposit);
    function earnedRewards(uint256 poolId, address userOfTarget) external view returns (address[] memory, uint256[] memory);
    /* Mutators */
    function init(address newOwner) external;
    function updateService(address newService) external;
    function setDrainProtection(bool enabled) external;
    function setDrainerAllowance(address drainer, bool allow) external;
    function updateRewarder(address newRewarder) external;
    function updateDrainAddress(address newDrainAddress) external;
    function updateOwner(address newOwner) external;
    function updatePool(uint256 poolId, uint256 amount) external;
    function addBulk(ITarget target, address adapter, uint256[] memory targetPids) external;
    function claim(uint256 poolId, address to) external;
    function updateTargetInfo(uint256 poolId, ITarget newTarget, address newAdapter, uint256 newTargetPoolId, bool restake) external;
    function massUpdateTarget(uint256[] memory poolId, ITarget[] memory newTarget, address[] memory newAdapter, uint256[] memory newTargetPoolId, bool[] memory restake) external;
    function massUpdateAdapter(uint256[] memory poolId, address newAdapter) external;
    function deposit(uint256 poolId, uint256 rewardableAmount, bool claimRewards) external;
    function withdraw(uint256 poolId,  uint256 rewardableAmount, bool claimRewards) external;
    function drain(uint256[] memory poolIds) external;
}