// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAggregationRouterV5.sol";

interface ISwapperFactory {
    function swap(IAggregationRouterV5.SwapTransaction calldata) external;

    function enableTAssetForSwap(address _tAsset, address _stakingContract) external;

    function executeSwapForCvgToke(address _user, IAggregationRouterV5.SwapTransaction calldata) external returns (uint256);

    function executeSimpleSwap(address _user, IAggregationRouterV5.SwapTransaction calldata) external returns (uint256);
}