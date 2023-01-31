// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice Minimal interface for mint pass contract
 * @dev See https://etherscan.io/address/0x1278fb63b150e1c9cc478824e589045729321c54
 */
interface IMintPass {
    function burn(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}