// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20ElasticSupply.sol";


/**
* @title GEX
* @author Geminon Protocol
* @notice Target supply: 100 million tokens across all chains. This is not a hard
* limit, supply is elastic to achieve linear price variation with respect to the
* amount of collateral in the pools. Supply can only be minted by supplying 
* collateral to Genesis Liquidity Pools. 
* On contract creation there is no initial supply.
*/
contract GEX is ERC20ElasticSupply {

    bool public isInitialized;
    int256 public supplyLimitMint;

    
    /// @notice Mint is limited to 5 million tokens per day through the 
    /// variable supplyLimitMint and the _requireMaxMint() override. 
    /// @dev baseMintRatio and thresholdLimitMint parameters of 
    /// ERC20ElasticSupply constructor are ignored because of this 
    /// override.
    constructor() ERC20ElasticSupply("Geminon", "GEX", 50, 5*1e24) {
        supplyLimitMint = 5000000 * 1e18; 
        isInitialized = false;
    }


    /// @dev Initializes the GEX token adding the addresses of the contracts
    /// of the pools that can mint it. This function can only be called once
    /// after deployment. Owner can't be a minter.
    /// @param poolsMinters array of minter addresses. 
    function initialize(address[] memory poolsMinters) external onlyOwner {
        require(!isInitialized); // dev: Already initialized

        for (uint16 i=0; i < poolsMinters.length; i++) {
            require(poolsMinters[i] != address(0));
            require(poolsMinters[i] != owner());
            minters[poolsMinters[i]] = true;
        }
        
        minters[owner()] = false;
        isInitialized = true;
    }

    /// @dev Checks that the amount minted is not higher than the max daily limit.
    function _requireMaxMint(uint256 amount) internal override {
        require(_meanDailyAmount(_toInt256(amount)) <= supplyLimitMint); // dev: Max mint rate
    }
}