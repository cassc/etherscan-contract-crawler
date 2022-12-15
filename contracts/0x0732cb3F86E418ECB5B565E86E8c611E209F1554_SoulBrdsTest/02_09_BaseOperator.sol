// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721A/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {DefaultOperatorFilterer} from "./OpenseaOperatorFilterRegistry/DefaultOperatorFilterer.sol";

abstract contract BaseOperator is
    ERC721A("Soulbrds", "SB"),
    DefaultOperatorFilterer,
    Ownable
{
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}