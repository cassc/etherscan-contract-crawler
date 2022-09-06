// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/ICryptoPunksMarket.sol";

library NFTs {
    address constant CRYPTOPUNKS = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;

    function ownerOf(address token, uint256 tokenId) internal view returns (address) {
        if (token == CRYPTOPUNKS) {
            return ICryptoPunksMarket(token).punkIndexToAddress(tokenId);
        } else {
            return IERC721(token).ownerOf(tokenId);
        }
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) internal {
        if (token == CRYPTOPUNKS) {
            // ICryptoPunksMarket.offerPunkForSaleToAddress() should have been called by the owner prior to this call
            ICryptoPunksMarket(token).buyPunk(tokenId);
            if (to != address(this)) {
                ICryptoPunksMarket(token).transferPunk(to, tokenId);
            }
        } else {
            IERC721(token).safeTransferFrom(from, to, tokenId);
        }
    }
}