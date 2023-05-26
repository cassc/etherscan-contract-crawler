//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMetadataRouter{
/*	enum NFTStandard{
		ERC721,
		ERC1155
	}*/
	struct SubNFT {
		address addr;
//		NFTStandard standard;
		uint256 tokenId;
		string baseURI;
	}
    /**
     * @dev Emitted when subNFT of `subId` is updated.
     */
	event UpdateSubNFT(uint16 indexed subId, address indexed addr, uint256 indexed tokenId, string key);
    /**
     * @dev Emitted when the first `subId` of `tokenId` is updated.
     */
	event UpdateSubIdForToken(uint256 tokenId, uint16 subId);
    /**
     * @dev Emitted when global priority list is updated.
     */
	event UpdateGlobalPriority();
    /**
     * @dev Emitted when main NFT contract address `addr` is updated.
     */
	event UpdateMainNFT(address indexed addr);

    /**
     * @dev Returns the subNFT infromation as SubNFT struct of `subId` index.
     */
	function subNFTs(uint16) external view returns(SubNFT memory);//(address, NFTStandard, uint256, string memory);

    /**
     * @dev Returns the first pritoriy `subId` of `tokenId` token.
     */
	function tokenPriority(uint256 tokenId) external view returns(uint16 subId);

    /**
     * @dev Returns the global priority subId array.
     */
	function globalPriorityArray() external view returns(uint16[] memory subIds);

    /**
     * @dev Returns the global priority `subId` at `index`.
     */
	function globalPriority(uint256 index) external view returns(uint16 subId);
	function getGlobalPriorityLength() external view returns(uint256);
	function mainNFT() external view returns(IERC721);
	function getURI(uint256 tokenId, address owner, uint256 param) external view returns(string memory);
	function getTotalSubNFTs() external view returns(uint256 total);

    /**
     * @dev append new SubNFT `info` on subNFTs array.
	 * Returns provided `sudId` starting from 1.
     */
	function appendSubNFT(SubNFT memory info) external returns(uint16 subId);
	function updateSubNFT(uint16 subId, SubNFT memory info) external;
	function disableSubNFT(uint16 subId) external;
	function setTokenPriority(uint256 tokenId, uint16 subId) external;
	function resetTokenPriority(uint256 tokenId) external;
	function setGlobalPriority(uint16[] memory subIds) external;
	function setMainNFT(IERC721 addr) external;

}