// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IBEP20.sol";
import "./Math.sol";

/**
 * Token Time Lock
 * @dev Allow owner send locked token to user
 * @author Brian Dhang
 */
contract TokenTimeLock is Pausable, Ownable {
    using Math for uint256;
    IBEP20 immutable _tokenContract;
    uint256 constant SECONDS_IN_DAY = 86400;
    uint256 public balances;

    struct Entity {
        string pool_name;
        string lock_code;
        address user;
        uint64 balance;
        uint64 released;
        uint64 release_now_amount;
        uint64 lock_period_amount;
        uint32 start_release_date;
        uint32 next_release_date;
        uint16 keep_period;
        uint16 lock_period;
    }

    Entity[] public entities;

    mapping(string => uint256) public poolActiveTime;
    mapping(string => uint256) public poolBalances;
    mapping(string => uint256) public poolReleasedBalances;
    mapping(string => uint256) public poolUsedBalances;
    mapping(address => uint256) public ownerEntityCount;
    mapping(string => bool) public lockCode;

    event SetPool(
        string pool_name,
        uint256 balance,
        uint256 released,
        uint256 active_time,
        uint256 timestamp
    );
    event Withdraw(uint256 amount, uint256 timestamp);
    event LockToken(
        uint256 id,
        string pool_name,
        string lock_code,
        address indexed user,
        uint256 balance,
        uint256 release_now_amount,
        uint256 lock_period_amount,
        uint256 start_release_date,
        uint256 next_release_date,
        uint256 keep_period,
        uint256 lock_period,
        uint256 timestamp
    );
    event UpdateLockedToken(
        uint256 id,
        string pool_name,
        string lock_code,
        address indexed user,
        uint256 balance,
        uint256 release_now_amount,
        uint256 lock_period_amount,
        uint256 start_release_date,
        uint256 next_release_date,
        uint256 keep_period,
        uint256 lock_period,
        uint256 timestamp
    );
    event Release(
        uint256 id,
        string pool_name,
        string lock_code,
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * Constructor
     * @dev Set token address
     */
    constructor(address token) {
        _tokenContract = IBEP20(token);
    }

    /**
     * Pause
     * @dev Allow owner pause contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * Pause
     * @dev Allow owner unpause contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * Set pool
     * @dev Allow owner set pool
     */
    function setPool(
        string memory pool_name,
        uint256 balance,
        uint256 released,
        uint256 active_time
    ) external onlyOwner {
        require(balance >= released, "Invalid amount");

        balances = balances + balance - poolBalances[pool_name];
        poolBalances[pool_name] = balance;
        poolReleasedBalances[pool_name] = released;
        poolActiveTime[pool_name] = active_time;

        emit SetPool(
            pool_name,
            balance,
            released,
            active_time,
            block.timestamp
        );
    }

    /**
     * Withdraw
     * @dev Allow owner withdraw when contract have critical issue
     */
    function withdraw() external onlyOwner {
        uint256 amount = _tokenContract.balanceOf(address(this));
        _tokenContract.transfer(msg.sender, amount);
        emit Withdraw(amount, block.timestamp);
    }

    /**
     * Get entity ids by user
     * @dev Allow anyone get entities of specified user
     */
    function getEntityIdsByUser(address user)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](ownerEntityCount[user]);
        uint256 counter = 0;
        for (uint256 i = 0; i < entities.length; i++) {
            if (entities[i].user == user) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    /**
     * Lock token
     * @dev Allow owner send locked token to user
     */
    function lockToken(
        string memory pool_name,
        string memory lock_code,
        address user,
        uint256 balance,
        uint256 released,
        uint256 release_now_amount,
        uint256 lock_period_amount,
        uint256 keep_period,
        uint256 lock_period
    ) external onlyOwner {
        require(
            poolBalances[pool_name] >= poolUsedBalances[pool_name] + balance,
            "Pool not have enough token"
        );

        // Update pool balances
        poolUsedBalances[pool_name] += balance;

        // Calculate release time
        uint256 start_release_date = poolActiveTime[pool_name] +
            keep_period *
            SECONDS_IN_DAY;
        uint256 next_release_date = start_release_date;

        // Lock token for user
        entities.push(
            Entity(
                pool_name,
                lock_code,
                user,
                uint64(balance),
                uint64(released),
                uint64(release_now_amount),
                uint64(lock_period_amount),
                uint32(start_release_date),
                uint32(next_release_date),
                uint16(keep_period),
                uint16(lock_period)
            )
        );
        uint256 id = entities.length - 1;

        ownerEntityCount[user]++;
        lockCode[lock_code] = true;

        emit LockToken(
            id,
            pool_name,
            lock_code,
            user,
            balance,
            release_now_amount,
            lock_period_amount,
            start_release_date,
            next_release_date,
            keep_period,
            lock_period,
            block.timestamp
        );
    }

    /**
     * Update locked token
     * @dev Allow owner update balance, period for locked token
     */
    function updateLockedToken(
        uint256 id,
        address user,
        uint256 balance,
        uint256 release_now_amount,
        uint256 lock_period_amount,
        uint256 keep_period,
        uint256 lock_period
    ) external onlyOwner {
        require(id < entities.length, "Invalid id");
        Entity storage entity = entities[id];

        require(
            poolBalances[entity.pool_name] >=
                poolUsedBalances[entity.pool_name] + balance - entity.balance,
            "Pool not have enough token"
        );

        require(balance >= entity.released, "Invalid balance");

        // Update pool balances
        poolUsedBalances[entity.pool_name] =
            poolUsedBalances[entity.pool_name] +
            balance -
            entity.balance;

        // Calculate release time
        uint256 start_release_date = poolActiveTime[entity.pool_name] +
            keep_period *
            SECONDS_IN_DAY;
        uint256 next_release_date = start_release_date;

        // Update user
        ownerEntityCount[entity.user]--;
        ownerEntityCount[user]++;

        entity.user = user;
        entity.balance = uint64(balance);
        entity.release_now_amount = uint64(release_now_amount);
        entity.lock_period_amount = uint64(lock_period_amount);
        entity.start_release_date = uint32(start_release_date);
        entity.next_release_date = uint32(next_release_date);
        entity.keep_period = uint16(keep_period);
        entity.lock_period = uint16(lock_period);

        emit UpdateLockedToken(
            id,
            entity.pool_name,
            entity.lock_code,
            user,
            balance,
            release_now_amount,
            lock_period_amount,
            start_release_date,
            next_release_date,
            keep_period,
            lock_period,
            block.timestamp
        );
    }

    /**
     * Get available release amount
     * @dev Allow anyone get available release token amount of specified user
     */
    function getAvailableReleaseAmount(uint256 id)
        public
        view
        returns (uint256, uint256)
    {
        require(id < entities.length, "Invalid id");

        Entity memory entity = entities[id];

        if (entity.lock_period > 0) {
            uint256 releasingAmount = entity.release_now_amount;
            uint256 releaseNumber;

            if (block.timestamp > entity.start_release_date) {
                releaseNumber = Math.ceilDiv(
                    block.timestamp - entity.start_release_date,
                    entity.lock_period * SECONDS_IN_DAY
                );
                releasingAmount += releaseNumber * entity.lock_period_amount;
            }

            return (
                Math.min(releasingAmount, entity.balance) - entity.released,
                releaseNumber
            );
        }

        return (entity.balance - entity.released, 0);
    }

    /**
     * Claim
     * @dev Allow anyone check and claim token for specified entity
     */
    function claim(uint256 id) external whenNotPaused {
        (uint256 amount, uint256 releaseNumber) = getAvailableReleaseAmount(id);
        require(amount > 0, "Invalid amount to release");

        Entity storage entity = entities[id];

        uint256 timestamp = block.timestamp;
        require(
            timestamp > poolActiveTime[entity.pool_name],
            "Listing still in countdown"
        );

        poolReleasedBalances[entity.pool_name] += amount;
        entity.released += uint64(amount);

        // Calculate release time
        entity.next_release_date = uint32(
            entity.start_release_date +
                releaseNumber *
                entity.lock_period *
                SECONDS_IN_DAY
        );

        _tokenContract.transfer(entity.user, amount);

        emit Release(
            id,
            entity.pool_name,
            entity.lock_code,
            entity.user,
            amount,
            timestamp
        );
    }
}
