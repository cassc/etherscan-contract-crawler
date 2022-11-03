// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISymbiosisMetaRouter {
    struct MetaRouteArgs {
        bytes firstSwapCalldata;
        bytes secondSwapCalldata;
        address[] approvedTokens;
        address firstDexRouter;
        address secondDexRouter;
        uint256 amount;
        bool nativeIn;
        address relayRecipient;
        bytes otherSideCalldata;
    }

    function metaRoute(MetaRouteArgs memory args) external payable;
}