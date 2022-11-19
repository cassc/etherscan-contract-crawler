// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IRangoSymbiosis.sol";

interface ISymbiosisMetaRouter {
    function metaRoute(IRangoSymbiosis.MetaRouteTransaction calldata _metaRouteTransaction) external payable;
}