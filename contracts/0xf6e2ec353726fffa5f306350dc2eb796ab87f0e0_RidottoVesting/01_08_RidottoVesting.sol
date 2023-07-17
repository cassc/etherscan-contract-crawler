// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './Readable.sol';


contract RidottoVesting is Ownable, Readable {
    using SafeERC20 for IERC20;

    IERC20 immutable public RDT;
    uint128 constant public HUNDRED_PERCENT = 1000;
    uint32 public TGEdate = 1632846600; // Tuesday, 28 September 2021 16:30:00
    bool public paused;

    uint constant LOCK_TYPES = 9;
    enum LockType {
        Private,
        IDO,
        Team,
        Rewards,
        Marketing,
        Advisor,
        Ecosystem,
        BugBounty,
        Reserve
    }

    struct LockConfig {
        uint32 releasedAtStart;
        uint32 cliff;
        uint32 duration;
        uint32 period;
    }

    struct Lock {
        uint128 balance;
        uint128 claimed;
    }

    struct DB {
        mapping(LockType => LockConfig) config;
        mapping(address => Lock[LOCK_TYPES]) locks;
    }

    DB internal db;

    constructor(IERC20 rdt, address newOwner) {
        RDT = rdt;
        db.config[LockType.Private] = LockConfig(25, 3 * months, 9 * months, 3 * months);
        db.config[LockType.IDO] = LockConfig(330, 1 * month, 3 * months, 1);
        db.config[LockType.Team] = LockConfig(0, 6 * months, 18 * months, 1);
        db.config[LockType.Rewards] = LockConfig(35, 1 * month, 12 * months, 1);
        db.config[LockType.Marketing] = LockConfig(0, 1 * month, 6 * months, 1);
        db.config[LockType.Advisor] = LockConfig(0, 6 * months, 18 * months, 1);
        db.config[LockType.Ecosystem] = LockConfig(0, 5 * month, 18 * months, 1);
        db.config[LockType.BugBounty] = LockConfig(0, 6 * month, 36 * months, 1);
        db.config[LockType.Reserve] = LockConfig(0, 1 * month, 12 * months, 1);
        transferOwnership(newOwner);
    }

    function getUserInfo(address who) external view returns(Lock[9] memory) {
        return db.locks[who];
    }

    function calcualteReleased(uint128 amount, uint32 releaseStart, LockConfig memory config)
    private view returns(uint128) {
        // Assumes that releaseStart already reached.
        uint128 atStart = amount * uint128(config.releasedAtStart) / HUNDRED_PERCENT;
        if (not(reached(releaseStart + config.cliff))) {
            return atStart;
        }
        uint128 period = config.period;
        uint128 periods = uint128(since(releaseStart)) / period;
        uint128 released = atStart + ((amount - atStart) * periods * period / config.duration);
        return uint128(Math.min(amount, released));
    }

    function calcualteClaimable(uint128 released, uint128 claimed) private pure returns(uint128) {
        if (released < claimed) {
            return 0;
        }
        return released - claimed;
    }

    function availableToClaim(address who) public view returns(uint128) {
        uint32 releaseStart = TGEdate;
        if (not(reached(releaseStart))) {
            return 0;
        }
        Lock[LOCK_TYPES] memory userLocks = db.locks[who];
        uint128 claimable = 0;
        for (uint8 i = 0; i < LOCK_TYPES; i++) {
            claimable += calcualteClaimable(
                calcualteReleased(userLocks[i].balance, releaseStart, db.config[LockType(i)]),
                userLocks[i].claimed
            );
        }
        return claimable;
    }

    function balanceOf(address who) external view returns(uint) {
        Lock[LOCK_TYPES] memory userLocks = db.locks[who];
        uint128 balances = 0;
        uint128 claimed = 0;
        for (uint8 i = 0; i < LOCK_TYPES; i++) {
            balances += userLocks[i].balance;
            claimed += userLocks[i].claimed;
        }
        if (claimed > balances) {
            return 0;
        }
        return balances - claimed;
    }

    function assign(LockType[] calldata lockTypes, address[] calldata tos, uint128[] calldata amounts)
    external onlyOwner {
        uint len = lockTypes.length;
        require(len == tos.length, 'Invalid tos input');
        require(len == amounts.length, 'Invalid amounts input');
        for (uint i = 0; i < len; i++) {
            LockType lockType = lockTypes[i];
            address to = tos[i];
            uint128 amount = amounts[i];
            db.locks[to][uint8(lockType)].balance += amount;
            emit LockAssigned(to, amount, lockType);
        }
    }

    function revoke(LockType[] calldata lockTypes, address[] calldata whos)
    external onlyOwner {
        uint len = lockTypes.length;
        require(len == whos.length, 'Invalid input');
        for (uint i = 0; i < len; i++) {
            LockType lockType = lockTypes[i];
            address who = whos[i];
            Lock memory lock = db.locks[who][uint8(lockType)];
            uint128 amount = lock.balance - uint128(Math.min(lock.balance, lock.claimed));
            delete db.locks[who][uint8(lockType)];
            emit LockRevoked(who, amount, lockType);
        }
    }

    function setTGEdate(uint32 timestamp) external onlyOwner {
        TGEdate = timestamp;
        emit TGEdateSet(timestamp);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    function claim() external {
        require(not(paused), 'Paused');
        uint32 releaseStart = TGEdate;
        require(reached(releaseStart), 'Release not started');
        Lock[LOCK_TYPES] memory userLocks = db.locks[msg.sender];
        uint128 claimableSum = 0;
        for (uint8 i = 0; i < LOCK_TYPES; i++) {
            uint128 claimable = calcualteClaimable(
                calcualteReleased(userLocks[i].balance, releaseStart, db.config[LockType(i)]),
                userLocks[i].claimed
            );
            if (claimable == 0) {
                continue;
            }
            db.locks[msg.sender][i].claimed = userLocks[i].claimed + claimable;
            claimableSum += claimable;
            emit Claimed(msg.sender, claimable, LockType(i));
        }
        require(claimableSum > 0, 'Nothing to claim');
        RDT.safeTransfer(msg.sender, claimableSum);
    }

    function recover(IERC20 token, address to, uint amount) external onlyOwner {
        token.safeTransfer(to, amount);
        emit Recovered(token, to, amount);
    }

    event TGEdateSet(uint timestamp);
    event LockAssigned(address user, uint amount, LockType lockType);
    event LockRevoked(address user, uint amount, LockType lockType);
    event Claimed(address user, uint amount, LockType lockType);
    event Paused();
    event Unpaused();
    event Recovered(IERC20 token, address to, uint amount);
}