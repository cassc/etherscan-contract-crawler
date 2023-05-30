// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SignatureVerify
{
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                  SIGNATURE VERIFYING
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function getMessageHash(
        address to,
        uint256[] calldata tokenIndices,
        uint256[] calldata mintAmounts,
        uint256 networkName,
        address contractAddress,
        uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            to, 
            tokenIndices, 
            mintAmounts,
            networkName,
            contractAddress,
            nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(
    // Address
        address signer,
        address to,

    // Token Request
        uint256[] calldata tokenIndices,
        uint256[] calldata mintAmounts,
        uint256 networkName,
        address contractAddress,
        uint256 nonce,

    // // Epoch Time
    //     uint256 epochTime,

    // Signature to compare to
        bytes memory signature) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(to, 
        tokenIndices, 
        mintAmounts, 
        networkName, 
        contractAddress, 
        nonce);//, epochTime);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function recoverSigner(
        bytes32 ethSignedMessageHash, 
        bytes memory signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (
        bytes32 r,
        bytes32 s,
        uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}