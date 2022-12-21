// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20ElasticSupply.sol";


/**
* @title USDG
* @author Geminon Protocol
* @notice US Dollar Stablecoin
*/
contract USDG is ERC20ElasticSupply {

    bool public isInitialized;
    
    
    constructor() ERC20ElasticSupply("Geminon US Dollar", "USDG", 50, 1e24) {
        isInitialized = false;
    }


    /// @dev Initializes the USDG token adding the address of the stablecoin 
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

    /// @dev Compatibility with ERC20Indexed tokens
    function getOrUpdatePegValue() public pure returns(uint256) {
        return getPegValue();
    }

    /// @dev Get the current value of the peg in USD with 18 decimals
    function getPegValue() public pure returns(uint256) {
        return 1e18;
    }
}