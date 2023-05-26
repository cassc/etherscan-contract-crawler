// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@solmate/auth/Owned.sol";
import "@solmate/utils/ReentrancyGuard.sol";
import "@solmate/utils/SafeCastLib.sol";

import {IVotingEscrow} from "./interfaces/IVotingEscrow.sol";
import {IBlocklist} from "./interfaces/IBlocklist.sol";
import {SafeTransferLib, ERC20} from "@solmate/utils/SafeTransferLib.sol";

contract VEZTH is IVotingEscrow, Owned {
    using SafeCastLib for uint256;

    struct LockedBalance {
        uint128 amount;
        uint64 end;
        uint64 start;
    }

    struct Point {
        uint128 amount;
        uint128 index;
    }

    uint256 private constant _SCALE = 7 days;
    uint256 private constant _MAX_TIME = 365 days;
    uint256 private constant _MIN_TIME = 14 days;
    uint256 private constant _INCREASE = 4;

    // comming soon
    // bytes32 private constant _DELEGATION_TYPEHASH =
    // keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    // Voting token
    string public constant name = "Vote Escrowed ZTH";
    string public constant symbol = "veZTH";
    uint8 public constant decimals = 18;
    ERC20 public immutable token;

    mapping(uint256 => Point) private _totalUnlockAtEpoch;
    mapping(address => mapping(uint256 => Point)) private _userUnlockAtEpoch;

    address public penaltyRecipient; // receives collected penalty payments
    uint256 public maxPenalty = 1e18; // penalty for quitters with MAXTIME remaining lock
    address public blocklist;
    mapping(address => LockedBalance) public locked;

    /**
     * @notice Initializes state
     * @param _penaltyRecipient The recipient of penalty paid by lock quitters
     * @param _token The token locked in order to obtain voting power
     */
    constructor(address _penaltyRecipient, address _token) Owned(msg.sender) {
        token = ERC20(_token);
        penaltyRecipient = _penaltyRecipient;
    }

    function lockEnd(address account) external view returns (uint256) {
        return locked[account].end;
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function balanceOf(address account) external view returns (uint256) {
        return getVotes(account);
    }

    /**
     * @dev Gets the current total votes balance for all locked tokens.
     */
    function totalSupply() external view returns (uint256) {
        return _getVotes(_totalUnlockAtEpoch);
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view returns (uint256) {
        return _getVotes(_userUnlockAtEpoch[account]);
    }

    function _getVotes(mapping(uint256 => Point) storage points) private view returns (uint256) {
        uint256 epoch = _getEpoch(block.timestamp); 
        uint256 max = _MAX_TIME / _SCALE;
        uint256 powers;
        //  max lookup is 52 times
        for (uint256 i = 1; i <= max; i++) {
            Point memory p = points[epoch + i];
            powers += uint256(p.index) - uint256(p.amount) * block.timestamp;
        }
        return (powers * _INCREASE) / _MAX_TIME;
    }

    function createLock(uint256 value, uint256 unlockTime) external checkBlocklist {
        _createLock(msg.sender, value, unlockTime);
    }

    function createLockWithPermit(uint256 value, uint256 unlockTime, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
        checkBlocklist
    {
        // permit max
        ERC20(address(token)).permit(msg.sender, address(this), type(uint256).max, deadline, v, r, s);
        _createLock(msg.sender, value, unlockTime);
    }

    function _createLock(address account, uint256 value, uint256 unlockTime) internal {
        LockedBalance memory lock = locked[account];
        if (lock.amount > 0) revert WithdrawOldTokensFirst();
        if (value == 0) revert ZeroValue();
        if (unlockTime <  block.timestamp + _MIN_TIME) revert InsufficientLockTime();
        if (unlockTime > block.timestamp + _MAX_TIME) {
            revert ExceedsMaxLockTime();
        }

        // Transfer tokens
        SafeTransferLib.safeTransferFrom(token, msg.sender, address(this), value);

        locked[account] = LockedBalance({
            amount: value.safeCastTo128(),
            end: unlockTime.safeCastTo64(),
            start: block.timestamp.safeCastTo64()
        });
        uint256 epoch = _getEpoch(unlockTime);
        _writePoint(account, epoch, value, unlockTime, true);
        emit CreateLock(account, value, unlockTime);
    }

    function _writePoint(address account, uint256 epoch, uint256 value, uint256 unlocktime, bool isAdd) private {
        Point memory point = _userUnlockAtEpoch[account][epoch];
        Point memory totalPoint = _totalUnlockAtEpoch[epoch];

        if (isAdd) {
            uint128 delta = (value * unlocktime).safeCastTo128();
            uint128 v = value.safeCastTo128();
            point.amount += v;
            point.index += delta;
            totalPoint.amount += v;
            totalPoint.index += delta;
        } else {
            uint128 delta = (value * unlocktime).safeCastTo128();
            uint128 v = value.safeCastTo128();
            point.amount -= v;
            point.index -= delta;
            totalPoint.amount -= v;
            totalPoint.index -= delta;
        }
        _userUnlockAtEpoch[account][epoch] = point;
        _totalUnlockAtEpoch[epoch] = totalPoint;
    }

    function increaseAmount(uint256 value) external {
        LockedBalance memory lock = locked[msg.sender];
        if (value == 0) revert ZeroValue();
        if (lock.amount == 0) revert CreateLockFirst();
        if (lock.end <= block.timestamp) revert LockExpired();

        // Update state
        // Transfer tokens
        SafeTransferLib.safeTransferFrom(token, msg.sender, address(this), value);
        // Update state
        locked[msg.sender].amount = (lock.amount + value).safeCastTo128();

        uint256 epoch = _getEpoch(lock.end);
        _writePoint(msg.sender, epoch, value, lock.end, true);
        emit IncreaseAmount(msg.sender, value, lock.end);
    }

    function increaseUnlockTime(uint256 unlockTime) external {
        LockedBalance memory lock = locked[msg.sender];
        if (lock.amount == 0) revert CreateLockFirst();

        if (unlockTime > block.timestamp + _MAX_TIME) {
            revert ExceedsMaxLockTime();
        }
        if (unlockTime <= block.timestamp) revert InsufficientLockTime();
        if (unlockTime <= lock.end) revert InsufficientLockTime();

        // Update state
        locked[msg.sender].end = unlockTime.safeCastTo64();
        uint256 oldEpoch = _getEpoch(lock.end);
        uint256 epoch = _getEpoch(unlockTime);
        _writePoint(msg.sender, oldEpoch, lock.amount, lock.end, false);
        _writePoint(msg.sender, epoch, lock.amount, unlockTime, true);

        emit IncreaseUnlockTime(msg.sender, lock.amount, lock.end);
    }

    function withdraw() external {
        LockedBalance memory lock = locked[msg.sender];
        if (lock.amount == 0) revert MissingLock();
        if (lock.end > block.timestamp) revert LockNotExpired();

        // Update state
        locked[msg.sender] = LockedBalance(0, 0, 0);
        uint256 epoch = _getEpoch(lock.end);
        _writePoint(msg.sender, epoch, lock.amount, lock.end, false);

        // Transfer tokens
        SafeTransferLib.safeTransfer(token, msg.sender, lock.amount);

        emit Unlock(msg.sender, lock.amount, 0);
    }

    function quitLock() external {
        LockedBalance memory lock = locked[msg.sender];
        if (lock.amount == 0) revert MissingLock();
        if (lock.end <= block.timestamp) revert LockExpired();

        // Update state
        locked[msg.sender].amount = 0;
        locked[msg.sender].end = 0;

        uint256 epoch = _getEpoch(lock.end);
        _writePoint(msg.sender, epoch, lock.amount, lock.end, false);

        // Collect penalty
        uint256 penalty = (lock.amount * _calculatePenaltyRate(lock.end)) / 1e18;
        if (lock.amount < penalty) penalty = lock.amount;

        SafeTransferLib.safeTransfer(token, penaltyRecipient, penalty);
        SafeTransferLib.safeTransfer(token, msg.sender, lock.amount - penalty);
        emit Unlock(msg.sender, lock.amount, penalty);
    }

    /// @notice Returns the penalty rate for a given lock expiration
    /// @param end The lock's expiration
    /// @return The penalty rate applicable to the lock
    /// @dev The penalty rate decreases linearly at the same rate as a lock's voting power
    /// in order to compensate for votes unlocked without committing to the lock expiration
    function getPenaltyRate(uint256 end) external view returns (uint256) {
        if (end <= block.timestamp) return 0;
        return _calculatePenaltyRate(end);
    }

    // Calculate penalty rate
    // Penalty rate decreases linearly at the same rate as a lock's voting power
    // in order to compensate for votes used
    function _calculatePenaltyRate(uint256 end) internal view returns (uint256) {
        // We know that end > block.timestamp because expired locks cannot be quitted
        return ((end - block.timestamp) * maxPenalty) / _MAX_TIME;
    }

    function _getEpoch(uint256 unlockTime) private pure returns (uint256) {
        return unlockTime / _SCALE;
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~~~~~~ ///
    ///       Owner Functions       ///
    /// ~~~~~~~~~~~~~~~~~~~~~~~~~~~ ///

    /// @notice Updates the blocklist contract
    function updateBlocklist(address _addr) external onlyOwner {
        blocklist = _addr;
        emit UpdateBlocklist(_addr);
    }

    /// @notice Updates the recipient of the accumulated penalty paid by quitters
    function updatePenaltyRecipient(address _addr) external onlyOwner {
        penaltyRecipient = _addr;
        emit UpdatePenaltyRecipient(_addr);
    }

    /**
     * @notice Updates the quitlock penalty
     * @dev use case:
     *  1. Removes quitlock penalty by setting it to zero.
     *  2. Migrat to a new  VotingEscrow contract.
     */
    function updatePenalty(uint256 penalty) external onlyOwner {
        maxPenalty = penalty;
        emit UpdatePenalty(penalty);
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~~~~~~ ///
    ///      Disable ERC20 functions ///
    /// ~~~~~~~~~~~~~~~~~~~~~~~~~~~ ///
    function allowance(address, address) external pure returns (uint256) {
        return 0;
    }

    function approve(address, uint256) external pure returns (bool) {
        return false;
    }

    function transfer(address, uint256) external pure returns (bool) {
        revert("Disabled");
    }

    function transferFrom(address, address, uint256) external pure returns (bool) {
        revert("Disabled");
    }

    /**
     * ====== others
     */

    modifier checkBlocklist() {
        if (blocklist != address(0)) {
            require(!IBlocklist(blocklist).isBlocked(msg.sender), "Blocked contract");
        }
        _;
    }

    event UpdatePenalty(uint256 penalty);
    event UpdateBlocklist(address indexed blocklist);
    event UpdatePenaltyRecipient(address indexed recipient);
    event CollectPenalty(uint256 amount, address indexed recipient);
    event Unlock(address account, uint256 value, uint256 penalty);
    event CreateLock(address indexed account, uint256 value, uint256 unlockTime);
    event IncreaseUnlockTime(address account, uint256 value, uint256 unlockTime);
    event IncreaseAmount(address account, uint256 value, uint256 unlockTime);

    error LockExpired(); // lock expired
    error CreateLockFirst(); // create lock first
    error InsufficientLockTime(); // insufficient lock time
    error ExceedsMaxLockTime(); // exceeds max lock time
    error MissingLock(); // no lock found
    error LockNotExpired(); // lock not expired
    error OnlyBlocklist(); // only callable by the blocklist contract
    error WithdrawOldTokensFirst(); // Withdraw old tokens first
    error ZeroValue(); // Zero value
}