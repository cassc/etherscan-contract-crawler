// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title RLBTRFLY
/// @author ████

/**
    @notice
    Partially adapted from Convex's CvxLockerV2 contract with some modifications and optimizations for the BTRFLY V2 requirements
*/

contract RLBTRFLY is ReentrancyGuard, Ownable {
    using SafeTransferLib for ERC20;

    /**
        @notice Lock balance details
        @param  amount      uint224  Locked amount in the lock
        @param  unlockTime  uint32   Unlock time of the lock
     */
    struct LockedBalance {
        uint224 amount;
        uint32 unlockTime;
    }

    /**
        @notice Balance details
        @param  locked           uint224          Overall locked amount
        @param  nextUnlockIndex  uint32           Index of earliest next unlock
        @param  lockedBalances   LockedBalance[]  List of locked balances data
     */
    struct Balance {
        uint224 locked;
        uint32 nextUnlockIndex;
        LockedBalance[] lockedBalances;
    }

    // 1 epoch = 1 week
    uint32 public constant EPOCH_DURATION = 1 weeks;
    // Full lock duration = 16 epochs
    uint256 public constant LOCK_DURATION = 16 * EPOCH_DURATION;

    ERC20 public immutable btrflyV2;

    uint256 public lockedSupply;

    mapping(address => Balance) public balances;

    bool public isShutdown;

    string public constant name = "Revenue-Locked BTRFLY";
    string public constant symbol = "rlBTRFLY";
    uint8 public constant decimals = 18;

    event Shutdown();
    event Locked(
        address indexed account,
        uint256 indexed epoch,
        uint256 amount
    );
    event Withdrawn(address indexed account, uint256 amount, bool relock);

    error ZeroAddress();
    error ZeroAmount();
    error IsShutdown();
    error InvalidNumber(uint256 value);

    /**
        @param  _btrflyV2  address  BTRFLYV2 token address
     */
    constructor(address _btrflyV2) {
        if (_btrflyV2 == address(0)) revert ZeroAddress();
        btrflyV2 = ERC20(_btrflyV2);
    }

    /**
        @notice Emergency method to shutdown the current locker contract which also force-unlock all locked tokens
     */
    function shutdown() external onlyOwner {
        if (isShutdown) revert IsShutdown();

        isShutdown = true;

        emit Shutdown();
    }

    /**
        @notice Locked balance of the specified account including those with expired locks
        @param  account  address  Account
        @return amount   uint256  Amount
     */
    function lockedBalanceOf(address account)
        external
        view
        returns (uint256 amount)
    {
        return balances[account].locked;
    }

    /**
        @notice Balance of the specified account by only including tokens in active locks
        @param  account  address  Account
        @return amount   uint256  Amount
     */
    function balanceOf(address account) external view returns (uint256 amount) {
        // Using storage as it's actually cheaper than allocating a new memory based variable
        Balance storage userBalance = balances[account];
        LockedBalance[] storage locks = userBalance.lockedBalances;
        uint256 nextUnlockIndex = userBalance.nextUnlockIndex;

        amount = balances[account].locked;

        uint256 locksLength = locks.length;

        // Skip all old records
        for (uint256 i = nextUnlockIndex; i < locksLength; ++i) {
            if (locks[i].unlockTime <= block.timestamp) {
                amount -= locks[i].amount;
            } else {
                break;
            }
        }

        // Remove amount locked in the next epoch
        if (
            locksLength > 0 &&
            uint256(locks[locksLength - 1].unlockTime) - LOCK_DURATION >
            getCurrentEpoch()
        ) {
            amount -= locks[locksLength - 1].amount;
        }

        return amount;
    }

    /**
        @notice Pending locked amount at the specified account
        @param  account  address  Account
        @return amount   uint256  Amount
     */
    function pendingLockOf(address account)
        external
        view
        returns (uint256 amount)
    {
        LockedBalance[] storage locks = balances[account].lockedBalances;

        uint256 locksLength = locks.length;

        if (
            locksLength > 0 &&
            uint256(locks[locksLength - 1].unlockTime) - LOCK_DURATION >
            getCurrentEpoch()
        ) {
            return locks[locksLength - 1].amount;
        }

        return 0;
    }

    /**
        @notice Locked balances details for the specifed account
        @param  account     address          Account
        @return total       uint256          Total amount
        @return unlockable  uint256          Unlockable amount
        @return locked      uint256          Locked amount
        @return lockData    LockedBalance[]  List of active locks
     */
    function lockedBalances(address account)
        external
        view
        returns (
            uint256 total,
            uint256 unlockable,
            uint256 locked,
            LockedBalance[] memory lockData
        )
    {
        Balance storage userBalance = balances[account];
        LockedBalance[] storage locks = userBalance.lockedBalances;
        uint256 nextUnlockIndex = userBalance.nextUnlockIndex;
        uint256 idx;

        for (uint256 i = nextUnlockIndex; i < locks.length; ++i) {
            if (locks[i].unlockTime > block.timestamp) {
                if (idx == 0) {
                    lockData = new LockedBalance[](locks.length - i);
                }

                lockData[idx] = locks[i];
                locked += lockData[idx].amount;
                ++idx;
            } else {
                unlockable += locks[i].amount;
            }
        }

        return (userBalance.locked, unlockable, locked, lockData);
    }

    /**
        @notice Get current epoch
        @return uint256  Current epoch
     */
    function getCurrentEpoch() public view returns (uint256) {
        return (block.timestamp / EPOCH_DURATION) * EPOCH_DURATION;
    }

    /**
        @notice Locked tokens cannot be withdrawn for the entire lock duration and are eligible to receive rewards
        @param  account  address  Account
        @param  amount   uint256  Amount
     */
    function lock(address account, uint256 amount) external nonReentrant {
        if (account == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        btrflyV2.safeTransferFrom(msg.sender, address(this), amount);

        _lock(account, amount);
    }

    /**
        @notice Perform the actual lock
        @param  account  address  Account
        @param  amount   uint256  Amount
     */
    function _lock(address account, uint256 amount) internal {
        if (isShutdown) revert IsShutdown();

        Balance storage balance = balances[account];

        uint224 lockAmount = _toUint224(amount);

        balance.locked += lockAmount;
        lockedSupply += lockAmount;

        uint256 lockEpoch = getCurrentEpoch() + EPOCH_DURATION;
        uint256 unlockTime = lockEpoch + LOCK_DURATION;
        LockedBalance[] storage locks = balance.lockedBalances;
        uint256 idx = locks.length;

        // If the latest user lock is smaller than this lock, add a new entry to the end of the list
        // else, append it to the latest user lock
        if (idx == 0 || locks[idx - 1].unlockTime < unlockTime) {
            locks.push(
                LockedBalance({
                    amount: lockAmount,
                    unlockTime: _toUint32(unlockTime)
                })
            );
        } else {
            locks[idx - 1].amount += lockAmount;
        }

        emit Locked(account, lockEpoch, amount);
    }

    /**
        @notice Withdraw all currently locked tokens where the unlock time has passed
        @param  account     address  Account
        @param  relock      bool     Whether should relock
        @param  withdrawTo  address  Target receiver
     */
    function _processExpiredLocks(
        address account,
        bool relock,
        address withdrawTo
    ) internal {
        // Using storage as it's actually cheaper than allocating a new memory based variable
        Balance storage userBalance = balances[account];
        LockedBalance[] storage locks = userBalance.lockedBalances;
        uint224 locked;
        uint256 length = locks.length;

        if (isShutdown || locks[length - 1].unlockTime <= block.timestamp) {
            locked = userBalance.locked;
            userBalance.nextUnlockIndex = _toUint32(length);
        } else {
            // Using nextUnlockIndex to reduce the number of loops
            uint32 nextUnlockIndex = userBalance.nextUnlockIndex;

            for (uint256 i = nextUnlockIndex; i < length; ++i) {
                // Unlock time must be less or equal to time
                if (locks[i].unlockTime > block.timestamp) break;

                // Add to cumulative amounts
                locked += locks[i].amount;
                ++nextUnlockIndex;
            }

            // Update the account's next unlock index
            userBalance.nextUnlockIndex = nextUnlockIndex;
        }

        if (locked == 0) revert ZeroAmount();

        // Update user balances and total supplies
        userBalance.locked -= locked;
        lockedSupply -= locked;

        emit Withdrawn(account, locked, relock);

        // Relock or return to user
        if (relock) {
            _lock(withdrawTo, locked);
        } else {
            btrflyV2.safeTransfer(withdrawTo, locked);
        }
    }

    /**
        @notice Withdraw expired locks to a different address
        @param  to  address  Target receiver
     */
    function withdrawExpiredLocksTo(address to) external nonReentrant {
        if (to == address(0)) revert ZeroAddress();

        _processExpiredLocks(msg.sender, false, to);
    }

    /**
        @notice Withdraw/relock all currently locked tokens where the unlock time has passed
        @param  relock  bool  Whether should relock
     */
    function processExpiredLocks(bool relock) external nonReentrant {
        _processExpiredLocks(msg.sender, relock, msg.sender);
    }

    /**
        @notice Validate and cast a uint256 integer to uint224
        @param  value  uint256  Value
        @return        uint224  Casted value
     */
    function _toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) revert InvalidNumber(value);

        return uint224(value);
    }

    /**
        @notice Validate and cast a uint256 integer to uint32
        @param  value  uint256  Value
        @return        uint32   Casted value
     */
    function _toUint32(uint256 value) internal pure returns (uint32) {
        if (value > type(uint32).max) revert InvalidNumber(value);

        return uint32(value);
    }
}