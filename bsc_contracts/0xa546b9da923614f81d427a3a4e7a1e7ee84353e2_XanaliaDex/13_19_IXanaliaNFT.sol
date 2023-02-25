// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IXanaliaNFT {
	function setXanaliaUriAddress(address _xanaliaUriAddress) external;

	function getCreator(uint256 _id) external view returns (address);

	function getRoyaltyFee(uint256 _id) external view returns (uint256);

	function create(
		string calldata _tokenURI,
		uint256 _royaltyFee,
		address _owner
	) external returns (uint256);

	function tokenURI(uint256 tokenId_) external view returns (string memory);

	function getContractAuthor() external view returns (address);

	function isApprovedForAll(address owner, address operator) external view returns (bool);

	function setApprovalForAll(
		address owner,
		address operator,
		bool approved
	) external;

	function transferOwnership(address owner) external;

	function getAuthor(uint256 tokenId) external view returns (address);
}