// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Dogelon is IERC721 {
	
	function setMinterContract(address _minterContract) external;

	function setMetadataContract(address _metadataContract) external;

	function mint(address to, uint256 imageHash, bytes32[] calldata merkleProof, uint256 whitelistQuantity) external payable;

	function updateImage(address userAddress, uint256 newImageHash, uint256 _tokenId) external;
	
	function burn(uint256 _tokenId) external;
			
}