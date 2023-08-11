// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

/**
 @notice This contract manages the role-based access control via _checkRole() with meaningful 
 error messages if the user does not have the requested role. This contract is inherited by 
 PolicyManager, RuleRegistry, KeyringCredentials, IdentityTree, WalletCheck and 
 KeyringZkCredentialUpdater.
 */

abstract contract KeyringAccessControl is ERC2771Context, AccessControl {

    address private constant NULL_ADDRESS = address(0);

    // Reservations hold space in upgradeable contracts for future versions of this module.
    bytes32[50] private _reservedSlots;

    error Unacceptable(string reason);

    error Unauthorized(
        address sender,
        string module,
        string method,
        bytes32 role,
        string reason,
        string context
    );

    /**
     * @param trustedForwarder Contract address that is allowed to relay message signers.
     */
    constructor(address trustedForwarder) ERC2771Context(trustedForwarder) {
        if (trustedForwarder == NULL_ADDRESS)
            revert Unacceptable({
                reason: "trustedForwarder cannot be empty"
            });
    }

    /**
     * @notice Disables incomplete ERC165 support inherited from oz/AccessControl.sol
     * @return bool Never returned.
     * @dev Always reverts. Do not rely on ERC165 support to interact with this contract.
     */
    function supportsInterface(bytes4 /*interfaceId */) public view virtual override returns (bool) {
        revert Unacceptable ({ reason: "ERC2165 is unsupported" });
    }

    /**
     * @notice Role-based access control.
     * @dev Reverts if the account is missing the role.
     * @param role The role to check. 
     * @param account An address to check for the role.
     * @param context For reporting purposes. Usually the function that requested the permission check.
     */
    function _checkRole(
        bytes32 role,
        address account,
        string memory context
    ) internal view {
        if (!hasRole(role, account))
            revert Unauthorized({
                sender: account,
                module: "KeyringAccessControl",
                method: "_checkRole",
                role: role,
                reason: "sender does not have the required role",
                context: context
            });
    }

    /**
     * @notice Returns ERC2771 signer if msg.sender is a trusted forwarder, otherwise returns msg.sender.
     * @return sender User deemed to have signed the transaction.
     */
    function _msgSender()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (address sender)
    {
        return ERC2771Context._msgSender();
    }

    /**
     * @notice Returns msg.data if not from a trusted forwarder, or truncated msg.data if the signer was 
     appended to msg.data
     * @dev Although not currently used, this function forms part of ERC2771 so is included for completeness.
     * @return data Data deemed to be the msg.data
     */
    function _msgData()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }
}