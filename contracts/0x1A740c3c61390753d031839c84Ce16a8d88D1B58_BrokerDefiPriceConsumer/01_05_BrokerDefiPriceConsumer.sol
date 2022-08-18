// SPDX-License-Identifier: MIT
// author : saad sarwar
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./Percentages.sol";


contract BrokerDefiPriceConsumer is Ownable {

    using Percentages for uint;

    AggregatorV3Interface internal priceFeed;

    uint partnerPrice = 1750 * 10 ** 8; // 1750 in usdt because chainlink oracle uses 8 decimals

    uint proPrice = 1500 * 10 ** 8;

    constructor(address aggregator) {
        priceFeed = AggregatorV3Interface(aggregator);
    }

    function getLatestEthPrice() public view returns (uint) {
        (
        /*uint80 roundID*/,
        int answer,
        /*uint startedAt*/,
        /*uint timeStamp*/,
        /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return uint(answer);
    }

    function usdToEth(uint _amountInUsd) public view returns (uint) {
        if(_amountInUsd == 0) {
            return 0;
        }

        uint _basisPoints = getLatestEthPrice().calcBasisPoints(_amountInUsd);
        uint _amountInEth = _basisPoints * (10 ** 14);

        return _amountInEth;
    }

    function getPartnerPriceInEth() public view returns(uint) {
        return usdToEth(partnerPrice);
    }

    function getProPriceInEth() public view returns(uint) {
        return usdToEth(proPrice);
    }

    function setPartnerPrice(uint price) public onlyOwner() {
        partnerPrice = price;
    }

    function setProPrice(uint price) public onlyOwner() {
        proPrice = price;
    }

}