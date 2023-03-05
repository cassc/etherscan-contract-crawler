// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.9;

interface IERC721PepeMetadataV2 {
	
	function setBaseURI(string memory uri) external;
	
	function setPepeContract(address _pepe) external;
	
	function tokenURI(uint256 hash) external view returns (string memory);
			
}