// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IPostagePriceModule.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainlinkPostagePriceModule is IPostagePriceModule, Ownable {
    AggregatorV3Interface public chainlinkOracle;
    uint256 public postageCostUsd; // USD * 10^18

    constructor(AggregatorV3Interface _chainlinkOracle, uint256 _postageCostUsd) {
        chainlinkOracle = AggregatorV3Interface(_chainlinkOracle);
        postageCostUsd = _postageCostUsd;
    }

    function getPostageWei() public view returns (uint256) {
        return postageCostUsd / (getLatestEthPrice() / 10 ** chainlinkOracle.decimals());
    }

    function getLatestEthPrice() public view returns (uint256) {
        (, int256 price,,,) = chainlinkOracle.latestRoundData();
        return uint256(price);
    }

    // Admin functionality
    function updatePrice(uint256 newPostageCostUsd) external onlyOwner {
        postageCostUsd = newPostageCostUsd;
    }
}