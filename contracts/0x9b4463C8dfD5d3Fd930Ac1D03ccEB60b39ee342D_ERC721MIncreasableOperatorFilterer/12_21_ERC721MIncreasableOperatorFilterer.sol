//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721M.sol";
import "./ERC721MIncreasableSupply.sol";
import "./OperatorFilter/DefaultOperatorFilterer.sol";

contract ERC721MIncreasableOperatorFilterer is ERC721MIncreasableSupply, DefaultOperatorFilterer {
    constructor(
        string memory collectionName,
        string memory collectionSymbol,
        string memory tokenURISuffix,
        uint256 maxMintableSupply,
        uint256 globalWalletLimit,
        address cosigner,
        uint64 timestampExpirySeconds
    )
        ERC721MIncreasableSupply(
            collectionName,
            collectionSymbol,
            tokenURISuffix,
            maxMintableSupply,
            globalWalletLimit,
            cosigner,
            timestampExpirySeconds
        )
    {}

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}