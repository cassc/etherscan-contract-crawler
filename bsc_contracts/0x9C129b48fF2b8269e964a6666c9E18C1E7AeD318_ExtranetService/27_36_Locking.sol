// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./lib/CollectTokens.sol";

/**
@notice Locking vault for ARDN token on Extranets
*/

contract Locking is Ownable {
    using SafeERC20 for IERC20;

    uint8 constant private LOCK_PAUSED   = 1 << 0;
    uint8 constant private UNLOCK_PAUSED = 1 << 1;
    uint8 constant private MAX_LOCKS = 100; // ought to be enough for everyone (c)

    /// @notice ARDN token that is locked
    IERC20 public immutable token;

    struct UnlockData {
        uint256 amount;
        uint256 power;
        uint32 unlockAfter;
    }

    /// @notice Minimum weeks to lock ARDN for
    uint8 public minDuration;

    /// @notice Maximum weeks to lock ARDN for
    uint8 public maxDuration;

    /// @notice Amount of ARDN locked by an account
    mapping (address => uint256) public lockedBy;

    /// @notice Total power (aka locked ARDN * duration) by account
    mapping (address => uint256) public powerBy;

    /// @notice List of unlocks per account
    mapping (address => UnlockData[]) public unlockData;

    /// @notice Bitmap of pauses, consisting of LOCK_PAUSED = 1 << 0 and UNLOCK_PAUSED = 1 << 1
    uint8 public pauses;

    event Locked(address indexed account, uint256 lockedAmount, uint256 addedPower, uint32 unlockAfter);
    event Unlocked(address indexed account, uint256 unlockedAmount, uint256 removedPower);
    event ConfigurationUpdated();

    constructor(address _token, uint8 _minDuration, uint8 _maxDuration) {
        token = IERC20(_token);

        minDuration = _minDuration;
        maxDuration = _maxDuration;
    }

    modifier whenNotPaused(uint8 whatExactly) {
        require((pauses & whatExactly) != whatExactly, "PAUSED");
        _;
    }

    /**
     * @notice Lock ARDN to gain power
     * @param amount ARDN amount to lock
     * @param duration for how many weeks
     */
    function lock(uint256 amount, uint8 duration)
        public
        whenNotPaused(LOCK_PAUSED)
    {
        require(duration >= minDuration && duration <= maxDuration, "DURATION");
        require(amount > 0, "ZERO");
        require(unlockData[msg.sender].length < MAX_LOCKS, "MAX_LOCKS");

        uint32 unlockAfter = uint32(block.timestamp) + (uint32(duration) * 7 days);
        uint256 power = amount * uint256(duration);

        unlockData[msg.sender].push(UnlockData({
            amount: amount,
            unlockAfter: unlockAfter,
            power: power
        }));

        lockedBy[msg.sender] += amount;
        powerBy[msg.sender] += power;

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit Locked(msg.sender, amount, power, unlockAfter);
    }

    /**
     * @notice Return amount of ARDN that can be unlocked right now
     * @param account Which address to calculate unlockable amount for
     * @return ARDN amount
     */
    function unlockable(address account)
        public
        view
        returns (uint256)
    {
        UnlockData[] storage userUnlockData = unlockData[account];

        uint256 amount = 0;

        for (uint i = 0; i < userUnlockData.length; i++) {
            UnlockData memory entry = userUnlockData[i];

            if (block.timestamp >= entry.unlockAfter) {
                amount += entry.amount;
            }
        }

        return amount;
    }

    /**
     * @notice Unlock ARDN that can be unlocked. Calling arguments should be calculated offchain.
     * @param from position in unlockData array from which shall we begin unlocking
     * @param count how many entries in the unlockData array shall we unlock
     */
    function unlockAt(uint256 from, uint256 count)
        public
        whenNotPaused(UNLOCK_PAUSED)
    {
        UnlockData[] storage userUnlockData = unlockData[msg.sender];

        require(count > 0, "COUNT");
        require(from + count <= userUnlockData.length, "COUNT");

        uint256 amountToReturn = 0;
        uint256 powerToRemove = 0;

        uint256 to = from + count;

        uint256 clearedCount = 0;

        for (uint256 pos=from; pos<to; pos++) {
            UnlockData memory entry = userUnlockData[pos];

            require(block.timestamp >= entry.unlockAfter, "LOCKED");

            powerToRemove += entry.power;
            amountToReturn += entry.amount;

            unlockData[msg.sender][pos].amount = 0;
            unlockData[msg.sender][pos].power = 0;
            unlockData[msg.sender][pos].unlockAfter = 0;

            clearedCount++;
        }

        require(clearedCount > 0, "ZERO");

        if (clearedCount == userUnlockData.length) {
            delete unlockData[msg.sender];
        } else {
            compressUnlockData(msg.sender);
        }

        lockedBy[msg.sender] -= amountToReturn;
        powerBy[msg.sender] -= powerToRemove;

        token.safeTransfer(msg.sender, amountToReturn);

        emit Unlocked(msg.sender, amountToReturn, powerToRemove);
    }

    function compressUnlockData(address account)
        private
    {
        // UnlockData[] storage userUnlockData = unlockData[account];

        uint256 len = unlockData[account].length;

        UnlockData[] memory newUserUnlockData = new UnlockData[](len);

        uint256 lastPos = 0;

        for (uint256 pos=0; pos<len; pos++) {
            UnlockData memory entry = unlockData[account][pos];

            if (entry.amount == 0) { // cleared
                continue;
            }

            newUserUnlockData[lastPos] = UnlockData({
                amount: entry.amount,
                unlockAfter: entry.unlockAfter,
                power: entry.power
            });

            lastPos++;
        }

        delete unlockData[account];
        // unlockData[account] = newUserUnlockData;

        for (uint i=0; i<lastPos; i++) {
            unlockData[account].push(newUserUnlockData[i]);
        }
    }

    /**
     * @notice Length of unlockData for account
     * @param account account
     * @return length
     */
    function unlockDataLength(address account)
        public
        view
        returns (uint256)
    {
        return unlockData[account].length;
    }

    /**
     * @notice Set pauses
     * @dev Admin method.
     */
    function setPauses(uint8 _pauses)
        public
        onlyOwner
    {
        pauses = _pauses;
        emit ConfigurationUpdated();
    }

    /**
     * @notice Change lock duration.
     * @dev Admin method.
     * @param _minDuration Minimum weeks to lock ARDN for
     * @param _maxDuration Maximum weeks to lock ARDN for
     */
    function setLockDuration(uint8 _minDuration, uint8 _maxDuration)
        public
        onlyOwner
    {
        minDuration = _minDuration;
        maxDuration = _maxDuration;
        emit ConfigurationUpdated();
    }

    /**
     * @notice Collect tokens and/or native token.
     * @dev Admin method.
     */
    function collectTokens(address[] memory tokens, address to)
        public
        onlyOwner
    {
        CollectTokens._collectTokens(tokens, to);
    }
}