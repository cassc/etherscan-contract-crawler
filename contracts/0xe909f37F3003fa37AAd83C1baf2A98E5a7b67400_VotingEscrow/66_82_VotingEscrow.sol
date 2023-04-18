// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

/***
 *@title VotingEscrow
 *@notice Votes have a weight depending on time, so that users are
 *        committed to the future of (whatever they are voting for)
 *@dev Vote weight decays linearly over time. Lock time cannot be
 *     more than `MAXTIME` (4 years).
 */

// Voting escrow to have time-weighted votes
// Votes have a weight depending on time, so that users are committed
// to the future of (whatever they are voting for).
// The weight in this implementation is linear, and lock cannot be more than maxtime
// w ^
// 1 +        /
//   |      /
//   |    /
//   |  /
//   |/
// 0 +--------+------> time
//       maxtime (4 years?)

// Interface for checking whether address belongs to a whitelisted
// type of a smart wallet.
// When new types are added - the whole contract is changed
// The check() method is modifying to be able to use caching
// for individual wallet addresses

//libraries
import {IVotingEscrow} from "./interfaces/IVotingEscrow.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";

/// Interface for checking whether address belongs to a whitelisted
/// type of a smart wallet.
/// When new types are added - the whole contract is changed
/// The check() method is modifying to be able to use caching
/// for individual wallet addresses
interface SmartWalletChecker {
    function check(address _wallet) external view returns (bool);
}

