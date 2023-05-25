// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.7.0 <0.9.0;

import { IERC5192 } from "./IERC5192.sol";

/**
 * @title IERC5192PL
 * @dev Interface of ERC5192PL.
 */

interface IERC5192PL is IERC5192 {
	/**
	 * @dev Cannot transfer when locked.
	 */
	error ErrLocked();

	/**
	 * @dev Cannot transfer when token locked.
	 */
	error ErrTokenLocked();

	/**
	 * @dev The token does not exist.
	 */
	error ErrNotFound();

	/**
	 * @dev Cannot query set function for the null address.
	 */
	error ErrNullAddress();

	/**
	 * @dev Error if not parent contract address.
	 */
	error ErrNotAllowtedAddress();

	/**
	 * @dev Error if sale has not started.
	 */
	error ErrNotSaleActive();

	/**
	 * @dev Unlock tokens only when called from the parent contract address.
	 */
	function setIsTokenUnLocked(uint256 _tokenId, bool _value) external;

	/**
	 * @dev Set parent contract address.
	 */
	function setParentContractAddress(address _parentContractAddress) external;
}