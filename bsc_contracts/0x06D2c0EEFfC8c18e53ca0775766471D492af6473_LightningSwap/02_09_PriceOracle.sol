// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ChainlinkAggregatorV3Interface.sol";

contract PriceOracle is Ownable {
    using Address for address;

    ChainlinkAggregatorV3Interface public btcOracle;
    ChainlinkAggregatorV3Interface public nativeOracle;

    mapping(address => address) public chainlinkOracles;

    event TokenOracleSet(address indexed token, address oralce);

    constructor(address _btcOracle, address _nativeOrace) {
        require(_btcOracle.isContract(), "BTC oracle is not contract");
        require(_nativeOrace.isContract(), "Native oracle is not contract");
        btcOracle = ChainlinkAggregatorV3Interface(_btcOracle);
        nativeOracle = ChainlinkAggregatorV3Interface(_nativeOrace);
    }

    function setTokenOracle(address token, address oracle) external onlyOwner {
        chainlinkOracles[token] = oracle;
        emit TokenOracleSet(token, oracle);
    }

    function getBTCPrice() external view returns (uint256 price) {
        (, int256 answer,,,) = btcOracle.latestRoundData();
        return uint256(answer);
    }

    function getNativePrice() external view returns (uint256 price) {
        (, int256 answer,,,) = nativeOracle.latestRoundData();
        return uint256(answer);
    }

    function getTokenPrice(address token) external view returns (uint256 price) {
        address oracle = chainlinkOracles[token];
        if (oracle == address(0)) return 0;

        (, int256 answer,,,) = ChainlinkAggregatorV3Interface(oracle).latestRoundData();
        return uint256(answer);
    }
}