// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Pepe is IERC721 {
	
	function setBaseURI(string memory uri) external;
	
	function setPepeMinter(address _minter) external;
	
	function setAuthorizedSigningAddress(address signer) external;
	
	function mint(address to, uint256 imageHash) external;
	
	function burn(uint256 _tokenId) external;
			
}