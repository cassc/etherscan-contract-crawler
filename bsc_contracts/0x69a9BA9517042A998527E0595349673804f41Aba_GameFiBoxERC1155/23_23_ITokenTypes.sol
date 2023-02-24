// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

interface ITokenTypes {
    enum TokenStandart {
        NULL,
        ERC20,
        ERC721,
        ERC1155
    }

    struct TransferredToken {
        address tokenContract;
        uint256 tokenId;
        uint256 amount;
    }
}