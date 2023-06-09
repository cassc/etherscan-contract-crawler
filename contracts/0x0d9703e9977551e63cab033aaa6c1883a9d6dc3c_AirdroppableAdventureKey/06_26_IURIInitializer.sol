// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IURIInitializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to include a base uri and suffix uri.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface IURIInitializer is IERC165 {

    /**
     * @notice Initializes uri parameters
     */
    function initializeURI(string memory baseURI_, string memory suffixURI_) external;
}