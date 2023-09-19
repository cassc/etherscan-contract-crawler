// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

interface IERC721x {

	/**
	 * @dev Returns if the token is locked (non-transferrable) or not.
	 */
	function isUnlocked(uint256 _id) external view returns(bool);

	/**
	 * @dev Returns the amount of locks on the token.
	 */
	function lockCount(uint256 _tokenId) external view returns(uint256);

	/**
	 * @dev Returns if a contract is allowed to lock/unlock tokens.
	 */
	function approvedContract(address _contract) external view returns(bool);

	/**
	 * @dev Returns the contract that locked a token at a specific index in the mapping.
	 */
	function lockMap(uint256 _tokenId, uint256 _index) external view returns(address);

	/**
	 * @dev Returns the mapping index of a contract that locked a token.
	 */
	function lockMapIndex(uint256 _tokenId, address _contract) external view returns(uint256);

	/**
	 * @dev Locks a token, preventing it from being transferrable
	 */
	function lockId(uint256 _id) external;

	/**
	 * @dev Unlocks a token.
	 */
	function unlockId(uint256 _id) external;

	/**
	 * @dev Unlocks a token from a given contract if the contract is no longer approved.
	 */
	function freeId(uint256 _id, address _contract) external;
}