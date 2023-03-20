// contracts/Project.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IOracle.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract ChainLinkOracle is IOracle {
    address public priceFeedAddress;

    constructor(address _priceFeedAddress) {
        priceFeedAddress = _priceFeedAddress;
    }

    /**
     * @dev Returns the price of Bitcoin from chainlink.
     */
    function getPrice() external view override returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (
            ,
            int256 price,
            ,
            uint256 timeStamp,
            
        ) = priceFeed.latestRoundData();
        require(timeStamp > 0, "ChainLinkOracle: Round not complete");
        return uint256(price);
    }

}