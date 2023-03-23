// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IOwnableTwoSteps} from "./interfaces/IOwnableTwoSteps.sol";

/**
 * @title OwnableTwoSteps
 * @notice This contract offers transfer of ownership in two steps with potential owner
 *         having to confirm the transaction to become the owner.
 *         Renouncement of the ownership is also a two-step process since the next potential owner is the address(0).
 * @author LooksRare protocol team (👀,💎)
 */
abstract contract OwnableTwoSteps is IOwnableTwoSteps {
    /**
     * @notice Address of the current owner.
     */
    address public owner;

    /**
     * @notice Address of the potential owner.
     */
    address public potentialOwner;

    /**
     * @notice Ownership status.
     */
    Status public ownershipStatus;

    /**
     * @notice Modifier to wrap functions for contracts that inherit this contract.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @notice Constructor
     * @param _owner The contract's owner
     */
    constructor(address _owner) {
        owner = _owner;
        emit NewOwner(_owner);
    }

    /**
     * @notice This function is used to cancel the ownership transfer.
     * @dev This function can be used for both cancelling a transfer to a new owner and
     *      cancelling the renouncement of the ownership.
     */
    function cancelOwnershipTransfer() external onlyOwner {
        Status _ownershipStatus = ownershipStatus;
        if (_ownershipStatus == Status.NoOngoingTransfer) {
            revert NoOngoingTransferInProgress();
        }

        if (_ownershipStatus == Status.TransferInProgress) {
            delete potentialOwner;
        }

        delete ownershipStatus;

        emit CancelOwnershipTransfer();
    }

    /**
     * @notice This function is used to confirm the ownership renouncement.
     */
    function confirmOwnershipRenouncement() external onlyOwner {
        if (ownershipStatus != Status.RenouncementInProgress) {
            revert RenouncementNotInProgress();
        }

        delete owner;
        delete ownershipStatus;

        emit NewOwner(address(0));
    }

    /**
     * @notice This function is used to confirm the ownership transfer.
     * @dev This function can only be called by the current potential owner.
     */
    function confirmOwnershipTransfer() external {
        if (ownershipStatus != Status.TransferInProgress) {
            revert TransferNotInProgress();
        }

        if (msg.sender != potentialOwner) {
            revert WrongPotentialOwner();
        }

        owner = msg.sender;
        delete ownershipStatus;
        delete potentialOwner;

        emit NewOwner(msg.sender);
    }

    /**
     * @notice This function is used to initiate the transfer of ownership to a new owner.
     * @param newPotentialOwner New potential owner address
     */
    function initiateOwnershipTransfer(address newPotentialOwner) external onlyOwner {
        if (ownershipStatus != Status.NoOngoingTransfer) {
            revert TransferAlreadyInProgress();
        }

        ownershipStatus = Status.TransferInProgress;
        potentialOwner = newPotentialOwner;

        /**
         * @dev This function can only be called by the owner, so msg.sender is the owner.
         *      We don't have to SLOAD the owner again.
         */
        emit InitiateOwnershipTransfer(msg.sender, newPotentialOwner);
    }

    /**
     * @notice This function is used to initiate the ownership renouncement.
     */
    function initiateOwnershipRenouncement() external onlyOwner {
        if (ownershipStatus != Status.NoOngoingTransfer) {
            revert TransferAlreadyInProgress();
        }

        ownershipStatus = Status.RenouncementInProgress;

        emit InitiateOwnershipRenouncement();
    }

    function _onlyOwner() private view {
        if (msg.sender != owner) revert NotOwner();
    }
}