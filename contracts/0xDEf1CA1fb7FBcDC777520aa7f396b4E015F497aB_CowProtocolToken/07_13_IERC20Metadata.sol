// SPDX-License-Identifier: MIT

// Vendored from OpenZeppelin Contracts v4.4.0, see:
// <https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.4.0/contracts/token/ERC20/extensions/IERC20Metadata.sol>
// The following changes were made:
// - Vendored imports

// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}