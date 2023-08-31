// contracts/Structs.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

contract CATERC20Structs {
    struct CrossChainPayload {
        // Amount being transferred (big-endian uint256)
        uint256 amount;
        // Address of the token. Left-zero-padded if shorter than 32 bytes
        bytes32 tokenAddress;
        // Chain ID of the token
        uint16 tokenChain;
        // Address of the recipient. Left-zero-padded if shorter than 32 bytes
        bytes32 toAddress;
        // Chain ID of the recipient
        uint16 toChain;
        // Token Decimals of sender chain
        uint8 tokenDecimals;
    }

    struct SignatureVerification {
        // Address of custodian the user has delegated to sign transaction on behalf of
        address custodian;
        // Timestamp the transaction will be valid till
        uint256 validTill;
        // Signed Signature
        bytes signature;
    }
}