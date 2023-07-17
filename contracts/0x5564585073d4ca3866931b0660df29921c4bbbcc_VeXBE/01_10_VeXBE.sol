pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

import "./interfaces/ILockSubscription.sol";

// @title Voting Escrow XBE
// @author Curve Finance | Translation to Solidity - Integral Team O
// @license MIT
// @notice Votes have a weight depending on time, so that users are
//         committed to the future of (whatever they are voting for)
// @dev Vote weight decays linearly over time. Lock time cannot be
//     more than `MAXTIME` (2 years).
contract VeXBE is Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // # Voting escrow to have time-weighted votes
    // # Votes have a weight depending on time, so that users are committed
    // # to the future of (whatever they are voting for).
    // # The weight in this implementation is linear, and lock cannot be more than maxtime:
    // # w ^
    // # 1 +        /
    // #   |      /
    // #   |    /
    // #   |  /
    // #   |/
    // # 0 +--------+------> time
    // #       maxtime (2 years?)

    struct Point {
        int128 bias;
        int128 slope; // - dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    event CommitOwnership(address admin);
    event ApplyOwnership(address admin);
    event Deposit(
        address indexed provider,
        uint256 value,
        uint256 indexed locktime,
        int128 _type,
        uint256 ts
    );
    event Withdraw(address indexed provider, uint256 value, uint256 ts);
    event Supply(uint256 prevSupply, uint256 supply);

    int128 public constant DEPOSIT_FOR_TYPE = 0;
    int128 public constant CREATE_LOCK_TYPE = 1;
    int128 public constant INCREASE_LOCK_AMOUNT = 2;
    int128 public constant INCREASE_UNLOCK_TIME = 3;

    // General constants
    uint256 public constant YEAR = 86400 * 365;
    uint256 public constant WEEK = 7 * 86400; // all future times are rounded by week
    uint256 public constant MAXTIME = 100 * WEEK; // 2 years (23.333 Months)
    uint256 public constant MULTIPLIER = 10**18;

    uint256 public supply;

    mapping(address => LockedBalance) public locked;
    mapping(address => uint256) internal _lockStarts;

    uint256 public epoch;
    mapping(uint256 => Point) public pointHistory; // epoch -> unsigned point /*Point[100000000000000000000000000000]*/

    // Point[1000000000]
    mapping(address => mapping(uint256 => Point)) public userPointHistory; // user -> Point[user_epoch]

    mapping(address => uint256) public userPointEpoch;
    mapping(uint256 => int128) public slopeChanges; // time -> signed slope change

    address public votingStakingRewards;
    ILockSubscription public registrationMediator;

    address public controller;

    string public name;
    string public symbol;
    string public version;
    uint256 public decimals;

    address public admin;
    address public futureAdmin;

    uint256 public minLockDuration;

    mapping(address => mapping(address => bool)) public createLockAllowance;

    modifier onlyAdmin() {
        require(msg.sender == admin, "!admin");
        _;
    }

    // """
    // @notice Contract constructor
    // @param token_addr `ERC20CRV` token address
    // @param _name Token name
    // @param _symbol Token symbol
    // @param _version Contract version - required for Aragon compatibility
    // """
    function configure(
        address tokenAddr,
        address _votingStakingRewards,
        address _registrationMediator,
        uint256 _minLockDuration,
        string calldata _name,
        string calldata _symbol,
        string calldata _version
    ) external initializer {
        admin = msg.sender;
        pointHistory[0].blk = block.number;
        pointHistory[0].ts = block.timestamp;
        controller = msg.sender;
        uint256 _decimals = ERC20(tokenAddr).decimals();
        require(_decimals <= 255, "decimalsOverflow");
        decimals = _decimals;
        name = _name;
        symbol = _symbol;
        version = _version;
        votingStakingRewards = _votingStakingRewards;
        registrationMediator = ILockSubscription(_registrationMediator);

        _setMinLockDuration(_minLockDuration);
    }

    function _setMinLockDuration(uint256 _minLockDuration) private {
        require(_minLockDuration < MAXTIME, "!badMinLockDuration");
        minLockDuration = _minLockDuration;
    }

    function setMinLockDuration(uint256 _minLockDuration) external onlyAdmin {
        _setMinLockDuration(_minLockDuration);
    }

    function setVoting(address _votingStakingRewards) external onlyAdmin {
        require(_votingStakingRewards != address(0), "addressIsZero");
        votingStakingRewards = _votingStakingRewards;
    }

    // """
    // @notice Transfer ownership of VotingEscrow contract to `addr`
    // @param addr Address to have ownership transferred to
    // """
    function commitTransferOwnership(address addr) external onlyAdmin {
        futureAdmin = addr;
        emit CommitOwnership(addr);
    }

    // """
    // @notice Apply ownership transfer
    // """
    function applyTransferOwnership() external onlyAdmin {
        address _admin = futureAdmin;
        require(_admin != address(0), "adminIsZero");
        admin = _admin;
        emit ApplyOwnership(_admin);
    }

    // """
    // @notice Get the most recently recorded rate of voting power decrease for `addr`
    // @param addr Address of the user wallet
    // @return Value of the slope
    // """
    function getLastUserSlope(address addr) external view returns (int128) {
        uint256 uepoch = userPointEpoch[addr];
        return userPointHistory[addr][uepoch].slope;
    }

    // """
    // @notice Get the timestamp for checkpoint `_idx` for `_addr`
    // @param _addr User wallet address
    // @param _idx User epoch number
    // @return Epoch time of the checkpoint
    // """
    function userPointHistoryTs(address addr, uint256 idx)
        external
        view
        returns (uint256)
    {
        return userPointHistory[addr][idx].ts;
    }

    // """
    // @notice Get timestamp when `_addr`'s lock finishes
    // @param _addr User wallet
    // @return Epoch time of the lock end
    // """
    function lockedEnd(address addr) external view returns (uint256) {
        return locked[addr].end;
    }

    function lockStarts(address addr) external view returns (uint256) {
        return _lockStarts[addr];
    }

    function lockedAmount(address addr) external view returns (uint256) {
        return uint256(locked[addr].amount);
    }

    // """
    // @notice Record global and per-user data to checkpoint
    // @param addr User's wallet address. No user checkpoint if 0x0
    // @param old_locked Pevious locked amount / end lock time for the user
    // @param new_locked New locked amount / end lock time for the user
    // """
    function _checkpoint(
        address addr,
        LockedBalance memory oldLocked,
        LockedBalance memory newLocked
    ) internal {
        Point memory uOld;
        Point memory uNew;
        int128 oldDSlope = 0;
        int128 newDSlope = 0;
        // uint256 _epoch = epoch;

        if (addr != address(0)) {
            // # Calculate slopes and biases
            // # Kept at zero when they have to
            if (oldLocked.end > block.timestamp && oldLocked.amount > 0) {
                uOld.slope = int128(uint256(oldLocked.amount) / MAXTIME);
                uOld.bias =
                    uOld.slope *
                    int128(oldLocked.end - block.timestamp);
            }
            if (newLocked.end > block.timestamp && newLocked.amount > 0) {
                uNew.slope = int128(uint256(newLocked.amount) / MAXTIME);
                uNew.bias =
                    uNew.slope *
                    int128(newLocked.end - block.timestamp);
            }

            // # Read values of scheduled changes in the slope
            // # old_locked.end can be in the past and in the future
            // # new_locked.end can ONLY by in the FUTURE unless everything expired: than zeros
            oldDSlope = slopeChanges[oldLocked.end];
            if (newLocked.end != 0) {
                if (newLocked.end == oldLocked.end) {
                    newDSlope = oldDSlope;
                } else {
                    newDSlope = slopeChanges[newLocked.end];
                }
            }
        }
        Point memory lastPoint = Point({
            bias: 0,
            slope: 0,
            ts: block.timestamp,
            blk: block.number
        });
        if (
            epoch > 0 /*_epoch*/
        ) {
            lastPoint = pointHistory[
                epoch /*_epoch*/
            ];
        }
        // uint256 lastCheckpoint = lastPoint.ts;

        // # initial_last_point is used for extrapolation to calculate block number
        // # (approximately, for *At methods) and save them
        // # as we cannot figure that out exactly from inside the contract

        Point memory initialLastPoint = lastPoint;
        uint256 blockSlope = 0;
        if (block.timestamp > lastPoint.ts) {
            blockSlope =
                (MULTIPLIER * (block.number - lastPoint.blk)) /
                (block.timestamp - lastPoint.ts);
        }

        // # If last point is already recorded in this block, slope=0
        // # But that's ok b/c we know the block in such case
        //
        // # Go over weeks to fill history and calculate what the current point is
        uint256 tI = (lastPoint.ts / WEEK) * WEEK; /*lastCheckpoint*/

        for (uint256 i = 0; i < 255; i++) {
            // # Hopefully it won't happen that this won't get used in 5 years!
            // # If it does, users will be able to withdraw but vote weight will be broken
            tI += WEEK;
            int128 dSlope = 0;

            if (tI > block.timestamp) {
                tI = block.timestamp;
            } else {
                dSlope = slopeChanges[tI];
            }

            lastPoint.bias -=
                lastPoint.slope *
                int128(
                    tI - lastPoint.ts /*lastCheckpoint*/
                );
            lastPoint.slope += dSlope;

            if (lastPoint.bias < 0) {
                // # This can happen
                lastPoint.bias = 0;
            }

            if (lastPoint.slope < 0) {
                // # This cannot happen - just in case
                lastPoint.slope = 0;
            }

            // lastCheckpoint = tI;
            lastPoint.ts = tI;
            lastPoint.blk =
                initialLastPoint.blk +
                (blockSlope * (tI - initialLastPoint.ts)) /
                MULTIPLIER;
            epoch += 1; /*_epoch*/

            if (tI == block.timestamp) {
                lastPoint.blk = block.number;
                break;
            } else {
                pointHistory[
                    epoch /*_epoch*/
                ] = lastPoint;
            }
        }

        // epoch = _epoch;
        // # Now point_history is filled until t=now

        if (addr != address(0)) {
            // # If last point was in this block, the slope change has been applied already
            // # But in such case we have 0 slope(s)
            lastPoint.slope += (uNew.slope - uOld.slope);
            lastPoint.bias += (uNew.bias - uOld.bias);
            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
        }

        // # Record the changed point into history
        pointHistory[
            epoch /*_epoch*/
        ] = lastPoint;

        if (addr != address(0)) {
            // # Schedule the slope changes (slope is going down)
            // # We subtract new_user_slope from [new_locked.end]
            // # and add old_user_slope to [old_locked.end]
            if (oldLocked.end > block.timestamp) {
                // # old_dslope was <something> - u_old.slope, so we cancel that
                oldDSlope += uOld.slope;
                if (newLocked.end == oldLocked.end) {
                    oldDSlope -= uNew.slope;
                }
                slopeChanges[oldLocked.end] = oldDSlope;
            }
            if (newLocked.end > block.timestamp) {
                if (newLocked.end > oldLocked.end) {
                    newDSlope -= uNew.slope;
                    slopeChanges[newLocked.end] = newDSlope;
                }
                // else: we recorded it already in old_dslope
            }

            // Now handle user history
            // uint256 userEpoch = userPointEpoch[addr] + 1;

            userPointEpoch[addr] += 1; //= userPointEpoch[addr] + 1/*userEpoch*/;
            uNew.ts = block.timestamp;
            uNew.blk = block.number;
            userPointHistory[addr][
                userPointEpoch[addr] /*userEpoch*/
            ] = uNew;
        }
    }

    function _canConvertInt128(uint256 value) internal pure returns (bool) {
        return value < 2**127;
    }

    // """
    // @notice Deposit and lock tokens for a user
    // @param _addr User's wallet address
    // @param _value Amount to deposit
    // @param unlock_time New time when to unlock the tokens, or 0 if unchanged
    // @param locked_balance Previous locked amount / timestamp
    // """
    function _depositFor(
        address _addr,
        uint256 _value,
        uint256 unlockTime,
        LockedBalance memory lockedBalance,
        int128 _type
    ) internal {
        LockedBalance memory _locked = LockedBalance({
            amount: lockedBalance.amount,
            end: lockedBalance.end
        });
        uint256 supplyBefore = supply;

        supply = supplyBefore.add(_value);
        LockedBalance memory oldLocked = lockedBalance;
        // # Adding to existing lock, or if a lock is expired - creating a new one

        require(_canConvertInt128(_value), "!convertInt128");
        _locked.amount += int128(_value);
        if (unlockTime != 0) {
            _locked.end = unlockTime;
        }
        locked[_addr] = _locked;

        // # Possibilities:
        // # Both old_locked.end could be current or expired (>/< block.timestamp)
        // # value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // # _locked.end > block.timestamp (always)
        _checkpoint(_addr, oldLocked, _locked);

        require(
            IERC20(votingStakingRewards).balanceOf(_addr) >=
                uint256(_locked.amount),
            "notEnoughStake"
        );

        registrationMediator.processLockEvent(
            _addr,
            _lockStarts[_addr],
            _locked.end,
            uint256(_locked.amount)
        );

        emit Deposit(_addr, _value, _locked.end, _type, block.timestamp);
        emit Supply(supplyBefore, supplyBefore.add(_value));
    }

    // """
    // @notice Record global data to checkpoint
    // """
    function checkpoint() external {
        LockedBalance memory _emptyBalance;
        _checkpoint(address(0), _emptyBalance, _emptyBalance);
    }

    // """
    // @notice Deposit `_value` tokens for `_addr` and add to the lock
    // @dev Anyone (even a smart contract) can deposit for someone else, but
    //      cannot extend their locktime and deposit for a brand new user
    // @param _addr User's wallet address
    // @param _value Amount to add to user's lock
    // """
    function depositFor(address _addr, uint256 _value) external nonReentrant {
        LockedBalance memory _locked = locked[_addr];
        require(_value > 0, "!zeroValue");
        require(_locked.amount > 0, "!zeroLockedAmount");
        require(_locked.end > block.timestamp, "lockExpired");
        _depositFor(_addr, _value, 0, _locked, DEPOSIT_FOR_TYPE);
    }

    // """
    // @notice Deposit `_value` tokens for `msg.sender` and lock until `_unlock_time`
    // @param _value Amount to deposit
    // @param _unlock_time Epoch time when tokens unlock, rounded down to whole weeks
    // """
    function createLock(uint256 _value, uint256 _unlockTime)
        external
        nonReentrant
    {
        // assertNotContract(msg.sender);
        _createLockFor(msg.sender, _value, _unlockTime);
    }

    function setCreateLockAllowance(address _sender, bool _status) external {
        createLockAllowance[msg.sender][_sender] = _status;
    }

    function _createLockFor(
        address _for,
        uint256 _value,
        uint256 _unlockTime
    ) internal {
        uint256 unlockTime = (_unlockTime / WEEK) * WEEK; // # Locktime is rounded down to weeks
        LockedBalance memory _locked = locked[_for];

        require(_value > 0, "!zeroValue");
        require(_locked.amount == 0, "!withdrawOldTokensFirst");
        require(unlockTime > block.timestamp, "!futureTime");
        require(
            unlockTime >= minLockDuration + block.timestamp,
            "!minLockDuration"
        );
        require(
            unlockTime <= block.timestamp.add(MAXTIME),
            "invalidFutureTime"
        );

        _lockStarts[_for] = block.timestamp;

        _depositFor(_for, _value, unlockTime, _locked, CREATE_LOCK_TYPE);
    }

    function createLockFor(
        address _for,
        uint256 _value,
        uint256 _unlockTime
    ) external nonReentrant {
        if (msg.sender != votingStakingRewards) {
            require(createLockAllowance[msg.sender][_for], "!allowed");
        }
        _createLockFor(_for, _value, _unlockTime);
    }

    // """
    // @notice Deposit `_value` additional tokens for `msg.sender`
    //         without modifying the unlock time
    // @param _value Amount of tokens to deposit and add to the lock
    // """
    function increaseAmount(uint256 _value) external nonReentrant {
        // assertNotContract(msg.sender);
        LockedBalance memory _locked = locked[msg.sender];
        require(_value > 0, "!zeroValue");
        require(_locked.amount > 0, "!zeroLockedAmount");
        require(_locked.end > block.timestamp, "lockExpired");
        _depositFor(msg.sender, _value, 0, _locked, INCREASE_LOCK_AMOUNT);
    }

    // """
    // @notice Extend the unlock time for `msg.sender` to `_unlock_time`
    // @param _unlock_time New epoch time for unlocking
    // """
    function increaseUnlockTime(uint256 _unlockTime) external nonReentrant {
        // assertNotContract(msg.sender);
        LockedBalance memory _locked = locked[msg.sender];
        uint256 unlockTime = (_unlockTime / WEEK) * WEEK; // Locktime is rounded down to weeks

        require(_locked.end > block.timestamp, "lockExpired");
        require(_locked.amount > 0, "!zeroLockedAmount");
        require(unlockTime > _locked.end, "canOnlyIncreaseLockDuration");
        require(
            unlockTime <= block.timestamp.add(MAXTIME),
            "lockOnlyToValidFutureTime"
        );

        _depositFor(msg.sender, 0, unlockTime, _locked, INCREASE_UNLOCK_TIME);
    }

    // """
    // @notice Withdraw all tokens for `msg.sender`
    // @dev Only possible if the lock has expired
    // """
    function withdraw() external nonReentrant {
        LockedBalance memory _locked = locked[msg.sender];
        require(block.timestamp >= _locked.end, "lockDidntExpired");
        uint256 value = uint256(_locked.amount);

        LockedBalance memory oldLocked = _locked;
        _locked.end = 0;
        _locked.amount = 0;
        locked[msg.sender] = _locked;
        uint256 supplyBefore = supply;
        supply = supplyBefore - value;

        // # old_locked can have either expired <= timestamp or zero end
        // # _locked has only 0 end
        // # Both can have >= 0 amount
        _checkpoint(msg.sender, oldLocked, _locked);

        emit Withdraw(msg.sender, value, block.timestamp);
        emit Supply(supplyBefore, supplyBefore - value);
    }

    // """
    // @notice Binary search to estimate timestamp for block number
    // @param _block Block to find
    // @param max_epoch Don't go beyond this epoch
    // @return Approximate timestamp for block
    // """
    function findBlockEpoch(uint256 _block, uint256 maxEpoch)
        internal
        view
        returns (uint256)
    {
        uint256 _min = 0;
        uint256 _max = maxEpoch;
        for (uint256 i = 0; i < 128; i++) {
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

    // """
    // @notice Get the current voting power for `msg.sender`
    // @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
    // @param addr User wallet address
    // @param _t Epoch time to return voting power at
    // @return User voting power
    // """
    function balanceOf(address addr) public view returns (uint256) {
        return balanceOf(addr, block.timestamp);
    }

    function balanceOf(address addr, uint256 _t) public view returns (uint256) {
        uint256 _epoch = userPointEpoch[addr];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory lastPoint = userPointHistory[addr][_epoch];
            lastPoint.bias -= lastPoint.slope * int128(_t - lastPoint.ts);
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
            return uint256(lastPoint.bias);
        }
    }

    // """
    // @notice Measure voting power of `addr` at block height `_block`
    // @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
    // @param addr User's wallet address
    // @param _block Block to calculate the voting power at
    // @return Voting power
    // """
    function balanceOfAt(address addr, uint256 _block)
        external
        view
        returns (uint256)
    {
        // # Copying and pasting totalSupply code because Vyper cannot pass by
        // # reference yet
        require(_block <= block.number, "onlyPast");

        // Binary search
        uint256 _min = 0;
        uint256 _max = userPointEpoch[addr];
        for (uint256 i = 0; i < 128; i++) {
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

        Point memory upoint = userPointHistory[addr][_min];

        uint256 maxEpoch = epoch;
        uint256 _epoch = findBlockEpoch(_block, maxEpoch);
        Point memory point0 = pointHistory[_epoch];
        uint256 dBlock = 0;
        uint256 dT = 0;
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
            blockTime += (dT * (_block - point0.blk)) / dBlock;
        }

        upoint.bias -= upoint.slope * int128(blockTime - upoint.ts);
        if (upoint.bias >= 0) {
            return uint256(upoint.bias);
        } else {
            return 0;
        }
    }

    // """
    // @notice Calculate total voting power at some point in the past
    // @param point The point (bias/slope) to start search from
    // @param t Time to calculate the total voting power at
    // @return Total voting power at that time
    // """
    function supplyAt(Point memory point, uint256 t)
        internal
        view
        returns (uint256)
    {
        Point memory lastPoint = point;
        uint256 tI = (lastPoint.ts / WEEK) * WEEK;
        for (uint256 i = 0; i < 255; i++) {
            tI += WEEK;
            int128 dSlope = 0;
            if (tI > t) {
                tI = t;
            } else {
                dSlope = slopeChanges[tI];
            }
            lastPoint.bias -= lastPoint.slope * int128(tI - lastPoint.ts);
            if (tI == t) {
                break;
            }
            lastPoint.slope += dSlope;
            lastPoint.ts = tI;
        }

        if (lastPoint.bias < 0) {
            lastPoint.bias = 0;
        }
        return uint256(lastPoint.bias);
    }

    // """
    // @notice Calculate total voting power
    // @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
    // @return Total voting power
    // """
    function totalSupply() external view returns (uint256) {
        return totalSupply(block.timestamp);
    }

    // returns supply of locked tokens
    function lockedSupply() external view returns (uint256) {
        return supply;
    }

    function totalSupply(uint256 t) public view returns (uint256) {
        uint256 _epoch = epoch;
        Point memory lastPoint = pointHistory[_epoch];
        return supplyAt(lastPoint, t);
    }

    // """
    // @notice Calculate total voting power at some point in the past
    // @param _block Block to calculate the total voting power at
    // @return Total voting power at `_block`
    // """
    function totalSupplyAt(uint256 _block) external view returns (uint256) {
        require(_block <= block.number, "onlyPastAllowed");
        uint256 _epoch = epoch;
        uint256 targetEpoch = findBlockEpoch(_block, _epoch);

        Point memory point = pointHistory[targetEpoch];
        uint256 dt = 0; // difference in total voting power between _epoch and targetEpoch

        if (targetEpoch < _epoch) {
            Point memory pointNext = pointHistory[targetEpoch + 1];
            if (point.blk != pointNext.blk) {
                dt =
                    ((_block - point.blk) * (pointNext.ts - point.ts)) /
                    (pointNext.blk - point.blk);
            }
        } else {
            if (point.blk != block.number) {
                dt =
                    ((_block - point.blk) * (block.timestamp - point.ts)) /
                    (block.number - point.blk);
            }
        }

        // # Now dt contains info on how far are we beyond point
        return supplyAt(point, point.ts + dt);
    }

    // """
    // @dev Dummy method required for Aragon compatibility
    // """
    function changeController(address _newController) external {
        require(msg.sender == controller, "!controller");
        controller = _newController;
    }
}