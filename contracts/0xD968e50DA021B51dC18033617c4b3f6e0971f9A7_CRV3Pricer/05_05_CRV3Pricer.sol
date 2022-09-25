// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import { IPricer } from "../interfaces/IPricer.sol";
import { ICurvePool } from "../interfaces/ICurve.sol";
import { IOracle } from "../interfaces/IOracle.sol";

contract CRV3Pricer is IPricer {
    address public constant asset = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    ICurvePool public constant CURVE_POOL = ICurvePool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

    IOracle public oracle;

    constructor(address _oracle) {
        oracle = IOracle(_oracle);
    }

    function getPrice() external view override returns (uint256) {
        return _getPrice(oracle.getPrice(DAI), oracle.getPrice(USDC), oracle.getPrice(USDT));
    }

    function _getPrice(
        uint256 _daiPrice,
        uint256 _usdcPrice,
        uint256 _usdtPrice
    ) private view returns (uint256) {
        uint256 minPrice = _daiPrice < _usdcPrice && _daiPrice < _usdtPrice
            ? _daiPrice
            : _usdcPrice < _daiPrice && _usdcPrice < _usdtPrice
            ? _usdcPrice
            : _usdtPrice;
        return (CURVE_POOL.get_virtual_price() * minPrice) / 1e18;
    }

    function setExpiryPriceInOracle(uint256 _expiryTimestamp) external {
        (uint256 daiPriceExpiry, ) = oracle.getExpiryPrice(DAI, _expiryTimestamp);
        require(daiPriceExpiry > 0, "DAI price not set yet");

        (uint256 usdcPriceExpiry, ) = oracle.getExpiryPrice(USDC, _expiryTimestamp);
        require(usdcPriceExpiry > 0, "USDC price not set yet");

        (uint256 usdtPriceExpiry, ) = oracle.getExpiryPrice(USDT, _expiryTimestamp);
        require(usdtPriceExpiry > 0, "USDT price not set yet");

        uint256 price = _getPrice(usdcPriceExpiry, daiPriceExpiry, usdtPriceExpiry);

        oracle.setExpiryPrice(asset, _expiryTimestamp, price);
    }
}