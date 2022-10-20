// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IPlearnNFT is IERC721Enumerable {
    function mint(
        uint256 reservedRangeId,
        address to,
        uint256 tokenId
    ) external;
}