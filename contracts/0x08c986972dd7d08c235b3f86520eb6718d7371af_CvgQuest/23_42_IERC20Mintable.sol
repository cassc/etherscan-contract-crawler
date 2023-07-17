// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

/**
 * @dev Interface for the optional mint function from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Mintable is IERC20Metadata {
    /**
     * @dev Mint `amount` of token to `account`
     */
    function mint(address account, uint256 amount) external;
}