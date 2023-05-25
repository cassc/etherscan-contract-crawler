// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title IERC5192PLConnector
 * @dev Interface to tie to parent.
 */
interface IERC5192PLConnector {
	/**
	 * @dev Returns true/false values for the existence of NFTs associated with the parent.
	 */
	function isParentLinkSbtExists(
		address _parentLinkSbtContract,
		uint256 _parentLinkSbtTokenId
	) external view returns (bool);

	/**
	 * @dev Returns the parent's token ID.
	 */
	function getParentLinkSbtTokenOwnerId(
		address _parentLinkSbtContract,
		uint256 _parentLinkSbtTokenId
	) external view returns (uint256);

	/**
	 * @dev Returns the value of index.
	 */
	function getParentLinkSbtTokenIndex(
		uint256 _parentTokenId,
		address _parentLinkSbtContract,
		uint256 _parentLinkSbtTokenId
	) external view returns (uint256);

	/**
	 * @dev Returns the number of contracts associated with the parent token ID.
	 */
	function getTotalParentLinkSbtContracts(uint256 _tokenId) external view returns (uint256);

	/**
	 * @dev Returns the number of token IDs associated with the parent token ID.
	 */
	function getTotalParentLinkSbtTokens(
		uint256 _tokenId,
		address _parentLinkSbtContract
	) external view returns (uint256);

	/**
	 * @dev Returns the contract address associated with the parent.
	 */
	function getParentLinkSbtContractByIndex(
		uint256 _tokenId,
		uint256 _index
	) external view returns (address parentLinkSbtContract);

	/**
	 * @dev Returns the token ID associated with the parent.
	 */
	function getParentLinkSbtTokenByIndex(
		uint256 _tokenId,
		address _parentLinkSbtContract,
		uint256 _index
	) external view returns (uint256 parentLinkSbtTokenId);
}