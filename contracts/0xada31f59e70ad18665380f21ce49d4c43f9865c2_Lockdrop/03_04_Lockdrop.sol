// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.11;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {IERC20Droppable} from "./interfaces/IERC20Droppable.sol";

/// @title Lockdrop
/// @author zefram.eth
/// @notice Used for locking one token to receive another token
contract Lockdrop {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error Error_BeforeUnlockTimestamp();
    error Error_AfterUnlockTimestamp();

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice Records the amount of old tokens locked by a user during migration
    /// @dev Only used if unlockTimestamp() is non-zero
    mapping(address => uint256) public lockedOldTokenBalance;

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The old token that's being locked
    ERC20 public immutable oldToken;

    /// @notice The new token that's being distributed
    IERC20Droppable public immutable newToken;

    /// @notice The timestamp after which the locked old tokens
    /// can be redeemed.
    uint64 public immutable unlockTimestamp;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(ERC20 oldToken_, IERC20Droppable newToken_, uint64 unlockTimestamp_) {
        oldToken = oldToken_;
        newToken = newToken_;
        unlockTimestamp = unlockTimestamp_;
    }

    /// -----------------------------------------------------------------------
    /// User actions
    /// -----------------------------------------------------------------------

    /// @notice Locks old tokens and distributes new tokens
    /// @param oldTokenAmount The amount of old tokens to lock
    /// @param recipient The address that will receive the new tokens
    /// (as well as the right to unlock the old tokens)
    /// @return newTokenAmount The amount of new tokens received
    function lock(uint256 oldTokenAmount, address recipient) external returns (uint256 newTokenAmount) {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        // if locking 0, just do nothing
        if (oldTokenAmount == 0) {
            return 0;
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // can't lock after unlock since that enables infinite migration loops
        if (block.timestamp >= unlockTimestamp) {
            revert Error_AfterUnlockTimestamp();
        }

        // don't check for overflow cause nobody cares
        // also because an ERC20 token's total supply can't exceed 256 bits
        unchecked {
            lockedOldTokenBalance[recipient] += oldTokenAmount;
        }

        /// -----------------------------------------------------------------------
        /// Effects
        /// -----------------------------------------------------------------------

        // transfer old tokens from sender and lock
        oldToken.safeTransferFrom(msg.sender, address(this), oldTokenAmount);

        // transfer new tokens to recipient
        newTokenAmount = newToken.drop(oldTokenAmount, recipient);
    }

    /// @notice Unlocks old tokens. Only callable if the current time is >= unlockTimestamp.
    /// @param recipient The address that will receive the old tokens
    /// @return oldTokenAmount The amount of old tokens unlocked
    function unlock(address recipient) external returns (uint256 oldTokenAmount) {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        // must be after unlock timestamp
        if (block.timestamp < unlockTimestamp) {
            revert Error_BeforeUnlockTimestamp();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        oldTokenAmount = lockedOldTokenBalance[msg.sender];
        if (oldTokenAmount == 0) return 0;
        delete lockedOldTokenBalance[msg.sender];

        /// -----------------------------------------------------------------------
        /// Effects
        /// -----------------------------------------------------------------------

        oldToken.safeTransfer(recipient, oldTokenAmount);
    }
}