contract VotingEscrow is IVotingEscrow, ReentrancyGuard, Ownable2Step {
    // We cannot really do block numbers per se b/c slope is per time, not per block
    // and per block could be fairly bad b/c Ethereum changes blocktimes.
    // What we can do is to extrapolate ***At functions

    uint256 private constant _DEPOSIT_FOR_TYPE = 0;
    uint256 private constant _CREATE_LOCK_TYPE = 1;
    uint256 private constant _INCREASE_LOCK_AMOUNT = 2;
    uint256 private constant _INCREASE_UNLOCK_TIME = 3;

    uint256 public constant _DAY = 86400; // all future times are rounded by week
    uint256 public constant WEEK = 7 * _DAY; // all future times are rounded by week
    uint256 public constant MAXTIME = 4 * 365 * _DAY; // 4 years
    uint256 public constant MULTIPLIER = 10 ** 18;

    int256 public constant BASE_RATE = 10000;

    /// LT token address
    address public immutable token;
    /// permit2 contract address
    address public permit2Address;
    /// total locked LT value
    uint256 public supply;

    mapping(address => LockedBalance) public locked;

    //everytime user deposit/withdraw/change_locktime, these values will be updated;
    uint256 public override epoch;
    mapping(uint256 => Point) public supplyPointHistory; // epoch -> unsigned point.
    mapping(address => mapping(uint256 => Point)) public userPointHistory; // user -> Point[user_epoch]
    mapping(address => uint256) public userPointEpoch;
    mapping(uint256 => int256) public slopeChanges; // time -> signed slope change

    string public constant NAME = "Vote-escrowed LT";
    string public constant SYMBOL = "veLT";

    uint256 public immutable decimals;
    address public smartWalletChecker;

    constructor(address _tokenAddr, address _permit2Address) {
        require(_permit2Address != address(0), "CE000");

        token = _tokenAddr;
        permit2Address = _permit2Address;
        supplyPointHistory[0] = Point({bias: 0, slope: 0, ts: block.timestamp, blk: block.number});
        uint256 _decimals = IERC20Metadata(_tokenAddr).decimals();
        decimals = _decimals;
    }

    /***
     * @dev Get the user point for checkpoint for `_index` for `_userAddress`
     * @param _userAddress Address of the user wallet
     * @param _index User epoch number
     * @return user Epoch checkpoint
     */
    function getUserPointHistory(address _userAddress, uint256 _index) external view override returns (Point memory) {
        return userPointHistory[_userAddress][_index];
    }

    /***
     * @dev Get the most recently recorded rate of voting power decrease for `_addr`
     * @param _addr Address of the user wallet
     * @return Value of the slope
     */
    function getLastUserSlope(address _addr) external view override returns (int256) {
        uint256 uepoch = userPointEpoch[_addr];
        return userPointHistory[_addr][uepoch].slope;
    }

    /***
     * @dev Get the timestamp for checkpoint `_idx` for `_addr`
     * @param _addr User wallet address
     * @param _idx User epoch number
     * @return Epoch time of the checkpoint
     */
    function userPointHistoryTs(address _addr, uint256 _idx) external view override returns (uint256) {
        return userPointHistory[_addr][_idx].ts;
    }

    /***
     * @dev Get timestamp when `_addr`'s lock finishes
     * @param _addr User wallet
     * @return Epoch time of the lock end
     */
    function lockedEnd(address _addr) external view override returns (uint256) {
        return locked[_addr].end;
    }

    //Struct to avoid "Stack Too Deep"
    struct CheckpointParameters {
        Point userOldPoint;
        Point userNewPoint;
        int256 oldDslope;
        int256 newDslope;
        uint256 epoch;
    }

    /***
     * @dev Record global and per-user data to checkpoint
     * @param _addr User's wallet address. No user checkpoint if 0x0
     * @param _oldLocked Pevious locked amount / end lock time for the user
     * @param _newLocked New locked amount / end lock time for the user
     */
    function _checkpoint(address _addr, LockedBalance memory _oldLocked, LockedBalance memory _newLocked) internal {
        CheckpointParameters memory _st;
        _st.epoch = epoch;

        if (_addr != address(0)) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (_oldLocked.end > block.timestamp && _oldLocked.amount > 0) {
                _st.userOldPoint.slope = _oldLocked.amount / BASE_RATE / int256(MAXTIME);
                _st.userOldPoint.bias = _st.userOldPoint.slope * int256(_oldLocked.end - block.timestamp);
            }
            if (_newLocked.end > block.timestamp && _newLocked.amount > 0) {
                _st.userNewPoint.slope = _newLocked.amount / BASE_RATE / int256(MAXTIME);
                _st.userNewPoint.bias = _st.userNewPoint.slope * int256(_newLocked.end - block.timestamp);
            }

            // Read values of scheduled changes in the slope
            // _oldLocked.end can be in the past and in the future
            // _newLocked.end can ONLY by in the FUTURE unless everything expired than zeros
            _st.oldDslope = slopeChanges[_oldLocked.end];
            if (_newLocked.end != 0) {
                if (_newLocked.end == _oldLocked.end) {
                    _st.newDslope = _st.oldDslope;
                } else {
                    _st.newDslope = slopeChanges[_newLocked.end];
                }
            }
        }

        Point memory _lastPoint = Point({bias: 0, slope: 0, ts: block.timestamp, blk: block.number});
        if (_st.epoch > 0) {
            _lastPoint = supplyPointHistory[_st.epoch];
        }
        uint256 _lastCheckPoint = _lastPoint.ts;
        // _initialLastPoint is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        // Point memory _initialLastPoint = _lastPoint;
        uint256 _initBlk = _lastPoint.blk;
        uint256 _initTs = _lastPoint.ts;

        uint256 _blockSlope = 0; // dblock/dt
        if (block.timestamp > _lastPoint.ts) {
            _blockSlope = (MULTIPLIER * (block.number - _lastPoint.blk)) / (block.timestamp - _lastPoint.ts);
        }
        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        uint256 _ti = (_lastCheckPoint / WEEK) * WEEK;
        for (uint256 i; i < 255; i++) {
            // Hopefully it won't happen that this won't get used in 5 years!
            // If it does, users will be able to withdraw but vote weight will be broken
            _ti += WEEK;
            int256 dSlope = 0;
            if (_ti > block.timestamp) {
                // reach future time, reset to blok time
                _ti = block.timestamp;
            } else {
                dSlope = slopeChanges[_ti];
            }
            _lastPoint.bias = _lastPoint.bias - _lastPoint.slope * int256(_ti - _lastCheckPoint);
            _lastPoint.slope += dSlope;
            if (_lastPoint.bias < 0) {
                // This can happen
                _lastPoint.bias = 0;
            }
            if (_lastPoint.slope < 0) {
                // This cannot happen - just in case
                _lastPoint.slope = 0;
            }
            _lastCheckPoint = _ti;
            _lastPoint.ts = _ti;
            _lastPoint.blk = _initBlk + ((_blockSlope * (_ti - _initTs)) / MULTIPLIER);
            _st.epoch += 1;
            if (_ti == block.timestamp) {
                // history filled over, break loop
                _lastPoint.blk = block.number;
                break;
            } else {
                supplyPointHistory[_st.epoch] = _lastPoint;
            }
        }
        epoch = _st.epoch;
        // Now supplyPointHistory is filled until t=now

        if (_addr != address(0)) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            _lastPoint.slope += _st.userNewPoint.slope - _st.userOldPoint.slope;
            _lastPoint.bias += _st.userNewPoint.bias - _st.userOldPoint.bias;
            if (_lastPoint.slope < 0) {
                _lastPoint.slope = 0;
            }
            if (_lastPoint.bias < 0) {
                _lastPoint.bias = 0;
            }
        }

        // Record the changed point into history
        supplyPointHistory[_st.epoch] = _lastPoint;
        if (_addr != address(0)) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [_newLocked.end]
            // and add old_user_slope to [_oldLocked.end]
            if (_oldLocked.end > block.timestamp) {
                // _oldDslope was <something> - _userOldPoint.slope, so we cancel that
                _st.oldDslope += _st.userOldPoint.slope;
                if (_newLocked.end == _oldLocked.end) {
                    _st.oldDslope -= _st.userNewPoint.slope; // It was a new deposit, not extension
                }
                slopeChanges[_oldLocked.end] = _st.oldDslope;
            }
            if (_newLocked.end > block.timestamp) {
                if (_newLocked.end > _oldLocked.end) {
                    _st.newDslope -= _st.userNewPoint.slope; // old slope disappeared at this point
                    slopeChanges[_newLocked.end] = _st.newDslope;
                }
                // else we recorded it already in _oldDslope
            }

            // Now handle user history
            uint256 _userEpoch = userPointEpoch[_addr] + 1;

            userPointEpoch[_addr] = _userEpoch;
            _st.userNewPoint.ts = block.timestamp;
            _st.userNewPoint.blk = block.number;
            userPointHistory[_addr][_userEpoch] = _st.userNewPoint;
        }
    }

    /***
     * @dev Deposit and lock tokens for a user
     * @param _addr User's wallet address
     * @param _value Amount to deposit
     * @param _unlockTime New time when to unlock the tokens, or 0 if unchanged
     * @param _lockedBalance Previous locked amount / timestamp
     */
    function _depositFor(
        address _provider,
        address _beneficiary,
        uint256 _value,
        uint256 _unlockTime,
        LockedBalance memory _lockedBalance,
        uint256 _type,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) internal {
        LockedBalance memory _locked = LockedBalance(_lockedBalance.amount, _lockedBalance.end);
        LockedBalance memory _oldLocked = LockedBalance(_lockedBalance.amount, _lockedBalance.end);

        uint256 _supplyBefore = supply;
        supply = _supplyBefore + _value;
        //Adding to existing lock, or if a lock is expired - creating a new one
        _locked.amount = _locked.amount + int256(_value);
        if (_unlockTime != 0) {
            _locked.end = _unlockTime;
        }
        locked[_beneficiary] = _locked;

        // Possibilities
        // Both _oldLocked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)
        _checkpoint(_beneficiary, _oldLocked, _locked);
        if (_value != 0) {
            TransferHelper.doTransferIn(permit2Address, token, _value, _provider, nonce, deadline, signature);
        }

        emit Deposit(_provider, _beneficiary, _value, uint256(_locked.amount), _locked.end, _type, block.timestamp);
        emit Supply(_supplyBefore, _supplyBefore + _value);
    }

    /***
     * @notice Record total supply to checkpoint
     */
    function checkpointSupply() public override {
        LockedBalance memory _a;
        LockedBalance memory _b;
        _checkpoint(address(0), _a, _b);
    }

    /**
     * @notice Deposit `_value` tokens for `_beneficiary` and lock until `_unlockTime`
     * @dev only owner can call
     */
    function createLockFor(
        address _beneficiary,
        uint256 _value,
        uint256 _unlockTime,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) external override onlyOwner {
        _createLock(_beneficiary, _value, _unlockTime, nonce, deadline, signature);
    }

    function createLock(uint256 _value, uint256 _unlockTime, uint256 nonce, uint256 deadline, bytes memory signature) external override {
        _assertNotContract(msg.sender);
        _createLock(msg.sender, _value, _unlockTime, nonce, deadline, signature);
    }

    /***
     * @dev Deposit `_value` tokens for `msg.sender` and lock until `_unlockTime`
     * @param _beneficiary
     * @param _value Amount to deposit
     * @param _unlockTime Epoch time when tokens unlock, rounded down to whole weeks
     * @param _
     */
    function _createLock(
        address _beneficiary,
        uint256 _value,
        uint256 _unlockTime,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) internal nonReentrant {
        _unlockTime = (_unlockTime / WEEK) * WEEK; // Locktime is rounded down to weeks
        LockedBalance memory _locked = locked[_beneficiary];

        require(_value > 0, "VE000");
        require(_locked.amount == 0, "VE001");
        //The locking time shall be at least two cycles
        require(_unlockTime > block.timestamp + WEEK, "VE002");
        require(_unlockTime <= block.timestamp + MAXTIME, "VE003");

        _depositFor(msg.sender, _beneficiary, _value, _unlockTime, _locked, _CREATE_LOCK_TYPE, nonce, deadline, signature);
    }

    /**
     * @notice Deposit `_value` additional tokens for `msg.sender` without modifying the unlock time
     * @param _value Amount of tokens to deposit and add to the lock
     */
    function increaseAmount(uint256 _value, uint256 nonce, uint256 deadline, bytes memory signature) external override {
        _assertNotContract(msg.sender);
        _increaseAmount(msg.sender, _value, nonce, deadline, signature);
    }

    /**
     * @notice Deposit `_value` tokens for `_beneficiary` and add to the lock
     * @dev Anyone (even a smart contract) can deposit for someone else, but cannot extend their locktime and deposit for a brand new user
     * @param _beneficiary User's wallet address
     * @param _value Amount to add to user's lock
     */
    function increaseAmountFor(
        address _beneficiary,
        uint256 _value,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) external override {
        _increaseAmount(_beneficiary, _value, nonce, deadline, signature);
    }

    /***
     * @dev Deposit `_value` additional tokens for `msg.sender`
     *        without modifying the unlock time
     * @param _value Amount of tokens to deposit and add to the lock
     */
    function _increaseAmount(
        address _beneficiary,
        uint256 _value,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) internal nonReentrant {
        LockedBalance memory _locked = locked[_beneficiary];

        require(_value > 0, "VE000");
        require(_locked.amount > 0, "VE004");
        require(_locked.end > block.timestamp, "VE005");

        _depositFor(msg.sender, _beneficiary, _value, 0, _locked, _INCREASE_LOCK_AMOUNT, nonce, deadline, signature);
    }

    /***
     * @dev Extend the unlock time for `msg.sender` to `_unlockTime`
     * @param _unlockTime New epoch time for unlocking
     */
    function increaseUnlockTime(uint256 _unlockTime) external override nonReentrant {
        _assertNotContract(msg.sender);
        LockedBalance memory _locked = locked[msg.sender];
        _unlockTime = (_unlockTime / WEEK) * WEEK; // Locktime is rounded down to weeks

        require(_locked.end > block.timestamp, "VE006");
        require(_locked.amount > 0, "VE007");
        require(_unlockTime > _locked.end, "VE008");
        require(_unlockTime <= block.timestamp + MAXTIME, "VE009");

        _depositFor(msg.sender, msg.sender, 0, _unlockTime, _locked, _INCREASE_UNLOCK_TIME, 0, 0, "");
    }

    /***
     * @dev Withdraw all tokens for `msg.sender`
     * @dev Only possible if the lock has expired
     */
    function withdraw() external override nonReentrant {
        LockedBalance memory _locked = LockedBalance(locked[msg.sender].amount, locked[msg.sender].end);

        require(block.timestamp >= _locked.end, "VE010");
        uint256 _value = uint256(_locked.amount);

        LockedBalance memory _oldLocked = LockedBalance(locked[msg.sender].amount, locked[msg.sender].end);

        _locked.end = 0;
        _locked.amount = 0;
        locked[msg.sender] = _locked;
        uint256 _supplyBefore = supply;
        supply = _supplyBefore - _value;

        // _oldLocked can have either expired <= timestamp or zero end
        // _locked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(msg.sender, _oldLocked, _locked);

        TransferHelper.doTransferOut(token, msg.sender, _value);

        emit Withdraw(msg.sender, _value, block.timestamp);
        emit Supply(_supplyBefore, _supplyBefore - _value);
    }

    // The following ERC20/minime-compatible methods are not real balanceOf and supply!
    // They measure the weights for the purpose of voting, so they don't represent
    // real coins.

    /***
     * @dev Binary search to estimate timestamp for block number
     * @param blockNumber Block to find
     * @param maxEpoch Don't go beyond this epoch
     * @return Approximate timestamp for block
     */
    function _findBlockEpoch(uint256 blockNumber, uint256 maxEpoch) internal view returns (uint256) {
        // Binary search
        uint256 _min = 0;
        uint256 _max = maxEpoch;
        for (uint256 i; i <= 128; i++) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (supplyPointHistory[_mid].blk <= blockNumber) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    /***
     * @notice Get the current voting power for `msg.sender`
     * @dev Adheres to the ERC20 `balanceOf` interface for Metamask & Snapshot compatibility
     * @param _addr User wallet address
     * @return User's present voting power
     */
    function balanceOf(address _addr) external view returns (uint256) {
        uint256 _t = block.timestamp;

        uint256 _epoch = userPointEpoch[_addr];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory _lastPoint = userPointHistory[_addr][_epoch];
            unchecked {
                _lastPoint.bias -= _lastPoint.slope * int256(_t - _lastPoint.ts);
            }
            if (_lastPoint.bias < 0) {
                _lastPoint.bias = 0;
            }
            return uint256(_lastPoint.bias);
        }
    }

    /***
     * @notice Get the current voting power for `msg.sender`
     * @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
     * @param _addr User wallet address
     * @param _t Epoch time to return voting power at
     * @return User voting power
     * @dev return the present voting power if _t is 0
     */
    function balanceOfAtTime(address _addr, uint256 _t) external view override returns (uint256) {
        if (_t == 0) {
            _t = block.timestamp;
        }
        uint256 _epoch = userPointEpoch[_addr];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory _lastPoint = userPointHistory[_addr][_epoch];
            require(_t >= _lastPoint.ts, "GC007");
            unchecked {
                _lastPoint.bias -= _lastPoint.slope * int256(_t - _lastPoint.ts);
            }
            if (_lastPoint.bias < 0) {
                _lastPoint.bias = 0;
            }
            return uint256(_lastPoint.bias);
        }
    }

    //Struct to avoid "Stack Too Deep"
    struct Parameters {
        uint256 min;
        uint256 max;
        uint256 maxEpoch;
        uint256 dBlock;
        uint256 dt;
    }

    /***
     * @notice Measure voting power of `_addr` at block height `_block`
     * @dev Adheres to MiniMe `balanceOfAt` interface https//github.com/Giveth/minime
     * @param _addr User's wallet address
     * @param _block Block to calculate the voting power at
     * @return Voting power
     */
    function balanceOfAt(address _addr, uint256 _block) external view returns (uint256) {
        // Copying and pasting totalSupply code because Vyper cannot pass by
        // reference yet
        require(_block <= block.number, "VE011");

        Parameters memory _st;

        // Binary search
        _st.min = 0;
        _st.max = userPointEpoch[_addr];

        for (uint256 i; i <= 128; i++) {
            // Will be always enough for 128-bit numbers
            if (_st.min >= _st.max) {
                break;
            }
            uint256 _mid = (_st.min + _st.max + 1) / 2;
            if (userPointHistory[_addr][_mid].blk <= _block) {
                _st.min = _mid;
            } else {
                _st.max = _mid - 1;
            }
        }
        Point memory _upoint = userPointHistory[_addr][_st.min];

        _st.maxEpoch = epoch;
        uint256 _epoch = _findBlockEpoch(_block, _st.maxEpoch);
        Point memory _point = supplyPointHistory[_epoch];
        _st.dBlock = 0;
        _st.dt = 0;
        if (_epoch < _st.maxEpoch) {
            Point memory _point1 = supplyPointHistory[_epoch + 1];
            _st.dBlock = _point1.blk - _point.blk;
            _st.dt = _point1.ts - _point.ts;
        } else {
            _st.dBlock = block.number - _point.blk;
            _st.dt = block.timestamp - _point.ts;
        }
        uint256 blockTime = _point.ts;
        if (_st.dBlock != 0) {
            blockTime += (_st.dt * (_block - _point.blk)) / _st.dBlock;
        }

        unchecked {
            _upoint.bias -= _upoint.slope * int256(blockTime - _upoint.ts);
        }
        if (_upoint.bias >= 0) {
            return uint256(_upoint.bias);
        } else {
            return 0;
        }
    }

    /***
     * @dev Calculate total voting power at some point in the past
     * @param point The point (bias/slope) to start search from
     * @param t Time to calculate the total voting power at
     * @return Total voting power at that time
     */
    function _supplyAt(Point memory point, uint256 t) internal view returns (uint256) {
        require(t >= point.ts, "GC007");
        Point memory _lastPoint = point;
        uint256 _ti = (_lastPoint.ts / WEEK) * WEEK;
        for (uint256 i; i < 255; i++) {
            _ti += WEEK;
            int256 dSlope = 0;

            if (_ti > t) {
                _ti = t;
            } else {
                dSlope = slopeChanges[_ti];
            }
            unchecked {
                _lastPoint.bias -= _lastPoint.slope * int256(_ti - _lastPoint.ts);
            }
            if (_ti == t) {
                break;
            }
            _lastPoint.slope += dSlope;
            _lastPoint.ts = _ti;
        }

        if (_lastPoint.bias < 0) {
            _lastPoint.bias = 0;
        }
        return uint256(_lastPoint.bias);
    }

    /***
     * @notice Calculate total voting power
     * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     * @return Total voting power
     */
    function totalSupply() external view override returns (uint256) {
        uint256 _epoch = epoch;
        Point memory _lastPoint = supplyPointHistory[_epoch];

        return _supplyAt(_lastPoint, block.timestamp);
    }

    /***
     * @notice Calculate total voting power
     * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     * @return Total voting power
     */
    function totalSupplyAtTime(uint256 _t) external view override returns (uint256) {
        if (_t == 0) {
            _t = block.timestamp;
        }

        uint256 _epoch = epoch;
        Point memory _lastPoint = supplyPointHistory[_epoch];

        return _supplyAt(_lastPoint, _t);
    }

    /***
     * @notice Calculate total voting power at some point in the past
     * @param _block Block to calculate the total voting power at
     * @return Total voting power at `_block`
     */
    function totalSupplyAt(uint256 _block) external view returns (uint256) {
        require(_block <= block.number, "VE011");
        uint256 _epoch = epoch;
        uint256 _targetEpoch = _findBlockEpoch(_block, _epoch);

        Point memory _point = supplyPointHistory[_targetEpoch];
        uint256 dt = 0;
        if (_targetEpoch < _epoch) {
            Point memory _pointNext = supplyPointHistory[_targetEpoch + 1];
            if (_point.blk != _pointNext.blk) {
                dt = ((_block - _point.blk) * (_pointNext.ts - _point.ts)) / (_pointNext.blk - _point.blk);
            }
        } else {
            if (_point.blk != block.number) {
                dt = ((_block - _point.blk) * (block.timestamp - _point.ts)) / (block.number - _point.blk);
            }
        }
        // Now dt contains info on how far are we beyond point

        return _supplyAt(_point, _point.ts + dt);
    }

    /**
     * @notice Set an external contract to check for approved smart contract wallets
     * @param _check  Address of Smart contract checker
     */
    function setSmartWalletChecker(address _check) external onlyOwner {
        address oldChecker = smartWalletChecker;
        smartWalletChecker = _check;
        emit SetSmartWalletChecker(msg.sender, _check, oldChecker);
    }

    /**
     * @dev Set permit2 address, onlyOwner
     * @param newAddress New permit2 address
     */
    function setPermit2Address(address newAddress) external onlyOwner {
        require(newAddress != address(0), "CE000");
        address oldAddress = permit2Address;
        permit2Address = newAddress;
        emit SetPermit2Address(oldAddress, newAddress);
    }

    /**
     * @notice Check if the call is from a whitelisted smart contract, revert if not
     * @param addr Address to be checked
     */
    function _assertNotContract(address addr) internal view {
        if (addr != tx.origin) {
            if (smartWalletChecker != address(0)) {
                if (SmartWalletChecker(smartWalletChecker).check(addr)) {
                    return;
                }
            }
            revert("Smart contract depositors not allowed");
        }
    }
}