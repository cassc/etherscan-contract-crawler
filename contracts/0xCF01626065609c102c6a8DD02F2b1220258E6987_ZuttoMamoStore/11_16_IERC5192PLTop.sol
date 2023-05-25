// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title IERC5192PLTop
 * @dev Interface to be implemented in the parent NFT.
 */
interface IERC5192PLTop {
	/**
	 * @dev Returns the owner address of the NFT associated with the parent。
	 */
	function ownerOfParentLinkSbt(
		address _parentLinkSbtContract,
		uint256 _parentLinkSbtTokenId
	) external view returns (address parentTokenOwner);
}