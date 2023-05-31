/**
 *Submitted for verification at Etherscan.io on 2023-05-29
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IOracle {
    function getReferenceData(string memory symbol) external view returns (uint256 rate);
}

contract BandProtocolOracle {
    IOracle public priceFeed;

    constructor(address aggregatorAddress) {
        priceFeed = IOracle(aggregatorAddress);
    }

    /**
     * Returns the latest price from the configured Band Protocol aggregator .
     * @return The latest price.
     */
    function getLatestPrice() public view returns (uint256) {
        (uint256 rate) = getPriceData();
        return rate;
    }

    /**
     * 
     * @return rate The reference data rate.
     */
    function getPriceData() internal view returns (uint256 rate) {
        bytes memory symbol = "WETH_USD"; 
        try priceFeed.getReferenceData(string(symbol)) returns (uint256 result) {
            return result;
        } catch {
            revert("Error fetching price data from Band Protocol oracle");
        }
    }
}