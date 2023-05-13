// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title ConduitCaptainInterface
 * @author 0age
 * @notice ConduitCaptainInterface contains function endpoints, events, and error
 *         declarations for the ConduitCaptain contract.
 */
interface ConduitCaptainInterface {
    /**
     * @dev Emit an event whenever a revoker role is updated by the owner.
     *
     * @param revoker The address of the new revoker role.
     */
    event RevokerUpdated(address revoker);

    /**
     * @dev Revert with an error when attempting to set a conduit controller
     *      that does not contain contract code.
     */
    error InvalidConduitController(address conduitController);

    /**
     * @dev Revert with an error when attempting to call closeChannel from an
     *      account that does not currently hold the revoker role.
     */
    error InvalidRevoker();

    /**
     * @dev Revert with an error when attempting to register a revoker and
     *      supplying the null address.
     */
    error RevokerIsNullAddress();

    /**
     * @notice Initiate conduit ownership transfer by assigning a new potential
     *         owner for the given conduit. Only callable by the owner.
     *
     * @param conduit           The conduit for which to initiate ownership
     *                          transfer.
     * @param newPotentialOwner The new potential owner to set.
     */
    function transferConduitOwnership(
        address conduit,
        address newPotentialOwner
    ) external;

    /**
     * @notice Clear the currently set potential owner, if any, from a conduit.
     *         Only callable by the owner.
     *
     * @param conduit The conduit for which to cancel ownership transfer.
     */
    function cancelConduitOwnershipTransfer(address conduit) external;

    /**
     * @notice Accept ownership of a given conduit once this contract has been
     *         set as the current potential owner. Only callable by the owner.
     *
     * @param conduit The conduit for which to accept ownership transfer.
     */
    function acceptConduitOwnership(address conduit) external;

    /**
     * @notice Open or close a channel on a given conduit, thereby allowing the
     *         specified account to execute transfers against that conduit.
     *         Extreme care must be taken when updating channels, as malicious
     *         or vulnerable channels can transfer any ERC20, ERC721 and ERC1155
     *         tokens where the token holder has granted the conduit approval.
     *         Only the owner may call this function.
     *
     * @param conduit The conduit for which to open or close the channel.
     * @param channel The channel to open or close on the conduit.
     * @param isOpen  A boolean indicating whether to open or close the channel.
     */
    function updateChannel(
        address conduit,
        address channel,
        bool isOpen
    ) external;

    /**
     * @notice Close a channel on a given conduit, thereby preventing the
     *         specified account from executing transfers against that conduit.
     *         Only the designated revoker may call this function.
     *
     * @param conduit The conduit for which to close the channel.
     * @param channel The channel to close on the conduit.
     */
    function closeChannel(address conduit, address channel) external;

    /**
     * @notice Set a revoker role that can close channels. Only the owner may
     *         call this function.
     *
     * @param revoker The account to set as the revoker.
     */
    function updateRevoker(address revoker) external;

    /**
     * @notice External view function to retrieve the address of the revoker
     *         role that can close channels.
     *
     * @return revoker The account set as the revoker.
     */
    function getRevoker() external view returns (address revoker);

    /**
     * @notice External view function to retrieve the address of the
     *         ConduitController referenced by the contract
     *
     * @return conduitController The address of the ConduitController.
     */
    function getConduitController()
        external
        view
        returns (address conduitController);
}