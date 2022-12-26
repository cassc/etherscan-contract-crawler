pragma solidity ^0.8.0;

contract BridgeStructs {
    struct Transfer {
        // PayloadID uint8 = 1
        uint8 payloadID;
        // Amount being transferred (big-endian uint256)
        uint256 amount;
        // Address of the token on remote chain. Left-zero-padded if shorter than 32 bytes
        bytes32 tokenAddressOnRemoteChain;
        // Address of the token on origin chain
        bytes32 tokenAddressOrigin;
        // Address of the sender
        bytes32 fromAddressSender;
        // Address of the recipient. Left-zero-padded if shorter than 32 bytes
        bytes32 toAddressRecipient;
        // Chain ID of the sender
        uint16 tokenChainRemoteId;
        // Chain ID of the recipient
        uint16 tokenChainOriginId;
    }
}