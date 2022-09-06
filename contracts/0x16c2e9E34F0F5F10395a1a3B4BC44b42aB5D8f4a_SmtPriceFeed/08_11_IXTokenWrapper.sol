//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

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

    function xTokenToToken(address _token) external view returns (address);
}