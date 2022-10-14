// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IHorseNFT is IERC721EnumerableUpgradeable  {

	function mint(uint256 tokenId, address user) external;
	function tokenURI(uint256 tokenId) external view returns (string memory);
	function burn(uint256 tokenId) external;
	
}