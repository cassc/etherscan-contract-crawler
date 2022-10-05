// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.7;

/// @dev See https://eips.ethereum.org/EIPS/eip-5114
interface IERC5114 {
	// fired anytime a new instance of this token is minted
	// this event **MUST NOT** be fired twice for the same `tokenId`
	event Mint(uint256 indexed tokenId, address indexed nftAddress, uint256 indexed nftTokenId);

	// returns the NFT that this token is bound to.
	// this function **MUST** throw if the token hasn't been minted yet
	// this function **MUST** always return the same result every time it is called after it has been minted
	// this function **MUST** return the same value as found in the original `Mint` event for the token
	function ownerOf(uint256 index) external view returns (address nftAddress, uint256 nftTokenId);

	// returns a URI with details about this token collection
	// the metadata returned by this is merged with the metadata return by `tokenUri(uint256)`
	// the collectionUri **MUST** be immutable (e.g., ipfs:// and not http://)
	// the collectionUri **MUST** be content addressable (e.g., ipfs:// and not http://)
	// data from `tokenUri` takes precedence over data returned by this method
	// any external links referenced by the content at `collectionUri` also **MUST** follow all of the above rules
	function collectionUri() external view returns (string memory collectionUri);

	// returns a censorship resistant URI with details about this token instance
	// the collectionUri **MUST** be immutable (e.g., ipfs:// and not http://)
	// the collectionUri **MUST** be content addressable (e.g., ipfs:// and not http://)
	// data from this takes precedence over data returned by `collectionUri`
	// any external links referenced by the content at `tokenUri` also **MUST** follow all of the above rules
	function tokenUri(uint256 tokenId) external view returns (string memory tokenUri);

	// returns a string that indicates the format of the tokenUri and collectionUri results (e.g., 'EIP-ABCD' or 'soulbound-schema-version-4')
	function metadataFormat() external pure returns (string memory format);
}