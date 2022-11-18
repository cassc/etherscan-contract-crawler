// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ICollectionBase.sol";

/**
 * Collection Drop Contract (Base)
 */
abstract contract CollectionBase is ICollectionBase {
    
    using ECDSA for bytes32;
    using Strings for uint256;

    // Immutable variables that should only be set by the constructor or initializer
    address internal _signingAddress;

    // Message nonces
    mapping(bytes32 => bool) private _usedNonces;

    // Sale start/end control
    bool public active;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public presaleInterval;

    // Claim period start/end control
    uint256 public claimStartTime;
    uint256 public claimEndTime;

    /**
     * Withdraw funds
     */
    function _withdraw(address payable recipient, uint256 amount) internal {
        (bool success,) = recipient.call{value:amount}("");
        require(success);
    }

    /**
     * Activate the sale
     */
    function _activate() internal virtual {
        require(!active, "Already active");
        active = true;
    }

    /**
     * De-Activate the sale
     */
    function _deActivate() internal virtual {
        require(active, "Not active");
        active = false;
    }

    /**
     * Deactivate the sale
     */
    function _deactivate() internal virtual {
        startTime = 0;
        endTime = 0;
        active = false;
        claimStartTime = 0;
        claimEndTime = 0;

        emit CollectionDeactivated();
    }

    function _getNonceBytes32(string memory nonce) internal pure returns(bytes32 nonceBytes32) {
        bytes memory nonceBytes = bytes(nonce);
        require(nonceBytes.length <= 32, "Invalid nonce");
        assembly {
            nonceBytes32 := mload(add(nonce, 32))
        }
    }

    /**
     * Validate claim signature
     */
    function _validateClaimRequest(bytes32 message, bytes calldata signature, string calldata nonce, uint16 amount) internal virtual {
        _validatePurchaseRequestWithAmount(message, signature, nonce, amount);
    }

    /**
     * Validate claim restrictions
     */
    function _validateClaimRestrictions() internal virtual {
        require(active, "Inactive");
        // require(block.timestamp >= claimStartTime && block.timestamp <= claimEndTime, "Outside claim period.");
    }

    /**
     * Validate purchase signature
     */
    function _validatePurchaseRequest(bytes32 message, bytes calldata signature, string calldata nonce) internal virtual { 
        // Verify nonce usage/re-use
        bytes32 nonceBytes32 = _getNonceBytes32(nonce);
        require(!_usedNonces[nonceBytes32], "Cannot replay transaction");
        // Verify valid message based on input variables
        bytes32 expectedMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", (20+bytes(nonce).length).toString(), msg.sender, nonce));
        require(message == expectedMessage, "Malformed message");
        // Verify signature was performed by the expected signing address
        address signer = message.recover(signature);
        require(signer == _signingAddress, "Invalid signature");

        _usedNonces[nonceBytes32] = true;
    }

    /**
     * Validate purchase signature with amount
     */
    function _validatePurchaseRequestWithAmount(bytes32 message, bytes calldata signature, string calldata nonce, uint16 amount) internal virtual {
        // Verify nonce usage/re-use
        bytes32 nonceBytes32 = _getNonceBytes32(nonce);
        require(!_usedNonces[nonceBytes32], "Cannot replay transaction");
        // Verify valid message based on input variables
        bytes32 expectedMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", (20+bytes(nonce).length+bytes(uint256(amount).toString()).length).toString(), msg.sender, nonce, uint256(amount).toString()));
        require(message == expectedMessage, "Malformed message");
        // Verify signature was performed by the expected signing address
        address signer = message.recover(signature);
        require(signer == _signingAddress, "Invalid signature");

        _usedNonces[nonceBytes32] = true;
    }

    /**
     * Perform purchase restriciton checks. Override if more logic is needed
     */
    function _validatePurchaseRestrictions() internal virtual {
        require(active, "Inactive");
        // require(block.timestamp >= startTime, "Purchasing not active");
    }

    /**
     * @dev See {ICollectionBase-nonceUsed}.
     */
    function nonceUsed(string memory nonce) external view override returns(bool) {
        bytes32 nonceBytes32 = _getNonceBytes32(nonce);
        return _usedNonces[nonceBytes32];
    }

    /**
     * @dev Check if currently in presale
     */
    function _isPresale() internal view returns (bool) {
        return block.timestamp > startTime && block.timestamp - startTime < presaleInterval;
    }
}