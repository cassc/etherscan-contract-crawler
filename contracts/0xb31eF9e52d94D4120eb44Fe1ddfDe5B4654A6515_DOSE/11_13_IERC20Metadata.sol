// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20 Token Standard, ERC1046 optional extension: Metadata
 * See https://eips.ethereum.org/EIPS/eip-1046
 * Note: the ERC-165 identifier for this interface is 0x3c130d90.
 */
interface IERC20Metadata {
    /**
     * Returns a distinct Uniform Resource Identifier (URI) for the token metadata.
     * @return a distinct Uniform Resource Identifier (URI) for the token metadata.
     */
    function tokenURI() external view returns (string memory);
}