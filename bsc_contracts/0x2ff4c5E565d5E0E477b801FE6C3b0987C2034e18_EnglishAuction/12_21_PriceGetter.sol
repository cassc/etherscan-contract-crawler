// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceGetter is Initializable, OwnableUpgradeable {
    event AggregatorChanged(address aggregatorAddress);

    //============== INITIALIZE ==============

    function __PriceGetter_init(address aggregatorAddress)
        internal
        onlyInitializing
    {
        __PriceGetter_init_unchained(aggregatorAddress);
    }

    function __PriceGetter_init_unchained(address aggregatorAddress)
        internal
        onlyInitializing
    {
        bnbBusdPriceFeed = AggregatorV3Interface(aggregatorAddress);
    }

    //============== VARIABLES ==============

    AggregatorV3Interface internal bnbBusdPriceFeed;

    function changeAggregatorInterface(address aggregatorAddress)
        external
        onlyOwner
    {
        bnbBusdPriceFeed = AggregatorV3Interface(aggregatorAddress);
        emit AggregatorChanged(aggregatorAddress);
    }

    //============== GET FUNCTIONS ==============

    function getBnbBusd() public view returns (uint256) {
        (, int price, , , ) = bnbBusdPriceFeed.latestRoundData();
        return uint256(price);
    }

    //============== CONVERT FUNCTIONS ==============

    function convertBNBToBUSD(uint256 amountInBNB) public view returns (uint256) {
        return (amountInBNB * 1e18) / getBnbBusd();
    }

    function convertBUSDToBNB(uint256 amountInBUSD)
        public
        view
        returns (uint256)
    {
        return (getBnbBusd() * amountInBUSD) / 1e18;
    }

    uint256[50] private __gap;
}