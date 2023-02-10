//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IVerified
/// @author @dievardump
interface IDataHolder {
	/// @notice returns the uniqid for an NFT
	/// @param collection the collection
	/// @param tokenId the id
	/// @return an uniq id
	function id(address collection, uint256 tokenId) external view returns (bytes32);

	/// @notice returns the data holder for the given format of a verified id
	/// @param verifiedId the verified token id
	/// @param format the format id
	function getVerifiedFormatHolder(uint256 verifiedId, uint256 format) external view returns (address);

	/// @notice returns the verified id linked to the token
	/// @param collection the collection
	/// @param tokenId the id
	/// @return the verified if
	function getOriginTokenVerifiedId(address collection, uint256 tokenId) external view returns (uint256);

	/// @notice inits verifiedId storage
	/// @param verifiedId the verified token id
	/// @param collection the collection
	/// @param tokenId the id
	/// @param format the format provided
	/// @param dataHolder the contact holding the data for this format
	function initVerifiedTokenData(
		uint256 verifiedId,
		address collection,
		uint256 tokenId,
		uint256 format,
		address dataHolder
	) external;

	/// @notice allows to add another format safely (throws if already exist)
	/// @param collection the collection
	/// @param tokenId the id
	/// @param format the format provided
	/// @param dataHolder the contact holding the data for this format
	function safeSetData(
		address collection,
		uint256 tokenId,
		uint256 format,
		address dataHolder
	) external;

	/// @notice allows to add another format (it overwrites existing data for this format)
	/// @param collection the collection
	/// @param tokenId the id
	/// @param format the format provided
	/// @param dataHolder the contact holding the data for this format
	function setData(
		address collection,
		uint256 tokenId,
		uint256 format,
		address dataHolder
	) external;
}