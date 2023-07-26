// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorV3Interface.sol";

contract ChainlinkXAGUSDPriceConsumer {

    AggregatorV3Interface internal priceFeed;


    constructor() {
        //Mainnet address: 0x379589227b15F1a12195D3f2d90bBc9F31f95235
        //Rinkeby address: 0x9c1946428f4f159dB4889aA6B218833f467e1BfD
        //Kovan address: 0x4594051c018Ac096222b5077C3351d523F93a963
        //BNB address: 0x817326922c909b16944817c207562B25C4dF16aD
        
        priceFeed = AggregatorV3Interface(0x379589227b15F1a12195D3f2d90bBc9F31f95235);
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