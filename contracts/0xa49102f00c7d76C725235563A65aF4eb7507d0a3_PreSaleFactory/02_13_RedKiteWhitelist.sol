// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";

// Signature Verification
/// @title RedKite Whitelists - Implement off-chain whitelist and on-chain verification
/// @author Thang Nguyen Quy <[email protected]>

contract RedKiteWhitelist {
    // Using Openzeppelin ECDSA cryptography library
    function getMessageHash(
        address _candidate,
        uint256 _maxAmount,
        uint256 _minAmount
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_candidate, _maxAmount, _minAmount));
    }

    function getClaimMessageHash(
        address _candidate,
        uint256 _amount
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_candidate, _amount));
    }

    // Verify signature function
    function verify(
        address _signer,
        address _candidate,
        uint256 _maxAmount,
        uint256 _minAmount,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_candidate, _maxAmount, _minAmount);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return getSignerAddress(ethSignedMessageHash, signature) == _signer;
    }

    // Verify signature function
    function verifyClaimToken(
        address _signer,
        address _candidate,
        uint256 _amount,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getClaimMessageHash(_candidate, _amount);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return getSignerAddress(ethSignedMessageHash, signature) == _signer;
    }

    function getSignerAddress(bytes32 _messageHash, bytes memory _signature) public pure returns(address signer) {
        return ECDSA.recover(_messageHash, _signature);
    }

    // Split signature to r, s, v
    function splitSignature(bytes memory _signature)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_signature.length == 65, "invalid signature length");

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(_messageHash);
    }
}