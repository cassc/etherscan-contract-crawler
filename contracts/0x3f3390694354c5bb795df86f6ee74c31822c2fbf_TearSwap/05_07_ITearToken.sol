// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC20Upgradeable} from "@oz-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title ITearToken
 * @author Lozz (@lozzereth / www.allthingsweb3.com)
 * @notice Interface for $TEAR Token.
 */
interface ITearToken is IERC20Upgradeable {
    /// @notice When an account is not an approved EOA
    error NonApprovedEOA(address address_);

    /**
     * @notice Allow the EOA to mint tokens
     * @param recipient Recipient to receive tokens
     * @param amount Amount of token to issue
     */
    function eoaMint(address recipient, uint256 amount) external;
}