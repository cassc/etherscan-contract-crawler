// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IErc721CountDealPointsController {
    /// @dev creates the deal point
    function createPoint(
        uint256 dealId_,
        address from_,
        address to_,
        address token_,
        uint256 count_
    ) external;

    /// @dev all tokens, that stores deal point
    function tokensId(uint256 pointId) external view returns (uint256[] memory);
}