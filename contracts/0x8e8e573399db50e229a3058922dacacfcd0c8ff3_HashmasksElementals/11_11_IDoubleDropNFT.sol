// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IDoubleDropNFT {
    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * Metadata frozen. Cannot set new base URI.
     */
    error MetadataFrozen();

    /**
     * Cannot set redeemer contract multiple times
     */
    error RedeemerAlreadySet();

    /**
     * Redeemer contract not set
     */
    error RedeemerNotSet();

    /**
     * Only the redeemer contract can mint
     */
    error OnlyRedeemerCanMint();

    function redeem(uint256[] calldata _tokenIds, address _to) external;
}