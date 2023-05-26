// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Metadata.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
interface IERC20Capped is IERC20Metadata {
    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() external view returns (uint256);
}