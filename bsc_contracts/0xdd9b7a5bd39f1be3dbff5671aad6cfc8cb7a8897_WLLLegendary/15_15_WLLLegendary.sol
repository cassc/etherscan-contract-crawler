// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./WLLCard.sol";

contract WLLLegendary is WLLCard {
    using Strings for uint256;

    constructor() WLLCard("WorldLeagueLiveADP", "WLL_ADP10") {}

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (
            address(metadataContract) != address(0) &&
            metadataContract.hasOnchainMetadata(tokenId)
        ) {
            return metadataContract.tokenURI(tokenId);
        } else {
            string memory baseURI = _baseURI();
            uint256 campaignId = tokenIdToCampaignId[tokenId];
            return
                bytes(baseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            baseURI,
                            campaignId.toString(),
                            "/",
                            tokenId.toString()
                        )
                    )
                    : "";
        }
    }
}