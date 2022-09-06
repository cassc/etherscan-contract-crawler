//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/utils/Strings.sol';

library SignerVerification {
    function isMessageVerified(
        address signer,
        bytes calldata signature,
        string calldata concatenatedParams
    ) external pure returns (bool) {
        return recoverSigner(getPrefixedHashMessage(concatenatedParams), signature) == signer;
    }

    function getSigner(bytes calldata signature, string calldata concatenatedParams) external pure returns (address) {
        return recoverSigner(getPrefixedHashMessage(concatenatedParams), signature);
    }

    function getPrefixedHashMessage(string calldata concatenatedParams) internal pure returns (bytes32) {
        uint256 messageLength = bytes(concatenatedParams).length;
        bytes memory prefix = abi.encodePacked('\x19Ethereum Signed Message:\n', Strings.toString(messageLength));
        return keccak256(abi.encodePacked(prefix, concatenatedParams));
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
    internal
    pure
    returns (
        bytes32 r,
        bytes32 s,
        uint8 v
    )
    {
        require(sig.length == 65, 'invalid signature length');

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}