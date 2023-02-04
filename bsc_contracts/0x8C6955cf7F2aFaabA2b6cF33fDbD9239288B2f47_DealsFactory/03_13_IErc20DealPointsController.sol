// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../../IDealPointsController.sol';

interface IErc20DealPointsController is IDealPointsController {
    /// @dev creates the deal point
    /// only for factories
    function createPoint(
        uint256 dealId_,
        address from_,
        address to_,
        address token_,
        uint256 count_
    ) external;
}