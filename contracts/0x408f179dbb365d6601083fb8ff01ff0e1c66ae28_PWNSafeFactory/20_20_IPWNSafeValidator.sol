// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;


/**
 * @title PWNSafe Validator
 * @notice PWNSafe Validator is used in AssetTransferRights contract to determine
 *         if transfer via ATR token is possible without burning the ATR token.
 */
interface IPWNSafeValidator {

	/**
	 * @param safe Address that is tested to be a valid PWNSafe
	 * @return True if `safe` address is valid PWNSafe
	 */
	function isValidSafe(address safe) external view returns (bool);

}