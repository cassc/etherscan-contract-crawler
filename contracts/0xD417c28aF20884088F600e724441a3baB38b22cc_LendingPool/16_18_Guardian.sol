/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */

pragma solidity ^0.8.13;

import { Owned } from "../../lib/solmate/src/auth/Owned.sol";

/**
 * @title Guardian
 * @author Pragma Labs
 * @notice This module provides the logic that allows authorized accounts to trigger an emergency stop.
 */
abstract contract Guardian is Owned {
    /* //////////////////////////////////////////////////////////////
                                STORAGE
    ////////////////////////////////////////////////////////////// */

    // Address of the Guardian.
    address public guardian;
    // Flag indicating if the repay() function is paused.
    bool public repayPaused;
    // Flag indicating if the withdraw() function is paused.
    bool public withdrawPaused;
    // Flag indicating if the borrow() function is paused.
    bool public borrowPaused;
    // Flag indicating if the deposit() function is paused.
    bool public depositPaused;
    // Flag indicating if the liquidation() function is paused.
    bool public liquidationPaused;
    // Last timestamp an emergency stop was triggered.
    uint256 public pauseTimestamp;

    /* //////////////////////////////////////////////////////////////
                                EVENTS
    ////////////////////////////////////////////////////////////// */

    event GuardianChanged(address indexed oldGuardian, address indexed newGuardian);
    event PauseUpdate(
        bool repayPauseUpdate,
        bool withdrawPauseUpdate,
        bool borrowPauseUpdate,
        bool supplyPauseUpdate,
        bool liquidationPauseUpdate
    );

    /* //////////////////////////////////////////////////////////////
                                ERRORS
    ////////////////////////////////////////////////////////////// */

    error FunctionIsPaused();

    /* //////////////////////////////////////////////////////////////
                                MODIFIERS
    ////////////////////////////////////////////////////////////// */

    /**
     * @dev Throws if called by any account other than the guardian.
     */
    modifier onlyGuardian() {
        require(msg.sender == guardian, "Guardian: Only guardian");
        _;
    }

    /**
     * @dev This modifier is used to restrict access to certain functions when the contract is paused for repay.
     * It throws if repay is paused.
     */
    modifier whenRepayNotPaused() {
        if (repayPaused) revert FunctionIsPaused();
        _;
    }

    /**
     * @dev This modifier is used to restrict access to certain functions when the contract is paused for withdraw.
     * It throws if withdraw is paused.
     */
    modifier whenWithdrawNotPaused() {
        if (withdrawPaused) revert FunctionIsPaused();
        _;
    }

    /**
     * @dev This modifier is used to restrict access to certain functions when the contract is paused for borrow.
     * It throws if borrow is paused.
     */
    modifier whenBorrowNotPaused() {
        if (borrowPaused) revert FunctionIsPaused();
        _;
    }

    /**
     * @dev This modifier is used to restrict access to certain functions when the contract is paused for deposit.
     * It throws if deposit is paused.
     */
    modifier whenDepositNotPaused() {
        if (depositPaused) revert FunctionIsPaused();
        _;
    }

    /**
     * @dev This modifier is used to restrict access to certain functions when the contract is paused for liquidation.
     * It throws if liquidation is paused.
     */
    modifier whenLiquidationNotPaused() {
        if (liquidationPaused) revert FunctionIsPaused();
        _;
    }

    /* //////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ////////////////////////////////////////////////////////////// */

    constructor() Owned(msg.sender) { }

    /* //////////////////////////////////////////////////////////////
                            GUARDIAN LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice This function is used to set the guardian address.
     * @param guardian_ The address of the new guardian.
     * @dev Allows onlyOwner to change the guardian address.
     */
    function changeGuardian(address guardian_) external onlyOwner {
        emit GuardianChanged(guardian, guardian_);

        guardian = guardian_;
    }

    /* //////////////////////////////////////////////////////////////
                            PAUSING LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice This function is used to pause all the flags of the contract.
     * @dev This function can be called by the guardian to pause all functionality in the event of an emergency.
     * This function pauses repay, withdraw, borrow, deposit and liquidation.
     * This function can only be called by the guardian.
     * The guardian can only pause the protocol again after 32 days have past since the last pause.
     * This is to prevent that a malicious guardian can take user-funds hostage for an indefinite time.
     * @dev After the guardian has paused the protocol, the owner has 30 days to find potential problems,
     * find a solution and unpause the protocol. If the protocol is not unpaused after 30 days,
     * an emergency procedure can be started by any user to unpause the protocol.
     * All users have now at least a two-day window to withdraw assets and close positions before
     * the protocol can again be paused (after 32 days).
     */
    function pause() external onlyGuardian {
        require(block.timestamp > pauseTimestamp + 32 days, "G_P: Cannot pause");
        repayPaused = true;
        withdrawPaused = true;
        borrowPaused = true;
        depositPaused = true;
        liquidationPaused = true;
        pauseTimestamp = block.timestamp;

        emit PauseUpdate(true, true, true, true, true);
    }

    /**
     * @notice This function is used to unpause one or more flags.
     * @param repayPaused_ false when repay functionality should be unPaused.
     * @param withdrawPaused_ false when withdraw functionality should be unPaused.
     * @param borrowPaused_ false when borrow functionality should be unPaused.
     * @param depositPaused_ false when deposit functionality should be unPaused.
     * @param liquidationPaused_ false when liquidation functionality should be unPaused.
     * @dev This function can unPause repay, withdraw, borrow, and deposit individually.
     * @dev Can only update flags from paused (true) to unPaused (false), cannot be used the other way around
     * (to set unPaused flags to paused).
     */
    function unPause(
        bool repayPaused_,
        bool withdrawPaused_,
        bool borrowPaused_,
        bool depositPaused_,
        bool liquidationPaused_
    ) external onlyOwner {
        repayPaused = repayPaused && repayPaused_;
        withdrawPaused = withdrawPaused && withdrawPaused_;
        borrowPaused = borrowPaused && borrowPaused_;
        depositPaused = depositPaused && depositPaused_;
        liquidationPaused = liquidationPaused && liquidationPaused_;

        emit PauseUpdate(repayPaused, withdrawPaused, borrowPaused, depositPaused, liquidationPaused);
    }

    /**
     * @notice This function is used to unPause all flags.
     * @dev If the protocol is not unpaused after 30 days, any user can unpause the protocol.
     * This ensures that no rogue owner or guardian can lock user funds for an indefinite amount of time.
     * All users have now at least a two-day window to withdraw assets and close positions before
     * the protocol can again be paused (after 32 days).
     */
    function unPause() external {
        require(block.timestamp > pauseTimestamp + 30 days, "G_UP: Cannot unPause");
        if (repayPaused || withdrawPaused || borrowPaused || depositPaused || liquidationPaused) {
            repayPaused = false;
            withdrawPaused = false;
            borrowPaused = false;
            depositPaused = false;
            liquidationPaused = false;

            emit PauseUpdate(false, false, false, false, false);
        }
    }
}