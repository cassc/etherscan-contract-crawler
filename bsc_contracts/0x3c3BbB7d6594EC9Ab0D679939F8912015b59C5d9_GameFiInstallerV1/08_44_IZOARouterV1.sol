// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

import "./IBaseRouter.sol";

interface IZOARouterV1 is IBaseRouter {
    function initialize(
        address gameFiCore_,
        address gameFiShops_,
        address gameFiMarketplace,
        uint256 avatarPropertyId_,
        uint256 usernamePropertyId_
    ) external;

    // TODO fix interfaces
}