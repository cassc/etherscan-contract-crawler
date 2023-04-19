// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IVaultToken
 * 
 * @dev An ERC20-compliant token which is tied to a specific Vault, and can be minted from that vault 
 * in exchange for a specified base token, or can be exchanged at that Vault for the specified base 
 * token. 
 * 
 * @author John R. Kosinski 
 * Owned and Managed by Stream Finance
 */
interface IVaultToken  {
    
    /**
     * Returns the address of the Vault instance that is associated with this Vault Token. Can be a zero address.
     * 
     * @return The address of the associated Vault, if any
     */
    function vaultAddress() external view returns (address); 
    
    /**
     * Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Creates tokens out of thin air. Authorized address may mint to any user. 
     * 
     * @param to Address to which to give the newly minted value.
     * @param amount The number of units of the token to mint. 
     */
    function mint(address to, uint256 amount) external;
    
    /**
     * Destroys `amount` tokens from the sender's account, reducing the total supply.
     *
     * @param amount The amount to burn. 
     */
    function burn(uint256 amount) external;
    
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address addr) external view returns (uint256); 
    
    /**
     * @dev See {IERC20-transfer}.
     */
    function transfer(address to, uint256 amount) external returns (bool); 
    
    /**
     * Triggers stopped state, rendering many functions uncallable. 
     */
    function pause() external;
    
    /**
     * Returns to the normal state after having been paused.
     */
    function unpause() external;
    
    /**
     * This is just between the Vault and the Vault Token. It's private. Like just between them two. 
     * 
     * @param from The actual owner (not spender) of the tokens being transferred 
     * @param to The recipient of the transfer 
     * @param amount The amount to transfer
     */
    function transferFromInternal(address from, address to, uint256 amount) external returns (bool); 
}