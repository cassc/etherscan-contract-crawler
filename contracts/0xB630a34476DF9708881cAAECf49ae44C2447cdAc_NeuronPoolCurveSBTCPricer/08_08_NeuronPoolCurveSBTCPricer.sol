// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { IPricer } from "../interfaces/IPricer.sol";
import { ICurvePool } from "../interfaces/ICurve.sol";
import { INeuronPool } from "../../common/interfaces/INeuronPool.sol";
import { IOracle } from "../interfaces/IOracle.sol";

contract NeuronPoolCurveSBTCPricer is IPricer {
    ICurvePool public constant CURVE_POOL = ICurvePool(0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714);
    address public constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    address public immutable asset;
    INeuronPool public immutable neuronPool;
    uint8 public immutable pricePerShareDecimals;
    IOracle public immutable oracle;

    constructor(
        address _neuronPool,
        uint8 _pricePerShareDecimals,
        address _oracle
    ) {
        asset = _neuronPool;
        neuronPool = INeuronPool(_neuronPool);
        pricePerShareDecimals = _pricePerShareDecimals;
        oracle = IOracle(_oracle);
    }

    function getPrice() external view override returns (uint256) {
        return _getPrice(oracle.getPrice(WBTC));
    }

    function _getPrice(uint256 _wbtcPrice) private view returns (uint256) {
        return
            (neuronPool.pricePerShare() * CURVE_POOL.get_virtual_price() * ((_wbtcPrice * 9940) / 10000)) /
            (10**(pricePerShareDecimals + 18));
    }

    function setExpiryPriceInOracle(uint256 _expiryTimestamp) external {
        (uint256 wbtcPriceExpiry, ) = oracle.getExpiryPrice(WBTC, _expiryTimestamp);
        require(wbtcPriceExpiry > 0, "WBTC price not set yet");

        uint256 price = _getPrice(wbtcPriceExpiry);

        oracle.setExpiryPrice(asset, _expiryTimestamp, price);
    }
}