// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../../../IDealPointsController.sol';

interface IErc721ItemDealPointsController is IDealPointsController {
    /// @dev creates the deal point
    function createPoint(
        uint256 dealId_,
        address from_,
        address to_,
        address token_,
        uint256 tokenId_
    ) external;

    /// @dev token id that need to transfer
    function tokenId(uint256 pointId) external view returns (uint256);
}