// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @dev MintVoucher Struct definition used to validate EIP712.
 *
 * {wallet} wallet that the mint voucher was issued to
 * {tier} can be used for different pricing or amount checks
 * {code} voucher code that should be redeemed
 * {valid_until} timestamp until when the code is valid
 */
library LibMintVoucher {
    bytes32 private constant MINT_VOUCHER_TYPE =
        keccak256(
            "MintVoucher(address wallet,uint256 tier,string code,uint256 valid_until)"
        );

    struct MintVoucher {
        address wallet;
        uint256 tier;
        string code;
        uint256 valid_until;
    }

    function mintVoucherHash(MintVoucher memory mintVoucher)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    MINT_VOUCHER_TYPE,
                    mintVoucher.wallet,
                    mintVoucher.tier,
                    keccak256(abi.encodePacked(mintVoucher.code)),
                    mintVoucher.valid_until
                )
            );
    }
}