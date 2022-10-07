// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PriceConsumerV3 is Ownable {
    address public addressOracle = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    /**
     * Network: Ethereum
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */
    constructor() {}

    // @dev Returns the latest price
    function getLatestPrice() public view returns (uint256) {
        /// @dev Get the latest price
        AggregatorV3Interface priceFeed = AggregatorV3Interface(addressOracle);

        (, int256 price, , , ) = priceFeed.latestRoundData();

        return uint256(price) * 10**10;
    }

    /// @dev set oracle address
    function setOracleAddress(address _addressOracle) external onlyOwner {
        addressOracle = _addressOracle;
    }
}