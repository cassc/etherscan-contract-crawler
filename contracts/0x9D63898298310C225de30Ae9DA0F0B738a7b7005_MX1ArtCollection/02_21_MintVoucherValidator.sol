// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./LibMintVoucher.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/**
 * @dev EIP712 based contract module which validates a MintVoucher Issued by
 * Bowline. The signer is {SIGNER_WALLET} and checks for integrity of
 * minterCategory, amount and Address. {mintVoucher} is struct defined in
 * LibMintVoucher.
 *
 */
abstract contract MintVoucherValidator is EIP712 {
    constructor(string memory _voucherName, string memory _version)
        EIP712(_voucherName, _version)
    {}

    // Wallet that signs our mintVoucheres
    address public SIGNER_WALLET;

    /**
     * @dev Validates if {mintVoucher} was signed by {SIGNER_WALLET} and created {signature}.
     *
     * @param mintVoucher Struct with mintVoucher properties
     * @param signature Signature to decode and compare
     */
    function validateMintVoucher(LibMintVoucher.MintVoucher memory mintVoucher, bytes memory signature)
        internal
        view
    {
        bytes32 mintVoucherHash = LibMintVoucher.mintVoucherHash(mintVoucher);
        bytes32 digest = _hashTypedDataV4(mintVoucherHash);
        address signer = ECDSA.recover(digest, signature);

        require(
            signer == SIGNER_WALLET,
            "MintVoucherValidator: MintVoucher signature verification error"
        );
        require(
            mintVoucher.valid_until >= block.timestamp,
            "MintVoucherValidator: MintVoucher is not valid anymore"
        );
    }
}