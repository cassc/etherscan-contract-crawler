// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @notice It is returned if the amount is invalid.
 *         For ERC20, if amount is 0.
 *         For ERC721, any number that is not 1.
 *         For ERC1155, if amount is 0.
 */
error AmountInvalid();

/**
 * @notice It is returned if there is either a mismatch or an error in the length of the array(s).
 */
error LengthsInvalid();