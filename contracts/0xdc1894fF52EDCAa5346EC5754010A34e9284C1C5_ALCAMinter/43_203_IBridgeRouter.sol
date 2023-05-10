// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IBridgeRouter {
    function routeDeposit(
        address account_,
        uint8 routerVersion_,
        bytes calldata data_
    ) external returns (uint256);
}