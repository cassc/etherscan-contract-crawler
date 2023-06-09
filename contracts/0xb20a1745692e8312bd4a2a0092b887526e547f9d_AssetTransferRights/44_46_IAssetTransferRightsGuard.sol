// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;


/**
 * @title Asset Transfer Rights Guard Interface
 */
interface IAssetTransferRightsGuard {

	/**
	 * @dev Utility function used by AssetTransferRights contract to get information
	 *      about approvals for some asset contract on a wallet.
	 * @param safeAddress Address of a safe in question
	 * @param assetAddress Address of an asset contract
	 * @return True if wallet has at least one operator for given asset contract
	 */
	function hasOperatorFor(address safeAddress, address assetAddress) external view returns (bool);

}