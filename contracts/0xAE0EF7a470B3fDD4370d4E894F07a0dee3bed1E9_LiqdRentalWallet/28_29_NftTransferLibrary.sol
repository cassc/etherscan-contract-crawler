// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../../interfaces/ICryptoPunksMarket.sol";

library NftTransferLibrary {
    enum NftTokenType {
        ERC721,
        ERC1155,
        PUNK
    }

    function transferNft(
        address from,
        address to,
        address nftAddress,
        uint256 nftTokenId,
        NftTokenType nftTokenType
    ) internal {
        if (from != to) {
            if (nftTokenType == NftTokenType.ERC721) {
                IERC721(nftAddress).safeTransferFrom(from, to, nftTokenId);
            } else if (nftTokenType == NftTokenType.ERC1155) {
                IERC1155(nftAddress).safeTransferFrom(
                    from,
                    to,
                    nftTokenId,
                    1,
                    "0x00"
                );
            } else if (nftTokenType == NftTokenType.PUNK) {
                if (from == address(this)) {
                    // transfer nft out
                    ICryptoPunksMarket(nftAddress).transferPunk(to, nftTokenId);
                } else if (to == address(this)) {
                    // transfer nft from
                    ICryptoPunksMarket(nftAddress).buyPunk(nftTokenId);
                } else {
                    revert("PUNK_TRANSFER_FAIL");
                }
            } else {
                revert("UNKNOWN_TOKEN_TYPE");
            }
        }
    }
}