// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../AdminableUpgradeable.sol';
import '../staking/IStakingLockable.sol';
import '../interfaces/ILevelManager.sol';
import './WithLevels.sol';
import './WithPools.sol';

contract LevelManager is Initializable, AdminableUpgradeable, ILevelManager, WithLevels, WithPools {
    bytes32 public constant ADDER_ROLE = keccak256('ADDER_ROLE');

    mapping(address => bool) isIDO;
    // Address to level idx. 0 idx makes it fetch the real level
    mapping(address => uint256) public forceLevel;
    address[] public forceLevelAddresses;

    event Registered(address indexed account, address sale, uint256 time);
    event Unregistered(address indexed account, address sale);

    function initialize() public override initializer {
        AdminableUpgradeable.initialize();
        WithLevels.initializeNoneLevel();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADDER_ROLE, _msgSender());
    }

    modifier onlyIDO() {
        require(isIDO[_msgSender()], 'Only IDOs can lock');
        _;
    }

    /**
     * Returns the nearest of all pools unlock time.
     */
    function getUserUnlockTime(address account) external view override returns (uint256) {
        uint256 nextTime;
        for (uint256 i; i < pools.length; i++) {
            IStakingLockable pool = IStakingLockable(pools[i].addr);
            uint256 time = pool.getUnlocksAt(account);
            if (time > block.timestamp && (nextTime == 0 || time < nextTime)) {
                nextTime = time;
            }
        }

        return nextTime;
    }

    function getUserTier(address account) public view override returns (Tier memory) {
        (Tier memory tier, , , ) = getUserTierForPools(account, new address[](0));
        return tier;
    }

    // Returns the tier, the max amount in one of the specified pools,
    // the bool indicating if the pool with that max amount is locked - i.e. active, and the unlock time.
    function getUserTierPools(address account, address[] calldata poolAddresses)
        public
        view
        returns (
            Tier memory,
            uint256,
            bool,
            uint256
        )
    {
        return getUserTierForPools(account, poolAddresses);
    }
    
    function getUserTierStatus(address account)
    public
    view
    returns (
        Tier memory,
        uint256,
        bool,
        uint256
    )
    {
        return getUserTierForPools(account, new address[](0));
    }
    
    
    // Returns: tier, max amount, is locked, unlock time
    function getUserTierForPools(address account, address[] memory poolAddresses)
        internal
        view
        returns (
            Tier memory,
            uint256,
            bool,
            uint256
        )
    {
        // If an account has a level assigned
        if (forceLevel[account] > 0) {
            return (tiers[forceLevel[account]], tiers[forceLevel[account]].minAmount, true, 0);
        }

        // The pool with max staked tokens
        Pool memory maxPool = pools[0];
        uint256 maxAmount;
        for (uint8 i = 0; i < pools.length; i++) {
            if (!pools[i].enabled) continue;
            if (poolAddresses.length > 0) {
                bool matches = false;
                for (uint8 j = 0; j < poolAddresses.length; j++) {
                    if (pools[i].addr == poolAddresses[j]) {
                        matches = true;
                        break;
                    }
                }
                if (!matches) {
                    continue;
                }
            }
            uint256 amount = getPoolAmount(account, pools[i]);

            if (amount > maxAmount) {
                maxAmount = amount;
                maxPool = pools[i];
            }
        }

        Tier memory tier = tiers[getTierIdxForAmount(maxAmount, !maxPool.isVip)];
        // Update tier AAG flag, depends on whether user stakes in an AAG pool.
        tier.aag = tier.aag && maxPool.isAAG;

        // Boost multiplier based on the pool where the max amount is staked
        if (tier.multiplier > 0) {
            uint256 boost = tier.random
                ? maxPool.multiplierLotteryBoost
                : (tier.aag ? maxPool.multiplierAAGBoost : maxPool.multiplierGuaranteedBoost);
            tier.multiplier += (tier.multiplier * boost) / 1000;
        }

        bool isLocked = IStakingLockable(maxPool.addr).isLocked(account);
        uint256 unlocksAt = isLocked ? IStakingLockable(maxPool.addr).getUnlocksAt(account) : 0;

        return (tier, maxAmount, isLocked, unlocksAt);
    }

    // AAG level is when user:
    // - stakes in selected pools "pool.isAAG"
    // - has a specified level "tier.aag"
    // pool.isAAG && tier.aag (staked in that pool)
    function getIsUserAAG(address account) external view override returns (bool) {
        return getUserTier(account).aag;
    }

    function getUserAmount(address account) public view returns (uint256) {
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < pools.length; i++) {
            totalAmount += getPoolAmount(account, pools[i]);
        }

        return totalAmount;
    }

    function getUserPoolAmount(address account, address pool) public view returns (uint256) {
        for (uint256 i = 0; i < pools.length; i++) {
            if (pools[i].addr == pool) {
                return getPoolAmount(account, pools[i]);
            }
        }

        return 0;
    }

    /**
     * Previously it supported the LP pool, so a pool multiplier was used.
     * Now we support TPAD as the only token countable towards a level.
     * With multiplier support it was: (IStakingLockable(pool.addr).getLockedAmount(account) * pool.multiplier) / DEFAULT_MULTIPLIER
     */
    function getPoolAmount(address account, Pool storage pool) internal view returns (uint256) {
        return pool.enabled ? IStakingLockable(pool.addr).getLockedAmount(account) : 0;
    }

    function addIDO(address account) external onlyRole(ADDER_ROLE) {
        require(account != address(0), 'IDO cannot be zero address');
        isIDO[account] = true;
    }

    // Override the level id, set 0 to reset
    function setAccountLevel(address account, uint256 levelIdx) external onlyOwner {
        forceLevel[account] = levelIdx;
        address[] storage addrs = forceLevelAddresses;
        if (levelIdx > 0) {
            for (uint256 i = 0; i < addrs.length; i++) {
                if (addrs[i] == account) {
                    return;
                }
            }
            addrs.push(account);
        } else {
            // Delete address
            for (uint256 i = 0; i < addrs.length; i++) {
                if (addrs[i] == account) {
                    for (uint256 j = i; j < addrs.length - 1; j++) {
                        addrs[j] = addrs[j + 1];
                    }
                    addrs.pop();
                    break;
                }
            }
        }
    }

    function getAlwaysRegister()
        external
        view
        override
        returns (
            address[] memory,
            string[] memory,
            uint256[] memory
        )
    {
        uint256 length = forceLevelAddresses.length;
        address[] memory addresses = new address[](length);
        string[] memory tiersIds = new string[](length);
        uint256[] memory weights = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            address addr = forceLevelAddresses[i];
            uint256 levelIdx = forceLevel[addr];
            addresses[i] = addr;
            tiersIds[i] = tiers[levelIdx].id;
            weights[i] = tiers[levelIdx].multiplier;
        }
        return (addresses, tiersIds, weights);
    }

    function lock(address account, uint256 startTime) external override onlyIDO {
        internalLock(account, msg.sender, startTime);
    }

    function internalLock(
        address account,
        address saleAddress,
        uint256 registeredAt
    ) internal {
        Pool memory maxPool = pools[0];
        uint256 maxAmount;
        for (uint8 i = 0; i < pools.length; i++) {
            if (!pools[i].enabled) continue;
            uint256 amount = getPoolAmount(account, pools[i]);
            if (amount > maxAmount) {
                maxAmount = amount;
                maxPool = pools[i];
            }
        }
    
        try IStakingLockable(maxPool.addr).lock(account, registeredAt) {} catch {}
        
        emit Registered(account, saleAddress, registeredAt);
    }

    function batchRegister(
        address[] calldata addresses,
        address[] calldata saleAddresses,
        uint256[] calldata registeredAt
    ) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            internalLock(addresses[i], saleAddresses[i], registeredAt[i]);
        }
    }
}