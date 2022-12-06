// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20Indexed.sol";


/**
* @title USDI
* @author Geminon Protocol
*/
contract USDI is ERC20Indexed {

    bool public isInitialized = false;

    
    constructor(address indexBeacon) 
        ERC20Indexed(
            "CPI Indexed USD", 
            "USDI", 
            indexBeacon, 
            50,
            1e24
        )
    {}


    /// @dev Initializes the USDI token adding the address of the stablecoin 
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
}