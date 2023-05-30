// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./ICollectionBase.sol";

/**
 * Collection Drop Contract (Base)
 */
abstract contract CollectionBase is ICollectionBase {
    
    using ECDSA for bytes32;

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
    function _activate(uint256 startTime_, uint256 duration, uint256 presaleInterval_, uint256 claimStartTime_, uint256 claimEndTime_) internal virtual {
        require(!active, "Already active");
        require(startTime_ > block.timestamp, "Cannot activate in the past");
        require(presaleInterval_ <= duration, "Presale Interval cannot be longer than the sale");
        require(claimStartTime_ <= claimEndTime_ && claimEndTime_ <= startTime_, "Invalid claim times");
        startTime = startTime_;
        endTime = startTime + duration;
        presaleInterval = presaleInterval_;
        claimStartTime = claimStartTime_;
        claimEndTime = claimEndTime_;
        active = true;

        emit CollectionActivated(startTime, endTime, presaleInterval, claimStartTime, claimEndTime);
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

    /**
     * Validate claim signature
     */
    function _validateClaimRequest(bytes32 message, bytes calldata signature, bytes32 nonce, uint16 amount) internal virtual {
        _validatePurchaseRequestWithAmount(message, signature, nonce, amount);
    }

    /**
     * Validate claim restrictions
     */
    function _validateClaimRestrictions() internal virtual {
        require(active, "Inactive");
        require(block.timestamp >= claimStartTime && block.timestamp <= claimEndTime, "Outside claim period.");
    }

    /**
     * Validate purchase signature
     */
    function _validatePurchaseRequest(bytes32 message, bytes calldata signature, bytes32 nonce) internal virtual { 
        // Verify nonce usage/re-use
        require(!_usedNonces[nonce], "Cannot replay transaction");
        // Verify valid message based on input variables
        bytes32 expectedMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n52", msg.sender, nonce));
        require(message == expectedMessage, "Malformed message");
        // Verify signature was performed by the expected signing address
        address signer = message.recover(signature);
        require(signer == _signingAddress, "Invalid signature");

        _usedNonces[nonce] = true;
    }

    /**
     * Validate purchase signature with amount
     */
    function _validatePurchaseRequestWithAmount(bytes32 message, bytes calldata signature, bytes32 nonce, uint16 amount) internal virtual {
        // Verify nonce usage/re-use
        require(!_usedNonces[nonce], "Cannot replay transaction");
        // Verify valid message based on input variables
        bytes32 expectedMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n54", msg.sender, nonce, amount));
        require(message == expectedMessage, "Malformed message");
        // Verify signature was performed by the expected signing address
        address signer = message.recover(signature);
        require(signer == _signingAddress, "Invalid signature");

        _usedNonces[nonce] = true;
    }

    /**
     * Perform purchase restriciton checks. Override if more logic is needed
     */
    function _validatePurchaseRestrictions() internal virtual {
        require(active, "Inactive");
        require(block.timestamp >= startTime, "Purchasing not active");
    }

    /**
     * @dev See {ICollectionBase-nonceUsed}.
     */
    function nonceUsed(bytes32 nonce) external view override returns(bool) {
        return _usedNonces[nonce];
    }

    /**
     * @dev Check if currently in presale
     */
    function _isPresale() internal view returns (bool) {
        return block.timestamp > startTime && block.timestamp - startTime < presaleInterval;
    }
}