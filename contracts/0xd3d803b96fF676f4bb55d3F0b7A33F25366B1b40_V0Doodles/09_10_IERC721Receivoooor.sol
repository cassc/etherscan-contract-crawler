// SPDX-License-Identifier: Unlicense
// Creator: Scroungy Labs
// BurningZeppelin Contracts (last updated v-0.0.1) (token/ERC721/IERC721Receivoooor.sol)

pragma solidity ^0.8.9;

interface IERC721Receivoooor {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/******************/