// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

import "ERC20Indexed.sol";


/**
* @title EURI
* @author Geminon Protocol
* @notice Stablecoin indexed to the Harmonized Index of Consumer Prices
* of the Euro Area (inflation indexed Euro).
*/
contract EURI is ERC20Indexed {

    address public priceFeed;
    uint8 public priceFeedDecimals;
    bool public isInitialized;

    
    constructor(address indexBeacon, address priceFeed_) 
        ERC20Indexed(
            "HICP Indexed Euro", 
            "EURI", 
            indexBeacon, 
            50,
            1e24
        )
    {
        priceFeed = priceFeed_;
        priceFeedDecimals = AggregatorV3Interface(priceFeed).decimals();
        isInitialized = false;
        require(priceFeedDecimals <= 18); // dev: Too many decimals
    }


    /// @dev Initializes the EURI token adding the address of the stablecoin 
    /// minter contract. This function can only be called once
    /// after deployment. Owner can't be a minter.
    /// @param scMinter Stablecoin minter address. 
    function initialize(address scMinter) external onlyOwner {
        require(!isInitialized); // dev: Initialized
        require(scMinter != address(0)); // dev: Address 0
        require(scMinter != owner()); // dev: Minter is owner

        minters[scMinter] = true;
        isInitialized = true;
    }
    
    
    /// @dev Updates the address of the Chainlink oracle that provides the peg values. 7 days timelock.
    function updatePriceFeed(address priceFeed_) external onlyOwner {
        require(changeRequests[priceFeed].changeRequested); // dev: Not requested
        require(block.timestamp - changeRequests[priceFeed].timestampRequest > 7 days); // dev: Time elapsed
        require(changeRequests[priceFeed].newAddressRequested == priceFeed_); // dev: Different address requested

        changeRequests[priceFeed].changeRequested = false;
        priceFeed = priceFeed_;
        priceFeedDecimals = AggregatorV3Interface(priceFeed).decimals();
        
        require(priceFeedDecimals <= 18, 'Oracle has too many decimals');
    }

    
    /// @dev Get the current value of the peg in USD with 18 decimals
    function getPegValue() public view override returns(uint256) {
        return (_pegValue() * usdPrice()) / 1e6;
    }

    /// @notice Gets the current price of the base currency in USD
    function usdPrice() public view returns(uint256) {
        (, int256 answer, , , ) = AggregatorV3Interface(priceFeed).latestRoundData();
        return uint256(answer) * 10**(18-priceFeedDecimals);
    }
}