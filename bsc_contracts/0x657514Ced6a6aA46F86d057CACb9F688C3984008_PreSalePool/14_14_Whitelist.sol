// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library Whitelist {
    function verifySignature(
        uint256 _nonce,
        uint8 _salePhase,
        address _signer,
        address _candidate,
        uint256 _BUSDAmount,
        bytes memory _signature
    ) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(_nonce, _salePhase, _signer, _candidate, _BUSDAmount);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        address signerAddress = getSignerAddress(ethSignedMessageHash, _signature);
        return signerAddress == _signer;
    }

    function getMessageHash(
        uint256 _nonce,
        uint8 _salePhase,
        address _signer,
        address _candidate,
        uint256 _BUSDAmount
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_nonce, _salePhase, _signer, _candidate, _BUSDAmount));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(_messageHash);
    }

    function getSignerAddress(bytes32 _messageHash, bytes memory _signature) internal pure returns (address) {
        return ECDSA.recover(_messageHash, _signature);
    }
}