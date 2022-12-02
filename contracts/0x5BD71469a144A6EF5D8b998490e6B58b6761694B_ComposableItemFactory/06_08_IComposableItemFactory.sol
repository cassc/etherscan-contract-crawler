// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Composable Item Factory

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

interface IComposableItemFactory {
	/**
   	* @notice Emitted when a new collection is created from this factory.
   	* @param tokenAddress The address of the new NFT collection contract.
   	* @param creator The address of the creator which owns the new collection.
   	* @param version The implementation version used by the new collection.
   	* @param name The name of the collection contract created.
   	* @param symbol The symbol of the collection contract created.
   	* @param nonce The nonce used by the creator when creating the collection,
   	* used to define the address of the collection.
   	*/
  	event CollectionCreated(
    	address indexed tokenAddress,
    	address indexed creator,
    	uint256 indexed version,
    	string name,
    	string symbol,
    	uint256 nonce
  	);
  	
  	/**
   	* @notice Emitted when the implementation contract used by new collections is updated.
   	* @param implementation The new implementation contract address.
   	* @param version The version of the new implementation, auto-incremented.
   	*/
  	event ImplementationUpdated(address indexed implementation, uint256 indexed version);
  	
  	event MinterUpdated(address indexed minter);
}