//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

interface IReceivingForwarder {
    function forward(
        address _dstTokenIn,
        address _router,
        bytes memory _routerCalldata,
        address _dstTokenOut,
        address _fallbackAddress
    ) external payable;

    function forwardUniversal(
        address _dstTokenIn,
        address _router,
        bytes memory _routerCalldata,
        uint16[] memory _routerAmountPositions,
        address _dstTokenOut,
        address _fallbackAddress
    ) external payable;
}