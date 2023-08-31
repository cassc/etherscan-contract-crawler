// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

/**
 * @title NativeMetaTransaction interface. Used by eg. wETH on Polygon
 * @author [email protected]
 */
interface INativeMetaTransaction {
    /**
     * @notice Meta-transaction object
     * @param nonce Account nonce
     * @param from Account to be considered as sender
     * @param functionSignature Function to call on contract, with arguments encoded
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    /**
     * @notice Execute meta transaction on contract containing EIP-712 stuff natively
     * @param userAddress User to be considered as sender
     * @param functionSignature Function to call on contract, with arguments encoded
     * @param sigR Elliptic curve signature component
     * @param sigS Elliptic curve signature component
     * @param sigV Elliptic curve signature component
     */
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory);
}