// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library SignedPass {
    using ECDSA for bytes32;

    function verifyAddressSignedPass(
        string memory prefix,
        address addr,
        bytes memory signedMessage,
        address expectedSigner
    ) internal pure returns (bool) {
        address actualSigner = recoverSignerFromSignedPass(
            prefix,
            addr,
            signedMessage
        );
        return actualSigner == expectedSigner;
    }

    function recoverSignerFromSignedPass(
        string memory prefix,
        address addr,
        bytes memory signedMessage
    ) internal pure returns (address) {
        bytes32 message = getHash(prefix, addr);
        return recover(message, signedMessage);
    }

    function getHash(string memory prefix, address addr)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(prefix, addr));
    }

    function recover(bytes32 hash, bytes memory signedMessage)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(signedMessage);
    }
}