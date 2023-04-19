// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title ISecurityManager 
 * 
 * Interface for a contract's associated { SecurityManager } contract, from the point of view of the security-managed 
 * contract (only a small subset of the SecurityManager's methods are needed). 
 * 
 * See also { SecurityManager }
 * 
 * @author John R. Kosinski 
 * Owned and Managed by Stream Finance
 */
interface ISecurityManager  {
    
    /**
     * Returns `true` if `account` has been granted `role`.
     * 
     * @param role The role to query. 
     * @param account Does this account have the specified role?
     */
    function hasRole(bytes32 role, address account) external returns (bool); 
}