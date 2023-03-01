//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface INFT {
	function mint(string calldata _tokenURI, address _to) external returns (uint256);

	function burn(uint256 _tokenId) external;

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) external;

	function ownerOf(uint256 tokenId) external view returns (address);

	function tokenURI(uint256 tokenId) external view returns (string memory);

	function approve(address to, uint256 tokenId) external;

	function setApprovalForAll(address operator, bool approved) external;

	function addManagers(address _manager) external;

	function getRoyaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address reciever, uint256 _rate);

	function setArtistRoyalty(
		uint256 _tokenId,
		address _receiver,
		uint96 _feeNumerator
	) external;

	function checkNft(uint256 _tokenId) external returns (bool);
}