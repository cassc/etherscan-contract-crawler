//SPDX-License-Identifier: UNLICENSED
// File: contracts/token/BEP20/lib/IBEP20.sol



pragma solidity ^0.8.0;

/**
 * @title IBEP20
 * @dev Interface of the BEP standard.
 */

import "./IERC20.sol";
interface IBEP20 is IERC20 {
    /**
     * @dev Returns the token owner.
     */
    function getOwner() external view returns (address);
}

