// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library Whitelist {
    function verifySignatureWhenBuyDNFT(
        uint256 _nonces,
        uint8 _salePhase,
        address _signer,
        address _candidate,
        bytes memory _signature
    ) internal pure returns (bool) {
        bytes32 messageHash = getMessageHashWhenBuyDNFT(_nonces, _salePhase, _signer, _candidate);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        address signerAddress = getSignerAddress(ethSignedMessageHash, _signature);
        return signerAddress == _signer;
    }

    function verifySignatureWhenMergeDNFT(
        uint256 _nonces,
        address _signer,
        bytes memory _bytesToVerify,
        bytes memory _signature
    ) internal pure returns (bool) {
        bytes32 messageHash = getMessageHashWhenMergeDNFT(_nonces, _signer, _bytesToVerify);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        address signerAddress = getSignerAddress(ethSignedMessageHash, _signature);
        return signerAddress == _signer;
    }

    function verifySignatureWhenBuyKey(
        address _signer,
        uint256 _nonce,
        address _to,
        bytes memory _signature
    ) internal pure returns (bool) {
        bytes32 messageHash = getMessageHashWhenBuyKey(_signer, _nonce, _to);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        address signerAddress = getSignerAddress(ethSignedMessageHash, _signature);
        return signerAddress == _signer;
    }

    function getMessageHashWhenBuyDNFT(
        uint256 _nonces,
        uint8 _salePhase,
        address _signer,
        address _candidate
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_nonces, _salePhase, _signer, _candidate));
    }

    function getMessageHashWhenMergeDNFT(
        uint256 _nonces,
        address _signer,
        bytes memory _bytesToVerify
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_nonces, _signer, _bytesToVerify));
    }

    function getMessageHashWhenBuyKey(
        address _signer,
        uint256 _nonce,
        address _to
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_signer, _nonce, _to));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(_messageHash);
    }

    function getSignerAddress(bytes32 _messageHash, bytes memory _signature) internal pure returns (address) {
        return ECDSA.recover(_messageHash, _signature);
    }
}