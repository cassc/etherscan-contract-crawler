// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./AdapterBase.sol";
import "../libraries/Transfers.sol";
import "../interfaces/external/ISymbiosisMetaRouter.sol";

contract SymbiosisAdapter is AdapterBase {
    using Transfers for address;

    /// @notice Adapter constructor
    /// @param target_ Target contract for this adapter
    constructor(address target_) AdapterBase(target_) {}

    struct MetaRouteArgs {
        bytes firstSwapCalldata;
        bytes secondSwapCalldata;
        address[] approvedTokens;
        address firstDexRouter;
        address secondDexRouter;
        bool nativeIn;
        address relayRecipient;
        bytes otherSideCalldata;
        address approveTo;
    }

    /// @inheritdoc AdapterBase
    function call(
        address assetIn,
        uint256 amountIn,
        uint256,
        bytes memory args
    ) external payable override {
        MetaRouteArgs memory routeArgs = abi.decode(args, (MetaRouteArgs));

        if (!routeArgs.nativeIn) {
            assetIn.approve(routeArgs.approveTo, amountIn);
        }

        uint256 value = routeArgs.nativeIn ? amountIn : 0;
        ISymbiosisMetaRouter(target).metaRoute{value: value}(
            ISymbiosisMetaRouter.MetaRouteArgs({
                firstSwapCalldata: routeArgs.firstSwapCalldata,
                secondSwapCalldata: routeArgs.secondSwapCalldata,
                approvedTokens: routeArgs.approvedTokens,
                firstDexRouter: routeArgs.firstDexRouter,
                secondDexRouter: routeArgs.secondDexRouter,
                amount: amountIn,
                nativeIn: routeArgs.nativeIn,
                relayRecipient: routeArgs.relayRecipient,
                otherSideCalldata: routeArgs.otherSideCalldata
            })
        );
    }
}