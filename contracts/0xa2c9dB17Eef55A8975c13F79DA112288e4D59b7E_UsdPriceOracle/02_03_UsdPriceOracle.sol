//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "lib/chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "src/interfaces/IPriceOracle.sol";

contract UsdPriceOracle is IPriceOracle {
    AggregatorV3Interface internal priceFeed;

    constructor(address _oracle) {
        // eth - 0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419
        // eth-goerli -
        priceFeed = AggregatorV3Interface(_oracle);
    }

    function getPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        require(uint256(price) > 0, "oracle returned invalid price");
        return uint256(price);
    }

    function getWeiValueOfDollar() public view returns (uint256) {
        uint256 price = getPrice();
        return (1 ether * 100000000) / price;
    }
}