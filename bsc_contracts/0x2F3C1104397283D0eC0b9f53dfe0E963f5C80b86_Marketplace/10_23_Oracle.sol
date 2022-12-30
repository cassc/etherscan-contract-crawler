// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Oracle {
    // @dev Returns the latest price
    function getLatestPrice(address _oracle, uint256 _decimal)
        public
        view
        returns (uint256)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_oracle);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price) * 10**_decimal;
    }
}