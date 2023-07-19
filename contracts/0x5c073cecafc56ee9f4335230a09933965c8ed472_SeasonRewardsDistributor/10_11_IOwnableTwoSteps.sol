// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title IOwnableTwoSteps
 * @author LooksRare protocol team (👀,💎)
 */
interface IOwnableTwoSteps {
    /**
     * @notice This enum keeps track of the ownership status.
     * @param NoOngoingTransfer The default status when the owner is set
     * @param TransferInProgress The status when a transfer to a new owner is initialized
     * @param RenouncementInProgress The status when a transfer to address(0) is initialized
     */
    enum Status {
        NoOngoingTransfer,
        TransferInProgress,
        RenouncementInProgress
    }

    /**
     * @notice This is returned when there is no transfer of ownership in progress.
     */
    error NoOngoingTransferInProgress();

    /**
     * @notice This is returned when the caller is not the owner.
     */
    error NotOwner();

    /**
     * @notice This is returned when there is no renouncement in progress but
     *         the owner tries to validate the ownership renouncement.
     */
    error RenouncementNotInProgress();

    /**
     * @notice This is returned when the transfer is already in progress but the owner tries
     *         initiate a new ownership transfer.
     */
    error TransferAlreadyInProgress();

    /**
     * @notice This is returned when there is no ownership transfer in progress but the
     *         ownership change tries to be approved.
     */
    error TransferNotInProgress();

    /**
     * @notice This is returned when the ownership transfer is attempted to be validated by the
     *         a caller that is not the potential owner.
     */
    error WrongPotentialOwner();

    /**
     * @notice This is emitted if the ownership transfer is cancelled.
     */
    event CancelOwnershipTransfer();

    /**
     * @notice This is emitted if the ownership renouncement is initiated.
     */
    event InitiateOwnershipRenouncement();

    /**
     * @notice This is emitted if the ownership transfer is initiated.
     * @param previousOwner Previous/current owner
     * @param potentialOwner Potential/future owner
     */
    event InitiateOwnershipTransfer(address previousOwner, address potentialOwner);

    /**
     * @notice This is emitted when there is a new owner.
     */
    event NewOwner(address newOwner);
}