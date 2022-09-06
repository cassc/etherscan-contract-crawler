// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;
import "@chainlink/contracts/src/v0.5/interfaces/AggregatorV3Interface.sol";

contract ChainlinkService {  
  
    function getLatestPrice(address feedAddress) 
        public 
        view 
        returns (int, uint, uint8) 
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(feedAddress);
        ( ,int price, ,uint timeStamp, ) = priceFeed.latestRoundData();
        uint8 decimal = priceFeed.decimals();
        return (price, timeStamp, decimal);
    }
}