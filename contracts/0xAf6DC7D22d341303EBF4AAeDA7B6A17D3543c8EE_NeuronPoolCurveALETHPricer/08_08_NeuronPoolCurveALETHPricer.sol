// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { IPricer } from "../interfaces/IPricer.sol";
import { ICurvePool } from "../interfaces/ICurve.sol";
import { INeuronPool } from "../../common/interfaces/INeuronPool.sol";
import { IOracle } from "../interfaces/IOracle.sol";

contract NeuronPoolCurveALETHPricer is IPricer {
    ICurvePool public constant CURVE_POOL = ICurvePool(0xC4C319E2D4d66CcA4464C0c2B32c9Bd23ebe784e);

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public constant ALETH = 0x0100546F2cD4C9D97f798fFC9755E47865FF7Ee6;

    address public asset;

    INeuronPool public neuronPool;

    uint8 public pricePerShareDecimals;

    IOracle public oracle;

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
        return _getPrice(oracle.getPrice(WETH));
    }

    function _getPrice(uint256 _ethPrice) private view returns (uint256) {
        return
            (neuronPool.pricePerShare() * CURVE_POOL.get_virtual_price() * _ethPrice) /
            (10**(pricePerShareDecimals + 18));
    }

    function setExpiryPriceInOracle(uint256 _expiryTimestamp) external {
        (uint256 ethPriceExpiry, ) = oracle.getExpiryPrice(WETH, _expiryTimestamp);

        require(ethPriceExpiry > 0, "WETH price not set yet");

        uint256 price = _getPrice(ethPriceExpiry);

        oracle.setExpiryPrice(asset, _expiryTimestamp, price);
    }
}