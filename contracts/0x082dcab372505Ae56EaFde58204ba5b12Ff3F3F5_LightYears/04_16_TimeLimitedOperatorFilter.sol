// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Fellowship

pragma solidity ^0.8.7;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address contract_, address operator) external view returns (bool);

    function registerAndSubscribe(address contract_, address subscription) external;
}

contract TimeLimitedOperatorFilter {
    /// @notice The OpenSea OperatorFilterRegistry deployment
    IOperatorFilterRegistry private constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);
    uint256 private constant FILTER_END_DATE = 1675227600; // 2023-02-01 00:00:00 EST

    error OperatorNotAllowed(address operator);

    constructor() {
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // Subscribe to the "OpenSea Curated Subscription Address"
            OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
        }
    }

    function operatorAllowed(address operator) internal view returns (bool) {
        return
            block.timestamp >= FILTER_END_DATE ||
            address(OPERATOR_FILTER_REGISTRY).code.length == 0 ||
            OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator);
    }
}