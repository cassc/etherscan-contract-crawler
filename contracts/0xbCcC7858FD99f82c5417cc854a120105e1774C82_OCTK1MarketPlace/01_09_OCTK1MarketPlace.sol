// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-0.8/token/ERC1155/IERC1155.sol";
import "./MarketPlaceERC1155.sol";

/**
 * @title OCTK1MarketPlace is the marketplace for OCTK1 Token deployed by Octofan.
 * @dev OCTK1.
 */
contract OCTK1MarketPlace is MarketPlaceERC1155 {
    constructor(
        IERC1155 ierc1155,
        uint256[] memory tokenIds,
        uint256[] memory unitPriceInETH,
        address payable marketPlaceAddress
    ) MarketPlaceERC1155(ierc1155, tokenIds, unitPriceInETH, marketPlaceAddress) {}
}