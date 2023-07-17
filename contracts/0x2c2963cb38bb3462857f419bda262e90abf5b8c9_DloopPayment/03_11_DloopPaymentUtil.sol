// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";

contract DloopPaymentUtil {
    function validateSignature(
        bytes32 hash,
        bytes memory sig,
        address expectedSigner
    ) public pure returns (bool) {
        bytes32 ethSignedHash = ECDSA.toEthSignedMessageHash(hash);
        address actualSigner = ECDSA.recover(ethSignedHash, sig);
        return actualSigner == expectedSigner;
    }

    function createHash(
        uint256 artistId,
        uint64 artworkId,
        uint256 tokenId,
        uint64 checkoutId,
        address dloopAddress,
        uint256 dloopAmount,
        address artistAddress,
        uint256 artistAmount,
        uint256 maxEthAmount,
        uint256 expiresAt
    ) public pure returns (bytes32) {
        bytes memory encodedParams = abi.encodePacked(
            artistId,
            artworkId,
            tokenId,
            checkoutId,
            dloopAddress,
            dloopAmount,
            artistAddress,
            artistAmount,
            maxEthAmount,
            expiresAt
        );
        return keccak256(encodedParams);
    }
}