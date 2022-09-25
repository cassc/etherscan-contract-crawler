// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { IPricer } from "../interfaces/IPricer.sol";
import { ICurvePool } from "../interfaces/ICurve.sol";
import { INeuronPool } from "../../common/interfaces/INeuronPool.sol";
import { IOracle } from "../interfaces/IOracle.sol";

contract NeuronPoolCurveDoublePoolExtendsPricer is IPricer, Initializable {
    address public asset;

    INeuronPool public neuronPool;

    ICurvePool public curvePool;

    address public firstToken;

    address public secondToken;

    uint8 public pricePerShareDecimals;

    IOracle public oracle;

    function initialize(
        address _neuronPool,
        address _curvePool,
        address _firstToken,
        address _secondToken,
        uint8 _pricePerShareDecimals,
        address _oracle
    ) external initializer {
        asset = _neuronPool;
        neuronPool = INeuronPool(_neuronPool);
        curvePool = ICurvePool(_curvePool);
        firstToken = _firstToken;
        secondToken = _secondToken;
        pricePerShareDecimals = _pricePerShareDecimals;
        oracle = IOracle(_oracle);
    }

    function getPrice() external view override returns (uint256) {
        uint256 firstTokenPrice = oracle.getPrice(firstToken);
        uint256 secondTokenPrice = oracle.getPrice(secondToken);

        return _getPrice(firstTokenPrice, secondTokenPrice);
    }

    function _getPrice(uint256 _firstTokenPrice, uint256 _secondTokenPrice) private view returns (uint256) {
        return
            (neuronPool.pricePerShare() *
                curvePool.get_virtual_price() *
                (_firstTokenPrice < _secondTokenPrice ? _firstTokenPrice : _secondTokenPrice)) /
            (10**(pricePerShareDecimals + 18));
    }

    function setExpiryPriceInOracle(uint256 _expiryTimestamp) external {
        (uint256 firstTokenPriceExpiry, ) = oracle.getExpiryPrice(firstToken, _expiryTimestamp);

        require(firstTokenPriceExpiry > 0, "First token price not set yet");

        (uint256 secondTokenPriceExpiry, ) = oracle.getExpiryPrice(secondToken, _expiryTimestamp);

        require(secondTokenPriceExpiry > 0, "Second token price not set yet");

        uint256 price = _getPrice(firstTokenPriceExpiry, secondTokenPriceExpiry);

        oracle.setExpiryPrice(asset, _expiryTimestamp, price);
    }
}