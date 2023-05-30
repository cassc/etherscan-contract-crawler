// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IMaxSupplyInitializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to include a maximum supply.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface IMaxSupplyInitializer is IERC165 {

    /**
     * @notice Initializes max supply parameters
     */
    function initializeMaxSupply(uint256 maxSupply_) external;
}