// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IWhitelist 
 * 
 * Interface for a { Whitelist } contract, from the perspective of another contract which holds a reference to 
 * the Whitelist (only a small subset of its methods/properties will be needed). 
 * 
 * See also { Whitelist }
 * 
 * @author John R. Kosinski 
 * Owned and Managed by Stream Finance
 */
interface IWhitelist  {
    
    /**
     * Indicates whether or not the given address is in the contained. 
     * 
     * @param addr The address to query. 
     * @return True if the given address is on the whitelist, otherwise false.
     */
    function isWhitelisted(address addr) external returns (bool); 
}