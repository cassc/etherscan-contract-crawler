// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IConverter.sol";

/// @author YLDR <[email protected]>
interface IAssetConverter {
    error SlippageTooBig(address source, address destination, uint256 amountIn, uint256 amountOut);

    struct RouteData {
        IConverter converter;
        uint256 maxAllowedSlippage;
    }

    struct RouteDataUpdate {
        address source;
        address destination;
        RouteData data;
    }

    struct ComplexRouteUpdate {
        address source;
        address destination;
        address[] complexRoutes;
    }

    function pricesOracle() external view returns(address);

    function routes(address, address) external view returns(RouteData memory);
    function complexRoutes(address source, address destination) external view returns (address[] memory);

    function updateRoutes(RouteDataUpdate[] calldata updates) external;
    function updateComplexRoutes(ComplexRouteUpdate[] calldata updates) external;

    function swap(address source, address destination, uint256 amountIn) external returns (uint256);

    function previewSwap(address source, address destination, uint256 value) external returns (uint256);
}