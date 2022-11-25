//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title INFTAssist
 * @author gotbit
 */

interface INFTAssist {
    enum NFTType {
        NULL,
        ERC721,
        ERC1155
    }
    struct NFT {
        address nftContract;
        uint256 tokenId;
        string tokenURI;
        NFTType nftType;
    }

    error WrongNFTType();
    error CallerIsNotNFTOwner();
}