// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/**
 * @title IXTokenWrapper
 * @author Protofire
 * @dev XTokenWrapper Interface.
 *
 */

interface IXTokenWrapper {
    /**
     * @dev Token to xToken registry.
     */
    function tokenToXToken(address _token) external view returns (address);
}