// SPDX-License-Identifier:  AGPL-3.0-or-later
pragma solidity 0.8.18;

import {Marketplace} from "Marketplace.sol";


/**
 * @title BlockBarMarketplace
 * @author aarora
 */
contract BlockBarMarketplace is Marketplace {

    // Forward BlockBarBTL ERC721 and Chainlink price feed address to Marketplace
    constructor(
        address blockbarBtlContractAddress,
        address priceFeedAddress
    ) Marketplace(blockbarBtlContractAddress, priceFeedAddress) {}

    /**
    * @notice Get name of the contract
    *
    * @return nameOfContract string representation of BlockBarMarketplace
    */
    function name() external pure returns (string memory nameOfContract) {
        return "BlockBarMarketplace";
    }
}