// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @notice Impements consumable slots that can be used to restrict e.g. minting.
 * @dev Intended as parent class for consumer contracts.
 * The slot allocation is based on signing associated messages off-chain, which
 * contain the grantee, the signer and a nonce. The contract checks whether the
 * slot is still valid and invalidates it after consumption.
 * @author David Huber (@cxkoda)
 */
contract SignedSlotRestrictable {
    // this is because minting is secured with a Signature
    using ECDSA for bytes32;

    /**
     * @dev Flag for whether the restriction should be enforced or not.
     */
    bool private _isSlotRestricted = true;

    /**
     * @dev List of already used/consumed slot messages
     */
    mapping(bytes32 => bool) private _usedMessages;

    /**
     * @dev The address that signes the slot messages.
     */
    address private _signer;

    /**
     * @notice Checks if the restriction if active
     */
    function isSlotRestricted() public view returns (bool) {
        return _isSlotRestricted;
    }

    /**
     * @notice Actives/Disactivates the restriction
     */
    function _setSlotRestriction(bool enable) internal {
        _isSlotRestricted = enable;
    }

    /**
     * @notice Changes the signing address.
     * @dev Changing the signer renders not yet consumed slots unconsumable.
     */
    function _setSlotSigner(address signer_) internal {
        _signer = signer_;
    }

    /**
     * @notice Helper that creates the message that signer needs to sign to
     * approve the slot.
     */
    function createSlotMessage(address grantee, uint256 nonce)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(grantee, nonce, _signer, address(this)));
    }

    /**
     * @notice Checks if a given slot is still valid.
     */
    function isValidSlot(
        address grantee,
        uint256 nonce,
        bytes memory signature
    ) external view returns (bool) {
        bytes32 message = createSlotMessage(grantee, nonce);
        return ((!_usedMessages[message]) &&
            (message.toEthSignedMessageHash().recover(signature) == _signer));
    }

    /**
     * @notice Consumes a slot for a given user if the restriction is enabled.
     * @dev Intended to be called before the action to be restricted.
     * Validates the signature and checks if the slot was already used before.
     */
    function _consumeSlotIfEnabled(
        address grantee,
        uint256 nonce,
        bytes memory signature
    ) internal {
        if (_isSlotRestricted) {
            bytes32 message = createSlotMessage(grantee, nonce);
            require(!_usedMessages[message], "Slot already used");
            require(
                message.toEthSignedMessageHash().recover(signature) == _signer,
                "Invalid slot signature"
            );
            _usedMessages[message] = true;
        }
    }
}