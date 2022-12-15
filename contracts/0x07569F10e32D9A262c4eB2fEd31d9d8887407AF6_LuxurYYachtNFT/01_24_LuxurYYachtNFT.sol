// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@minteeble/smart-contracts/contracts/token/ERC721/MinteebleERC721A.sol";
import {DefaultOperatorFilterer} from "./OperatorFilter/DefaultOperatorFilterer.sol";

contract LuxurYYachtNFT is MinteebleERC721A, DefaultOperatorFilterer {
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        uint256 _mintPrice
    ) MinteebleERC721A(_tokenName, _tokenSymbol, _maxSupply, _mintPrice) {}

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}