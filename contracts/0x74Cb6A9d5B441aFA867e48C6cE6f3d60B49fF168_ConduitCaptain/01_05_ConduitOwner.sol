// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@interfaces/ConduitCaptainInterface.sol";
import "@interfaces/ConduitControllerInterface.sol";
import "@general/TwoStepOwnable.sol";


/**
 * @title ConduitCaptain
 * @author 0age
 * @notice ConduitCaptain is an owned contract where the owner can in turn update
 *         conduits that are owned by the contract. It allows for designating an
 *         account that may revoke channels from conduits.
 */
contract ConduitCaptain is TwoStepOwnable, ConduitCaptainInterface {
    // Set the conduit controller as an immutable argument.
    ConduitControllerInterface private immutable _CONDUIT_CONTROLLER;

    // Designate a storage variable for the revoker role.
    address private _revoker;

    /**
     * @dev Initialize contract by setting the conduit controller, the initial
     *      owner, and the initial revoker role.
     */
    constructor(
        address conduitController,
        address initialOwner,
        address initialRevoker
    ) {
        // OpenSea Conduit Controller: 0x00000000F9490004C11Cef243f5400493c00Ad63
        // Ensure that a contract is deployed to the given conduit controller.
        if (conduitController.code.length == 0) {
            revert InvalidConduitController(conduitController);
        }

        // Set the conduit controller as an immutable argument.
        _CONDUIT_CONTROLLER = ConduitControllerInterface(conduitController);

        // Set the initial owner.
        _setInitialOwner(initialOwner);

        // Set the initial revoker.
        _setRevoker(initialRevoker);
    }

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
    ) external override onlyOwner {
        // Call the conduit controller to transfer conduit ownership.
        _CONDUIT_CONTROLLER.transferOwnership(conduit, newPotentialOwner);
    }

    /**
     * @notice Clear the currently set potential owner, if any, from a conduit.
     *         Only callable by the owner.
     *
     * @param conduit The conduit for which to cancel ownership transfer.
     */
    function cancelConduitOwnershipTransfer(address conduit)
        external
        override
        onlyOwner
    {
        // Call the conduit controller to cancel conduit ownership transfer.
        _CONDUIT_CONTROLLER.cancelOwnershipTransfer(conduit);
    }

    /**
     * @notice Accept ownership of a given conduit once this contract has been
     *         set as the current potential owner. Only callable by the owner.
     *
     * @param conduit The conduit for which to accept ownership transfer.
     */
    function acceptConduitOwnership(address conduit)
        external
        override
        onlyOwner
    {
        // Call the conduit controller to accept conduit ownership.
        _CONDUIT_CONTROLLER.acceptOwnership(conduit);
    }

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
    ) external override onlyOwner {
        // Call the conduit controller to update channel status on the conduit.
        _CONDUIT_CONTROLLER.updateChannel(conduit, channel, isOpen);
    }

    /**
     * @notice Close a channel on a given conduit, thereby preventing the
     *         specified account from executing transfers against that conduit.
     *         Only the designated revoker may call this function.
     *
     * @param conduit The conduit for which to close the channel.
     * @param channel The channel to close on the conduit.
     */
    function closeChannel(address conduit, address channel) external override {
        // Revert if the caller is not the revoker.
        if (msg.sender != _revoker) {
            revert InvalidRevoker();
        }

        // Call the conduit controller to close the channel on the conduit.
        _CONDUIT_CONTROLLER.updateChannel(conduit, channel, false);
    }

    /**
     * @notice Set a revoker role that can close channels. Only the owner may
     *         call this function.
     *
     * @param revoker The account to set as the revoker.
     */
    function updateRevoker(address revoker) external override onlyOwner {
        // Assign the new revoker role.
        _setRevoker(revoker);
    }

    /**
     * @notice External view function to retrieve the address of the revoker
     *         role that can close channels.
     *
     * @return revoker The account set as the revoker.
     */
    function getRevoker() external view override returns (address revoker) {
        return _revoker;
    }

    /**
     * @notice External view function to retrieve the address of the
     *         ConduitController referenced by the contract
     *
     * @return conduitController The address of the ConduitController.
     */
    function getConduitController()
        external
        view
        override
        returns (address conduitController)
    {
        return address(_CONDUIT_CONTROLLER);
    }

    /**
     * @notice Internal function to set a revoker role that can close channels.
     *
     * @param revoker The account to set as the revoker.
     */
    function _setRevoker(address revoker) internal {
        // Revert if no address is supplied for the revoker role.
        if (revoker == address(0)) {
            revert RevokerIsNullAddress();
        }

        // Assign the new revoker role.
        _revoker = revoker;
        emit RevokerUpdated(revoker);
    }
}