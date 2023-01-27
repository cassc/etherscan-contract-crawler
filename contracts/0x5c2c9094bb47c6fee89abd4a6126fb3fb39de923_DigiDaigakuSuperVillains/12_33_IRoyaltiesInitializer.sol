// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IRoyaltiesInitializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to include OpenZeppelin ERC2981 functionality.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface IRoyaltiesInitializer is IERC165 {

    /**
     * @notice Initializes royalty parameters
     */
    function initializeRoyalties(address receiver, uint96 feeNumerator) external;
}