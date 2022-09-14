// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../AdminableUpgradeable.sol";
import "../staking/IStakingLockable.sol";
import "./ILevelManager.sol";
import "./WithLevels.sol";
import "./WithPools.sol";

contract LevelManager is
    Initializable,
    AdminableUpgradeable,
    ILevelManager,
    WithLevels,
    WithPools
{
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Registration {
        mapping(address => uint256) registeredAt;
        EnumerableSet.AddressSet sales;
    }

    bytes32 public constant ADDER_ROLE = keccak256("ADDER_ROLE");

    mapping(address => bool) isIDO;
    // List of user registration dates, if user de-register, the date becomes zero and doesn't count for locking
    mapping(address => Registration) private userState;

    // Address to level idx. 0 idx makes it fetch the real level
    mapping(address => uint256) public forceLevel;
    address[] public forceLevelAddresses;
    // Only staking in these pools will count the vip levels (required to stake min tier.amount in a pool)
    address[] public vipPools;
    mapping(address => bool) public isBlacklisted;
    
    event Registered(address indexed account, address sale, uint256 time);
    event Unregistered(address indexed account, address sale);
    event Blacklisted(bool status, address[] addresses);
    
    function initialize() public override initializer {
        AdminableUpgradeable.initialize();
        WithLevels.initializeNoneLevel();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADDER_ROLE, _msgSender());
    }

    modifier onlyIDO() {
        require(isIDO[_msgSender()], "Only IDOs can lock");
        _;
    }

    /**
     * Returns the nearest of all pools unlock time.
     */
    function getUserUnlockTime(address account)
        external
        view
        override
        returns (uint256)
    {
        uint256 nextTime;
        for (uint256 i; i < pools.length; i++) {
            IStakingLockable pool = IStakingLockable(pools[i]);
            uint256 time = pool.getUnlocksAt(account);
            if (time > block.timestamp && (nextTime == 0 || time < nextTime)) {
                nextTime = time;
            }
        }

        return nextTime;
    }

    function getUserTier(address account)
        public
        view
        override
        returns (Tier memory)
    {
        if (forceLevel[account] > 0) {
            return tiers[forceLevel[account]];
        }

        Tier memory tier;

        // First check if there's enough tokens in the VIP pools to qualify for the vip level
        if (vipPools.length > 0) {
            tier = tiers[
                getTierIdxForAmount(
                    getUserPoolsAmount(account, vipPools),
                    false
                )
            ];
            if (tier.vip) {
                return tier;
            }
        }

        // Otherwise return the tier, skipping the VIP tiers
        return
            tiers[
                getTierIdxForAmount(getUserPoolsAmount(account, pools), true)
            ];
    }

    function getUserRegistrations(address account)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 len = userState[account].sales.length();
        address[] memory sales = new address[](len);
        uint256[] memory times = new uint256[](len);
        for (uint256 i; i < len; i++) {
            sales[i] = userState[account].sales.at(i);
            times[i] = userState[account].registeredAt[sales[i]];
        }

        return (sales, times);
    }

    // Finds the latest registration: sale address and time. Unregistered sales are skipped.
    function getUserLatestRegistration(address account)
        public
        view
        override
        returns (address, uint256)
    {
        Registration storage state = userState[account];
        address sale = address(0);
        uint256 time = 0;
        for (uint256 i; i < state.sales.length(); i++) {
            address s = state.sales.at(i);
            uint256 t = state.registeredAt[s];
            if (t > time) {
                time = t;
                sale = s;
            }
        }
        return (sale, time);
    }

    function getUserAmount(address account) public view returns (uint256) {
        return getUserPoolsAmount(account, pools);
    }

    function getUserPoolsAmount(address account, address[] storage _pools)
        internal
        view
        returns (uint256)
    {
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _pools.length; i++) {
            address addr = _pools[i];
            if (poolEnabled[addr]) {
                totalAmount +=
                    (IStakingLockable(addr).getLockedAmount(account) *
                        poolMultiplier[addr]) /
                    DEFAULT_MULTIPLIER;
            }
        }

        return totalAmount;
    }

    function addIDO(address account) external onlyRole(ADDER_ROLE) {
        require(account != address(0), "IDO cannot be zero address");
        isIDO[account] = true;
    }

    // Override the level id, set 0 to reset
    function setAccountLevel(address account, uint256 levelIdx)
        external
        onlyOwner
    {
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

    function lock(address account, uint256 startTime)
        external
        override
        onlyIDO
    {
        require(!isBlacklisted[account], "Account is blacklisted");
        internalLock(account, msg.sender, startTime);
    }

    function unlock(address account) external override onlyIDO {
        internalUnlock(account, msg.sender);
    }

    function internalLock(
        address account,
        address saleAddress,
        uint256 registeredAt
    ) internal {
        require(
            userState[account].registeredAt[saleAddress] == 0,
            "LevelManager: User is already registered"
        );

        userState[account].sales.add(saleAddress);
        userState[account].registeredAt[saleAddress] = registeredAt;

        for (uint256 i; i < pools.length; i++) {
            if (!poolEnabled[pools[i]]) {
                continue;
            }
            IStakingLockable pool = IStakingLockable(pools[i]);
            if (pool.getLockedAmount(account) > 0) {
                try pool.lock(account, registeredAt) {} catch {}
            }
        }

        emit Registered(account, saleAddress, registeredAt);
    }

    function internalUnlock(address account, address saleAddress) internal {
        Registration storage state = userState[account];
        uint256 registeredAt = state.registeredAt[saleAddress];
        require(registeredAt > 0, "LevelManager: User is already unregistered");

        state.sales.remove(saleAddress);
        state.registeredAt[saleAddress] = 0;

        // Check if new latest registration is still after the lock time. If not, we reset the lock time to the last one
        //        (, uint256 latestRegTime) = getUserLatestRegistration();
        // TODO: unlock only if user's lock was extended because of the registration

        emit Unregistered(account, saleAddress);
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

    function setVipPools(address[] calldata _pools) external onlyOwner {
        vipPools = _pools;
    }
    
    function isUserBlacklisted(address account) external override view returns(bool) {
        return isBlacklisted[account];
    }
    
    function batchBlacklist(bool status, address[] calldata addresses) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            isBlacklisted[addr] = status;
        }
        emit Blacklisted(status, addresses);
    }
}