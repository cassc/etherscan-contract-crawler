// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../MetaRouteStructs.sol";

interface IMetaRouter {
    function metaRoute(
        MetaRouteStructs.MetaRouteTransaction calldata _metarouteTransaction
    ) external payable;

    function externalCall(
        address _token,
        uint256 _amount,
        address _receiveSide,
        bytes calldata _calldata,
        uint256 _offset
    ) external;

    function returnSwap(
        address _token,
        uint256 _amount,
        address _router,
        bytes calldata _swapCalldata,
        address _burnToken,
        address _synthesis,
        bytes calldata _burnCalldata
    ) external;

    function metaMintSwap(
        MetaRouteStructs.MetaMintTransaction calldata _metaMintTransaction
    ) external;
}