//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
/**                                            
       
             ___           ___           ___                         ___           ___         ___           ___                   
     /\  \         /\__\         /\  \                       /\  \         /\  \       /\  \         /\  \                  
    |::\  \       /:/ _/_        \:\  \         ___         /::\  \       /::\  \     /::\  \       /::\  \         ___     
    |:|:\  \     /:/ /\__\        \:\  \       /\__\       /:/\:\  \     /:/\:\__\   /:/\:\  \     /:/\:\__\       /\__\    
  __|:|\:\  \   /:/ /:/ _/_   _____\:\  \     /:/  /      /:/ /::\  \   /:/ /:/  /  /:/  \:\  \   /:/ /:/  /      /:/  /    
 /::::|_\:\__\ /:/_/:/ /\__\ /::::::::\__\   /:/__/      /:/_/:/\:\__\ /:/_/:/  /  /:/__/ \:\__\ /:/_/:/__/___   /:/__/     
 \:\~~\  \/__/ \:\/:/ /:/  / \:\~~\~~\/__/  /::\  \      \:\/:/  \/__/ \:\/:/  /   \:\  \ /:/  / \:\/:::::/  /  /::\  \     
  \:\  \        \::/_/:/  /   \:\  \       /:/\:\  \      \::/__/       \::/__/     \:\  /:/  /   \::/~~/~~~~  /:/\:\  \    
   \:\  \        \:\/:/  /     \:\  \      \/__\:\  \      \:\  \        \:\  \      \:\/:/  /     \:\~~\      \/__\:\  \   
    \:\__\        \::/  /       \:\__\          \:\__\      \:\__\        \:\__\      \::/  /       \:\__\          \:\__\  
     \/__/         \/__/         \/__/           \/__/       \/__/         \/__/       \/__/         \/__/           \/__/  
       
                                           
**/
interface IMentaportERC721 {
  /**
  * @dev Emitted when `mentaport` updates its account
  */
  event MentaportAccount(address indexed sender, address indexed account);
  /**
  * @dev Emitted when mint_role `sender` reveals contract URI.
  */
  event Reveal(address indexed sender);
  /**
  * @dev Emitted when contract owner changes max mint amount
  */
  event SetMaxMintAmount(uint256 newmaxMintAmount);
  /**
  * @dev Emitted when contract owner changes mint cost
  */
  event SetCost(uint256 cost);
  /**
  * @dev Emitted when contract withdraws
  */
  event Withdraw();
  /**
  * @dev Emitted when `admin`  mints `mintAmount` of tokens for `receiver` account
  */
  event MintForAddress(address indexed admin, uint256 mintAmount, address indexed receiver);
  /**
  * @dev Emitted when `admin` updates a rule
  */
  event RuleUpdate(address indexed admin, string message);
  /**
  * @dev Emitted when `admin` updates a `state`
  */
  event StateUpdate(address indexed admin, uint256 state, string message);

 /**
  * @dev Emitted when mint NFT with location
  */
  event MintLocation(address sender, uint256 tokenId);
}