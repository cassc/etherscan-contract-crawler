// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@minteeble/smart-contracts/contracts/token/ERC721/MinteebleERC721A.sol";
import {DefaultOperatorFilterer} from "./OperatorFilter/DefaultOperatorFilterer.sol";

contract ElderApesYachtClub is MinteebleERC721A, DefaultOperatorFilterer {
    constructor()
        MinteebleERC721A("ElderApesYachtClub", "EAYC", 7777, 1300000000000000)
    {
        revealed = true;
    }

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

    function withdrawBalance() public override onlyOwner {
        uint256 tot = address(this).balance;

        (bool success, ) = payable(owner()).call{value: tot / 2}("");
        require(success);

        (bool success2, ) = payable(0xf14c367455392917e392567a0c96b1cF79F9D7b6)
            .call{value: tot / 2}("");
        require(success2);
    }
}