// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IERC721Common {
    struct ERC721CommonConfig {
        string contractURI;
        string baseURI;
        address[] minters;
        address metadataManager;
        address royaltyReceiver;
        uint96 royaltyFeeNumerator;
    }
}