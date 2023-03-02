// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SCOA.sol";
import "./Constants.sol";
import "./Errors.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AccessExtension is AccessControl {
    using ECDSA for bytes32;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address private _admin; // admin address

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // grant the default admin role to the sender
        _admin = msg.sender; // set the admin
    }

    /**
     * @dev change the admin of the contract
     * @param newAdmin_ the new admin address
     */
    function changeAdmin(address newAdmin_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldAdmin = _admin; // get the old admin
        _changeAdmin(newAdmin_); // change the admin
        emit OwnershipTransferred(oldAdmin, newAdmin_); // emit the ownership transfer event
    }

    /**
     * @dev add a new creator to the contract
     * @param newCreater_ the new creator address
     */
    function addCreator(address newCreater_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addCreateRole(newCreater_); // add the creator role to the admin
    }

    /**
     * @dev add a new updater / deleter to the contract
     * @param newUpdateDeleter_ the new deleter address
     */
    function addUpdateDelete(address newUpdateDeleter_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addUpdateDeleteRole(newUpdateDeleter_); // add the burner role to the admin
    }

    /**
     * @dev remove a creator from the contract
     * @param oldCreater_ the old creator address
     */
    function removeCreator(address oldCreater_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _removeCreateRole(oldCreater_); // remove the creator role from account
    }

    /**
     * @dev remove an updater / deleter from the contract
     * @param oldDeleter_ the old deleter address
     */
    function removeUpdateDeleteRole(address oldDeleter_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _removeUpdateDeleteRole(oldDeleter_); // remove the burner role from account
    }

    /**
     * @dev Returns the owner of the contract
     * @notice This is required by the OperatorFilterer contract
     */
    function owner() public view returns (address) {
        return _admin; // return the owner
    }

    /**
     * @dev add create role to an account
     * @param newCreator_ the new creator address
     */
    function _addCreateRole(address newCreator_) internal virtual {
        _grantRole(CREATE_ROLE, newCreator_); // grant the creator role to the admin
    }

    /**
     * @dev add update / delete role to an account
     * @param newUpdateDeleter_ the new deleter addressu
     */
    function _addUpdateDeleteRole(address newUpdateDeleter_) internal virtual {
        _grantRole(UPDATE_DELETE_ROLE, newUpdateDeleter_); // grant the burner role to the admin
    }

    /**
     * @dev remove create role from an account
     * @param oldCreator_ the old creator address
     */
    function _removeCreateRole(address oldCreator_) internal virtual {
        _revokeRole(CREATE_ROLE, oldCreator_); // revoke the creator role from the admin
    }

    /**
     * @dev remove update / delete role from an account
     * @param oldDeleter_ the old deleter address
     */
    function _removeUpdateDeleteRole(address oldDeleter_) internal virtual {
        _revokeRole(UPDATE_DELETE_ROLE, oldDeleter_); // revoke the burner role from the admin
    }

    /**
     * @dev change the admin of the contract
     * @param newAdmin_ the new admin address
     */
    function _changeAdmin(address newAdmin_) internal virtual {
        _revokeRole(DEFAULT_ADMIN_ROLE, _admin); // revoke the default admin role from the sender
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin_); // grant the default admin role to the sender
        _admin = newAdmin_; // set the admin
    }

    /**
     * @dev check if the signature is valid
     * @param identity_ the identity to create
     * @param signature_ the signature to check
     */
    function _checkSignature(
        SCOA.Identity calldata identity_,
        bytes calldata signature_
    ) internal view {
        // verify that the signature is valid and get the signer address
        address signer = keccak256(
            abi.encode(
                identity_.alicePTR.namespace,
                identity_.alicePTR.curve,
                identity_.alicePTR.index,
                identity_.owner
            )
        ).toEthSignedMessageHash().recover(signature_);
        // check if the signer has the create role and is the authority in the identity
        if (!hasRole(CREATE_ROLE, signer) || signer != identity_.authority) {
            revert InvalidSignature(signature_);
        }
    }

    /**
     * @dev check if the signature is valid
     * @param to_ the address to send the certificate to
     * @param certificate_ the certificate to send
     * @param authority_ the authority of the certificate
     * @param signature_ the signature to check
     */
    function _checkSignature(
        address to_,
        SCOA.Certificate calldata certificate_,
        address authority_,
        bytes calldata signature_
    ) internal view {
        // verify that the signature is valid and get the signer address
        address signer = keccak256(
            abi.encode(
                certificate_.alicePTR.namespace,
                certificate_.alicePTR.curve,
                certificate_.alicePTR.index,
                certificate_.identity,
                to_
            )
        ).toEthSignedMessageHash().recover(signature_);
        // check if the signer has the create role or is the authority in the certificate
        if (!hasRole(CREATE_ROLE, signer) && signer != authority_) {
            revert InvalidSignature(signature_);
        }
    }

    /**
     * @dev check if the signature is valid
     * @param identity_ the identity to create
     * @param signature_ the signature to check
     */
    function _checkSignatureMemory(
        SCOA.Identity memory identity_,
        bytes memory signature_
    ) internal view {
        // verify that the signature is valid and get the signer address
        address signer = keccak256(
            abi.encode(
                identity_.alicePTR.namespace,
                identity_.alicePTR.curve,
                identity_.alicePTR.index,
                identity_.owner
            )
        ).toEthSignedMessageHash().recover(signature_);
        // check if the signer has the create role and is the authority in the identity
        if (!hasRole(CREATE_ROLE, signer) || signer != identity_.authority) {
            revert InvalidSignature(signature_);
        }
    }

    /**
     * @dev check if the signature is valid
     * @param to_ the address to send the certificate to
     * @param certificate_ the certificate to send
     * @param authority_ the authority of the certificate
     * @param signature_ the signature to check
     */
    function _checkSignatureMemory(
        address to_,
        SCOA.Certificate memory certificate_,
        address authority_,
        bytes memory signature_
    ) internal view {
        // verify that the signature is valid and get the signer address
        address signer = keccak256(
            abi.encode(
                certificate_.alicePTR.namespace,
                certificate_.alicePTR.curve,
                certificate_.alicePTR.index,
                certificate_.identity,
                to_
            )
        ).toEthSignedMessageHash().recover(signature_);
        // check if the signer has the create role or is the authority in the certificate
        if (!hasRole(CREATE_ROLE, signer) && signer != authority_) {
            revert InvalidSignature(signature_);
        }
    }
}