// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./inc/Context.sol"; 
import "./ISecurityManager.sol"; 

/**
 * @title ManagedSecurity 
 * 
 * This is an abstract base class for contracts whose security is managed by { SecurityManager }. It exposes 
 * the modifier which calls back to the associated { SecurityManager } contract. 
 * 
 * See also { SecurityManager }
 * 
 * @author John R. Kosinski 
 * Owned and Managed by Stream Finance
 */
abstract contract ManagedSecurity is Context { 
    //TODO: (MED) the use of Context here instead of ContextUpgradeable is questionable; consider making a separate ManagedSecurityUpgradeable
    ISecurityManager public securityManager; 
    
    //security roles 
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant GENERAL_MANAGER_ROLE = keccak256("GENERAL_MANAGER_ROLE");
    bytes32 public constant LIFECYCLE_MANAGER_ROLE = keccak256("LIFECYCLE_MANAGER_ROLE");
    bytes32 public constant WHITELIST_MANAGER_ROLE = keccak256("WHITELIST_MANAGER_ROLE");
    bytes32 public constant DEPOSIT_MANAGER_ROLE = keccak256("DEPOSIT_MANAGER_ROLE");
    
    //thrown when the onlyRole modifier reverts 
    error UnauthorizedAccess(bytes32 roleId, address addr); 
    
    //thrown if zero-address argument passed for securityManager
    error ZeroAddressArgument(); 
    
    //Restricts function calls to callers that have a specified security role only 
    modifier onlyRole(bytes32 role) {
        if (!securityManager.hasRole(role, _msgSender())) {
            revert UnauthorizedAccess(role, _msgSender());
        }
        _;
    }
    
    /**
     * Allows an authorized caller to set the securityManager address. 
     * 
     * Reverts: 
     * - {UnauthorizedAccess}: if caller is not authorized 
     * - {ZeroAddressArgument}: if the address passed is 0x0
     * - 'Address: low-level delegate call failed' (if `_securityManager` is not legit)
     * 
     * @param _securityManager Address of an ISecurityManager. 
     */
    function setSecurityManager(ISecurityManager _securityManager) external onlyRole(ADMIN_ROLE) {
        _setSecurityManager(_securityManager); 
    }
    
    /**
     * This call helps to check that a given address is a legitimate SecurityManager contract, by 
     * attempting to call one of its read-only methods. If it fails, this function will revert. 
     * 
     * @param _securityManager The address to check & verify 
     */
    function _setSecurityManager(ISecurityManager _securityManager) internal {
        
        //address can't be zero
        if (address(_securityManager) == address(0)) 
            revert ZeroAddressArgument(); 
            
        //this line will fail if security manager is invalid address
        _securityManager.hasRole(ADMIN_ROLE, address(this)); 
        
        //set the security manager
        securityManager = _securityManager;
    }
    
    //future-proof, as this is inherited by upgradeable contracts
    uint256[50] private __gap;
}