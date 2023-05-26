// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title BNV Goggle Contract Interface
/// @author BNV Team
/// @dev based on a standard ERC1155
interface IBNVGoggle is IERC1155 {
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external;

    function mintBatch(
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external;

    // VIEW ONLY =======================================
}