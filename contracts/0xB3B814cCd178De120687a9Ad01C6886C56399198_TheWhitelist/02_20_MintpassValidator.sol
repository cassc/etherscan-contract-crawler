// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./LibMintpass.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/**
 * @dev EIP712 based contract module which validates a Mintpass Issued by
 * The Whitelist. The signer is {ACE_WALLET} and checks for integrity of
 * minterCategory, amount and Address. {mintpass} is struct defined in
 * LibMintpass.
 *
 */
abstract contract MintpassValidator is EIP712 {
    constructor() EIP712("TheWhitelist", "1") {}

    // Wallet that signs our mintpasses
    address public ACE_WALLET;

    /**
     * @dev Validates if {mintpass} was signed by {ACE_WALLET} and created {signature}.
     *
     * @param mintpass Struct with mintpass properties
     * @param signature Signature to decode and compare
     */
    function validateMintpass(LibMintpass.Mintpass memory mintpass, bytes memory signature)
        internal
        view
    {
        bytes32 mintpassHash = LibMintpass.mintpassHash(mintpass);
        bytes32 digest = _hashTypedDataV4(mintpassHash);
        address signer = ECDSA.recover(digest, signature);

        require(
            signer == ACE_WALLET,
            "MintpassValidator: Mintpass signature verification error"
        );
    }
}