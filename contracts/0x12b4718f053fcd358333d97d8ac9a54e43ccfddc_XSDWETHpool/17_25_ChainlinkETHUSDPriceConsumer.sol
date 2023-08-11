// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorV3Interface.sol";

contract ChainlinkETHUSDPriceConsumer {

    AggregatorV3Interface internal priceFeed;

    constructor() {
        
        //Mainnet address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        //Rinkeby address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //Kovan address: 0x9326BFA02ADD2366b30bacB125260Af641031331
        //Goerli address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        //BNB address: 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            , 
            int price,
            ,
            ,
            
        ) = priceFeed.latestRoundData();
        return price;
    }

    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }
}