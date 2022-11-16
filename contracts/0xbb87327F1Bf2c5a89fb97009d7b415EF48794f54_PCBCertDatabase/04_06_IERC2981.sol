// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC2981{
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}