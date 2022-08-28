// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC2981Royalties {
    function royaltyInfo(uint256 tokenId_, uint256 value_)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}