// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;



import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

import "./IVEGoMiningToken.sol";
import "./IGoMiningToken.sol";

/// @title Voting Escrow GoMiningToken
/// @notice Cooldown logic is added in the contract
/// @notice Make contract upgradeable
/// @notice This is a Solidity implementation of the CURVE's voting escrow.
/// @notice Votes have a weight depending on time, so that users are
///         committed to the future of (whatever they are voting for)
/// @dev Vote weight decays linearly over time. Lock time cannot be
///  more than `MAX_TIME` (4 years).

/**
# Voting escrow to have time-weighted votes
# w ^
# 1 +        /
#   |      /
#   |    /
#   |  /
#   |/
# 0 +--------+------> time
#       maxtime (4 years?)
*/

contract VEGoMiningTokenV4 is IVEGoMiningToken, PausableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IGoMiningToken;
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for int256;
    using SafeCastUpgradeable for uint256;
    using SafeCastUpgradeable for int256;

    uint256 public constant WEEK = 1 weeks;
    uint256 public constant MAX_TIME = 4 * 365 days;
    uint256 public constant MULTIPLIER = 10 ** 18;

    struct Point {
        int128 bias; // veToken value at this point
        int128 slope; // slope at this point
        uint256 ts; // timestamp of this point
        uint256 blk; // block number of this point
    }

    struct LockedBalance {
        int128 amount; // amount of Token locked for a user.
        uint256 end; // the expiry time of the deposit.
    }

    enum ActionType {
        DEPOSIT_FOR,
        CREATE_LOCK,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME
    }

    event Deposit(
        address indexed provider,
        uint256 value,
        uint256 indexed lockTime,
        ActionType depositType,
        uint256 ts
    );

    event Withdraw(
        address indexed provider,
        uint256 value,
        uint256 ts
    );

    event Supply(
        uint256 prevSupply,
        uint256 supply
    );

    IGoMiningToken public Token;
    uint256 public supply;


    uint256 public epoch;
    mapping(uint256 => Point) public pointHistory; // epoch -> unsigned point
    mapping(uint256 => int128) public slopeChanges; // time -> signed slope change

    mapping(address => LockedBalance) public locked;
    mapping(address => mapping(uint256 => Point)) public userPointHistory; // user -> point[userEpoch]
    mapping(address => uint256) public override userPointEpoch;

    // veToken token related
    string public name;
    string public symbol;
    uint8 public decimals;
    string public version;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");




    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // @notice Get the most recently recorded rate of voting power decrease for `addr`
    // @param addr Address of the user wallet
    // @return Value of the slope
    function getLastUserSlope(address addr) external view override returns (int128) {
        uint256 uEpoch = userPointEpoch[addr];
        return userPointHistory[addr][uEpoch].slope;
    }

    // @notice Get the timestamp for checkpoint `idx` for `addr`
    // @param addr User wallet address
    // @param idx User epoch number
    function userPointHistoryAt(address addr, uint256 idx) external view override returns (uint256) {
        return userPointHistory[addr][idx].ts;
    }

    // @notice Get timestamp when `_addr`'s lock finishes
    // @param _addr User wallet
    // @return Epoch time of the lock end
    function lockedEnd(address addr) external view override returns (uint256) {
        return locked[addr].end;
    }

    // @notice Record global and per-user data to checkpoint
    // @param addr User's wallet address. No user checkpoint if 0x0
    // @param oldLocked Previous locked amount / end lock time for the user
    // @param newLocked New locked amount / end lock time for the user
    function _checkpoint(address addr, LockedBalance memory oldLocked, LockedBalance memory newLocked) internal {
        Point memory uOld = Point(0, 0, 0, 0);
        Point memory uNew = Point(0, 0, 0, 0);
        int128 dSlopeOld;
        int128 dSlopeNew;
        uint256 _epoch = epoch;

        if (addr != address(0)) {
            // Calculate slopes and biases
            // Kept at zero when they have to

            if (oldLocked.end > block.timestamp && oldLocked.amount > 0) {
                uOld.slope = oldLocked.amount / safeConvertUint256ToInt128(MAX_TIME);
                uOld.bias = uOld.slope * safeConvertUint256ToInt128(oldLocked.end - block.timestamp);
            }
            if (newLocked.end > block.timestamp && newLocked.amount > 0) {
                uNew.slope = newLocked.amount / safeConvertUint256ToInt128(MAX_TIME);
                uNew.bias = uNew.slope * safeConvertUint256ToInt128(newLocked.end - block.timestamp);
            }

            // Read values of scheduled changes in the slope
            // oldLocked.end can be in the past and in the future
            // newLocked.end can ONLY by in the FUTURE unless everything expired: than zeros
            dSlopeOld = slopeChanges[oldLocked.end];

            if (newLocked.end != 0) {
                if (newLocked.end == oldLocked.end) {
                    dSlopeNew = dSlopeOld;
                } else {
                    dSlopeNew = slopeChanges[newLocked.end];
                }
            }
        }

        Point memory lastPoint = Point(0, 0, block.timestamp, block.number);

        if (_epoch > 0) {
            lastPoint = pointHistory[_epoch];
        }

        uint256 lastCheckpoint = lastPoint.ts;

        // initialLastPoint is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        Point memory initialLastPoint = Point(lastPoint.bias, lastPoint.slope, lastPoint.ts, lastPoint.blk);
        uint256 blockSlope; // dblock/dt

        if (block.timestamp > lastPoint.ts) {
            blockSlope = MULTIPLIER * (block.number - lastPoint.blk) / (block.timestamp - lastPoint.ts);
        }
        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        uint256 ti = (lastCheckpoint / WEEK) * WEEK; // ts at end of week.

        for (uint256 i = 0; i < 255; i++) {
            // Hopefully it won't happen that this won't get used in 5 years!
            // If it does, users will be able to withdraw but vote weight will be broken
            ti += WEEK;
            int128 dSlope;
            if (ti > block.timestamp) {
                ti = block.timestamp;
            } else {
                dSlope = slopeChanges[ti];
            }
            lastPoint.bias -= lastPoint.slope * safeConvertUint256ToInt128(ti - lastCheckpoint);
            lastPoint.slope += dSlope;
            if (lastPoint.bias < 0) {// This can happen
                lastPoint.bias = 0;
            }
            if (lastPoint.slope < 0) {// This cannot happen - just in case
                lastPoint.slope = 0;
            }
            lastCheckpoint = ti;
            lastPoint.ts = ti;
            lastPoint.blk = initialLastPoint.blk + blockSlope * (ti - initialLastPoint.ts) / MULTIPLIER;
            _epoch += 1;
            if (ti == block.timestamp) {
                lastPoint.blk = block.number;
                break;
            } else {
                pointHistory[_epoch] = lastPoint;
            }
        }

        epoch = _epoch;
        // Now point_history is filled until t=now

        if (addr != address(0)) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            lastPoint.slope += (uNew.slope - uOld.slope);
            lastPoint.bias += (uNew.bias - uOld.bias);
            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
        }

        // Record the changed point into history
        pointHistory[_epoch] = lastPoint;


        if (addr != address(0)) {
            // Schedule the slope changes (slope is going down)
            // We subtract newUserSlope from [newLocked.end]
            // and add oldUserSlope to [oldLocked.end]
            if (oldLocked.end > block.timestamp) {
                // dSlopeOld was <something> - uOld.slope, so we cancel that
                dSlopeOld += uOld.slope;

                if (newLocked.end == oldLocked.end) {
                    // It was a new deposit, not extension
                    dSlopeOld -= uNew.slope;
                }
                slopeChanges[oldLocked.end] = dSlopeOld;
            }


            if (newLocked.end > block.timestamp) {
                if (newLocked.end > oldLocked.end) {
                    dSlopeNew -= uNew.slope; // old slope disappeared at this point
                    slopeChanges[newLocked.end] = dSlopeNew;
                }
                // else: we recorded it already in dSlopeOld
            }

            // Now handle user history
            uint256 uEpoch = userPointEpoch[addr] + 1;

            uNew.ts = block.timestamp;
            uNew.blk = block.number;
            _setUserPoints(addr, uEpoch, uNew);
        }

    }

    function _setUserPoints(address addr, uint256 uEpoch, Point memory point) internal {
        userPointEpoch[addr] = uEpoch;
        userPointHistory[addr][uEpoch] = point;
    }

    // @notice Deposit and lock tokens for a user
    // @param _addr User's wallet address
    // @param _value Amount to deposit
    // @param unlock_time New time when to unlock the tokens, or 0 if unchanged
    // @param locked_balance Previous locked amount / timestamp
    function _depositFor(address addr, uint256 value, uint256 unlockTime, LockedBalance memory lockedBalance, ActionType _type) internal {
        LockedBalance memory _locked = LockedBalance(lockedBalance.amount, lockedBalance.end);
        uint256 supplyBefore = supply;
        supply = supplyBefore + value;
        LockedBalance memory oldLocked = lockedBalance;
        // Adding to existing lock, or if a lock is expired - creating a new one
        _locked.amount += safeConvertUint256ToInt128(value);
        if (unlockTime != 0) {
            _locked.end = unlockTime;
        }
        locked[addr] = _locked;

        // Possibilities:
        // Both oldLocked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)
        _checkpoint(addr, oldLocked, _locked);

        if (value != 0) {
            require(Token.transferFrom(addr, address(this), value), "ve: token transfer failed");
        }

        emit Deposit(addr, value, _locked.end, _type, block.timestamp);
        emit Supply(supplyBefore, supply);
    }

    // @notice Record global data to checkpoint
    function checkpoint() external override whenNotPaused {
        _checkpoint(address(0), LockedBalance(0, 0), LockedBalance(0, 0));
    }

    // @notice Deposit `_value` tokens for `_addr` and add to the lock
    // @dev Anyone (even a smart contract) can deposit for someone else, but
    //cannot extend their locktime and deposit for a brand new user
    // @param _addr User's wallet address
    // @param _value Amount to add to user's lock
    function depositFor(address addr, uint256 value) external override nonReentrant whenNotPaused {
        LockedBalance memory _locked = locked[addr];
        require(value > 0, "ve: dev: need non-zero value");
        require(_locked.amount > 0, "ve: No existing lock found");
        require(_locked.end > block.timestamp, "ve: Cannot add to expired lock. Withdraw");

        _depositFor(addr, value, 0, locked[addr], ActionType.DEPOSIT_FOR);
    }

    // @notice Deposit `_value` tokens for `_msgSender()` and lock until `_unlockTime`
    // @param _value Amount to deposit
    // @param _unlockTime Epoch time when tokens unlock, rounded down to whole weeks
    function createLock(uint256 value, uint256 _unlockTime) external override nonReentrant whenNotPaused {

        uint256 unlockTime = (_unlockTime / WEEK) * WEEK;
        // Locktime is rounded down to weeks
        LockedBalance memory _locked = locked[_msgSender()];

        require(value > 0, "ve: dev: need non-zero value");
        require(_locked.amount == 0, "ve: Withdraw old tokens first");
        require(unlockTime > block.timestamp, "ve: Can only lock until time in the future");
        require(unlockTime <= block.timestamp + MAX_TIME, "ve: Voting lock can be 4 years max");

        _depositFor(_msgSender(), value, unlockTime, _locked, ActionType.CREATE_LOCK);
    }

    // @notice Deposit `_value` additional tokens for `_msgSender()`
    //without modifying the unlock time
    // @param _value Amount of tokens to deposit and add to the lock
    function increaseAmount(uint256 value) external override nonReentrant whenNotPaused {
        LockedBalance memory _locked = locked[_msgSender()];

        require(value > 0, "ve: dev: need non-zero value");
        require(_locked.amount > 0, "ve: No existing lock found");
        require(_locked.end > block.timestamp, "ve: Cannot add to expired lock. Withdraw");

        _depositFor(_msgSender(), value, 0, _locked, ActionType.INCREASE_LOCK_AMOUNT);
    }

    // @notice Extend the unlock time for `_msgSender()` to `_unlock_time`
    // @param _unlock_time New epoch time for unlocking
    function increaseUnlockTime(uint256 _unlockTime) external override nonReentrant whenNotPaused {
        // TODO self.assert_not_contract(_msgSender())
        LockedBalance memory _locked = locked[_msgSender()];
        uint256 unlockTime = (_unlockTime / WEEK) * WEEK;
        // Locktime is rounded down to weeks


        require(_locked.end > block.timestamp, "ve: Lock expired");
        require(_locked.amount > 0, "ve: Nothing is locked");
        require(unlockTime > _locked.end, "ve: Can only increase lock duration");
        require(unlockTime <= block.timestamp + MAX_TIME, "ve: Voting lock can be 4 years max");

        _depositFor(_msgSender(), 0, unlockTime, _locked, ActionType.INCREASE_UNLOCK_TIME);
    }

    // @notice Withdraw all tokens for `_msgSender()`
    // @dev Only possible if the lock has expired
    function withdraw() external override nonReentrant {
        LockedBalance memory _locked = locked[_msgSender()];
        require(block.timestamp >= _locked.end, "ve: The lock didn't expire");
        uint256 value = uint256(int256(_locked.amount));

        LockedBalance memory oldLocked = LockedBalance(_locked.amount, _locked.end);
        _locked.end = 0;
        _locked.amount = 0;
        locked[_msgSender()] = _locked;
        uint256 supplyBefore = supply;
        supply = supplyBefore - value;

        // old_locked can have either expired <= timestamp or zero end
        // _locked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(_msgSender(), oldLocked, _locked);

        require(Token.transfer(_msgSender(), value), "ve: token transfer failed");
        emit Withdraw(_msgSender(), value, block.timestamp);

        // not supply(!)
        emit Supply(supplyBefore, supplyBefore - value);
    }

    // The following ERC20/minime-compatible methods are not real balanceOf and supply!
    // They measure the weights for the purpose of voting, so they don't represent
    // real coins.

    // @notice Binary search to estimate timestamp for block number
    // @param _block Block to find
    // @param max_epoch Don't go beyond this epoch
    // @return Approximate timestamp for block
    function findBlockEpoch(uint256 _block, uint256 maxEpoch) internal view returns (uint256) {
        // Binary search
        uint256 _min;
        uint256 _max = maxEpoch;
        for (uint256 i = 0; i < 128; i++) {// Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (pointHistory[_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    // @notice Get the current voting power for `_msgSender()`
    // @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
    // @param addr User wallet address
    // @param _t Epoch time to return voting power at
    // @return User voting power
    function balanceOf(address addr, uint256 _t) public view override returns (uint256) {
        uint256 _epoch = userPointEpoch[addr];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory lastPoint = userPointHistory[addr][_epoch];
            lastPoint.bias -= lastPoint.slope * safeConvertUint256ToInt128(_t - lastPoint.ts);
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
            return uint256(int256(lastPoint.bias));
        }
    }

    function balanceOf(address addr) public view override returns (uint256) {
        return balanceOf(addr, block.timestamp);
    }

    // @notice Measure voting power of `addr` at block height `_block`
    // @param addr User's wallet address
    // @param _block Block to calculate the voting power at
    // @return Voting power

    function balanceOfAt(address addr, uint256 _block) public view override returns (uint256) {
        // Copying and pasting totalSupply code because Vyper cannot pass by
        // reference yet
        require(_block <= block.number, "ve: block not yet mined");
        //# Binary search
        uint256 _min;
        uint256 _max = userPointEpoch[addr];

        for (uint256 i = 0; i < 128; i++) {// Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (userPointHistory[addr][_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        Point memory uPoint = userPointHistory[addr][_min];

        uint256 maxEpoch = epoch;
        uint256 _epoch = findBlockEpoch(_block, maxEpoch);
        Point memory point0 = pointHistory[_epoch];
        uint256 dBlock;
        uint256 dT;

        if (_epoch < maxEpoch) {
            Point memory point1 = pointHistory[_epoch + 1];
            dBlock = point1.blk - point0.blk;
            dT = point1.ts - point0.ts;
        } else {
            dBlock = block.number - point0.blk;
            dT = block.timestamp - point0.ts;
        }

        uint256 blockTime = point0.ts;
        if (dBlock != 0) {
            blockTime += dT * (_block - point0.blk) / dBlock;
        }

        uPoint.bias -= uPoint.slope * safeConvertUint256ToInt128(blockTime - uPoint.ts);

        if (uPoint.bias >= 0) {
            return uint256(int256(uPoint.bias));
        } else {
            return 0;
        }
    }

    // @notice Calculate total voting power at some point in the past
    // @param point The point (bias/slope) to start search from
    // @param t Time to calculate the total voting power at
    // @return Total voting power at that time
    function supplyAt(Point memory point, uint256 t) internal view returns (uint256) {
        Point memory lastPoint = point;
        uint256 ti = (lastPoint.ts / WEEK) * WEEK;
        for (uint256 i = 0; i < 255; i++) {
            ti += WEEK;
            int128 dSlope;
            if (ti > t) {
                ti = t;
            } else {
                dSlope = slopeChanges[ti];
            }
            lastPoint.bias -= lastPoint.slope * safeConvertUint256ToInt128(ti - lastPoint.ts);
            if (ti == t) {
                break;
            }
            lastPoint.slope += dSlope;
            lastPoint.ts = ti;
        }
        if (lastPoint.bias < 0) {
            lastPoint.bias = 0;
        }
        return uint256(int256(lastPoint.bias));
    }

    // @notice Calculate total voting power
    // @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
    // @return Total voting power
    function totalSupply() public view override returns (uint256) {
        uint256 _epoch = epoch;
        Point memory lastPoint = pointHistory[_epoch];
        return supplyAt(lastPoint, block.timestamp);
    }

    // @notice Calculate total voting power at `t`
    // @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
    // @return Total voting power
    function totalSupply(uint256 t) public view override returns (uint256) {
        uint256 _epoch = epoch;
        Point memory lastPoint = pointHistory[_epoch];
        return supplyAt(lastPoint, t);
    }

    // @notice Calculate future 4 years
    // @return array of totalSupply for 4 years period
    function futureTotalSupply() external view returns (uint256, int128[] memory) {
        int128[] memory values = new int128[](255);

        uint256 _epoch = epoch;
        Point memory lastPoint = pointHistory[_epoch];

        uint256 ti = (lastPoint.ts / WEEK) * WEEK;
        uint256 start = ti + WEEK;

        for (uint256 i = 0; i < 255; i++) {
            ti += WEEK;
            int128 dSlope;

            dSlope = slopeChanges[ti];
            lastPoint.bias -= lastPoint.slope * safeConvertUint256ToInt128(ti - lastPoint.ts);
            values[i] = lastPoint.bias;


            if (lastPoint.bias < 0) {
                break;
            }
            lastPoint.slope += dSlope;
            lastPoint.ts = ti;
        }

        return (start, values);
    }

    // @notice Calculate total voting power at some point in the past
    // @param _block Block to calculate the total voting power at
    // @return Total voting power at `_block`
    function totalSupplyAt(uint256 _block) public view override returns (uint256) {
        require(_block <= block.number, "ve: block not yet mined");
        uint256 _epoch = epoch;
        uint256 targetEpoch = findBlockEpoch(_block, _epoch);
        Point memory point = pointHistory[targetEpoch];
        uint256 dt;
        if (targetEpoch < _epoch) {
            Point memory pointNext = pointHistory[targetEpoch + 1];
            if (point.blk != pointNext.blk) {
                dt = (_block - point.blk) * (pointNext.ts - point.ts) / (pointNext.blk - point.blk);
            } else {
                if (point.blk != block.number) {
                    dt = (_block - point.blk) * (block.timestamp - point.ts) / (block.number - point.blk);
                }
            }
        }
        return supplyAt(point, point.ts + dt);
    }


    // @notice Math utils to convert
    function safeConvertUint256ToInt128(uint256 value) internal pure returns (int128) {
        int256 convertedValue = value.toInt256();
        require(convertedValue >= type(int128).min && convertedValue <= type(int128).max, "Value out of range for int128");
        return int128(convertedValue);
    }

    function _authorizeUpgrade(address newImplementation) internal onlyRole(UPGRADER_ROLE) override {

    }
}