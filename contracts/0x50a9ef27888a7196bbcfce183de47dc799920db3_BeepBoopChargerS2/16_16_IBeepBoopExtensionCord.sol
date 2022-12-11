// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC721A} from "@erc721a/IERC721A.sol";

interface IBeepBoopExtensionCord is IERC721A {
    /**
     * @notice Burns an nft
     */
    function burn(uint256 tokenId) external;

    /**
     * @notice Burns many nfts at once
     */
    function burnMany(uint256[] memory tokenIds) external;
}