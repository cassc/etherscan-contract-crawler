// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./_IERC165.sol";

interface _IERC2981 is _IERC165 {
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}