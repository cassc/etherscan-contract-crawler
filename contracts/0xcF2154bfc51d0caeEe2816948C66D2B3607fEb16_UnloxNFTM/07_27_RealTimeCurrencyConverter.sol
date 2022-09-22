// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CurrencyConverterInterface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract RealTimeCurrencyConverter is CurrencyConverterInterface{

    using SafeMath for uint256;
    AggregatorV3Interface internal priceFeed;

    constructor() {

        /**
        * Network: Rinkeby
        * Aggregator: ETH/USD
        * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        */

        /**
        * Network: Ethereum Mainnet
        * Aggregator: ETH/USD
        * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        */
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    function centToWEI(uint256 centValue) external view returns (uint256)
    {
        (
            uint80 roundID, 
            int ethPrice,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        uint256 pow = 10**24;
        return centValue.mul(pow.div(uint256(ethPrice)));
    }
     
}