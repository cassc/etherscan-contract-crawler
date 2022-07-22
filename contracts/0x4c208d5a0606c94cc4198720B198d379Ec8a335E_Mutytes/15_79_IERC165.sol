// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC165 interface
 * @dev See https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice Query whether contract supports an interface
     * @param interfaceId The interface id
     * @return isSupported Whether the interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external returns (bool);
}