// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ChainlinkPriceFeedAggregator.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IConverter.sol";
import "./interfaces/IAssetConverter.sol";

/// @author YLDR <[email protected]>
contract AssetConverter is IAssetConverter, Ownable {
    using SafeERC20 for IERC20;

    ChainlinkPriceFeedAggregator private immutable _pricesOracle;
    mapping(address => mapping(address => RouteData)) private _routes;
    mapping(address => mapping(address => address[])) private _complexRoutes;
    uint256 private defaultMaxAllowedSlippage = 20; // in 10^-3s

    constructor(ChainlinkPriceFeedAggregator pricesOracle_) {
        _pricesOracle = pricesOracle_;
    }

    function pricesOracle() public view returns (address) {
        return address(_pricesOracle);
    }

    function routes(address source, address destination) public view returns (RouteData memory) {
        return _routes[source][destination];
    }

    function complexRoutes(address source, address destination) public view returns (address[] memory) {
        return _complexRoutes[source][destination];
    }

    function updateRoutes(RouteDataUpdate[] calldata updates) public onlyOwner {
        for (uint256 i = 0; i < updates.length; i++) {
            _routes[updates[i].source][updates[i].destination] = updates[i].data;
        }
    }

    function updateComplexRoutes(ComplexRouteUpdate[] calldata updates) public onlyOwner {
        for (uint256 i = 0; i < updates.length; i++) {
            _complexRoutes[updates[i].source][updates[i].destination] = updates[i].complexRoutes;
        }
    }

    function _checkSlippage(address source, address destination, uint256 amountIn, uint256 amountOut)
        internal
        view
        returns (bool)
    {
        // If amountIn is low enough, than fee substraction may substract 1
        // And in case in low amountIn this can make big difference
        amountIn -= 1;
        uint256 maxSlippage = _routes[source][destination].maxAllowedSlippage;
        if (maxSlippage == 0) {
            maxSlippage = defaultMaxAllowedSlippage;
        }

        uint256 sourceUSDPrice;
        uint256 destinationUSDPrice;
        try _pricesOracle.getRate(source) returns (uint256 price) {
            sourceUSDPrice = price;
        } catch {
            return true;
        }
        try _pricesOracle.getRate(destination) returns (uint256 price) {
            destinationUSDPrice = price;
        } catch {
            return true;
        }

        uint256 sourceUSDValue = (amountIn * sourceUSDPrice) / (10 ** IERC20Metadata(source).decimals());
        uint256 expected = (sourceUSDValue * (10 ** IERC20Metadata(destination).decimals())) / destinationUSDPrice;
        return (amountOut >= (expected * (1000 - maxSlippage)) / 1000);
    }

    function _getRoute(address source, address destination)
        internal
        view
        returns (address[] memory tokens, IConverter[] memory converters)
    {
        uint256 complexRoutesLength = _complexRoutes[source][destination].length;
        tokens = new address[](2 + complexRoutesLength);
        converters = new IConverter[](tokens.length - 1);
        tokens[0] = source;
        for (uint256 i = 0; i < complexRoutesLength; i++) {
            tokens[i + 1] = _complexRoutes[source][destination][i];
        }
        tokens[tokens.length - 1] = destination;
        for (uint256 i = 0; i < tokens.length - 1; i++) {
            converters[i] = _routes[tokens[i]][tokens[i + 1]].converter;
            require(address(converters[i]) != address(0), "AssetConverter: No converter specified for the route");
        }
    }

    function swap(address source, address destination, uint256 amountIn) external returns (uint256) {
        (address[] memory tokens, IConverter[] memory converters) = _getRoute(source, destination);

        IERC20(source).safeTransferFrom(msg.sender, address(converters[0]), amountIn);

        for (uint256 i = 0; i < tokens.length - 1; i++) {
            if (amountIn == 0) {
                return 0;
            }

            address to = i < tokens.length - 2 ? address(converters[i + 1]) : msg.sender;
            IConverter converter = converters[i];
            uint256 amountOut = converter.swap(tokens[i], tokens[i + 1], amountIn, to);
            if (!_checkSlippage(tokens[i], tokens[i + 1], amountIn, amountOut)) {
                revert SlippageTooBig(tokens[i], tokens[i + 1], amountIn, amountOut);
            }

            amountIn = amountOut;
        }
        return amountIn;
    }

    function previewSwap(address source, address destination, uint256 value) external returns (uint256) {
        (address[] memory tokens, IConverter[] memory converters) = _getRoute(source, destination);

        for (uint256 i = 0; i < tokens.length - 1; i++) {
            IConverter converter = converters[i];
            value = converter.previewSwap(tokens[i], tokens[i + 1], value);
        }
        return value;
    }
}