// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

contract HasSecondarySaleFees is ERC165Storage {
	
	mapping(uint256 => address payable[]) royaltyAddressMemory;
	mapping(uint256 => uint256[]) royaltyMemory;  
	mapping(uint256 => uint256) artworkNFTReference;
		
   /*
	* bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
	* bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
	*
	* => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
	*/
	
	bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;
	
	constructor() {
		_registerInterface(_INTERFACE_ID_FEES);
	}

	function getFeeRecipients(uint256 id) external view returns (address payable[] memory){
		uint256 NFTRef = artworkNFTReference[id];
		return royaltyAddressMemory[NFTRef];
	}

	function getFeeBps(uint256 id) external view returns (uint[] memory){
		uint256 NFTRef = artworkNFTReference[id];
		return royaltyMemory[NFTRef];
	}
}