/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: chainlink.sol


pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
contract ChainLinkOracle {
    AggregatorV3Interface internal priceFeed;

    /**
     * Contract constructor.
     * @param aggregatorAddress The address of the Chainlink aggregator contract to fetch the price data.
     */
    constructor(address aggregatorAddress) {
        priceFeed = AggregatorV3Interface(aggregatorAddress);
    }

    /**
     * Returns the latest price from the configured Chainlink aggregator.
     * @return The latest price.
     */
    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     * Returns the latest round data from the configured Chainlink aggregator.
     * @return roundId The round ID.
     * @return price The price for the round.
     * @return startedAt The start timestamp for the round.
     * @return updatedAt The update timestamp for the round.
     * @return answeredInRound The round ID where the answer was computed.
     */
    function getLatestRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return priceFeed.latestRoundData();
    }
}