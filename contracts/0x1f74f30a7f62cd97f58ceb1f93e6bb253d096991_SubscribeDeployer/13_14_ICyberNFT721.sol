// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

/**
 * @title ICyberNFT721
 * @author CyberConnect
 */
interface ICyberNFT721 {
    /**
     * @notice Gets total number of tokens in existence, burned tokens will reduce the count.
     *
     * @return uint256 The total supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Burns a token.
     *
     * @param tokenId The token ID to burn.
     */
    function burn(uint256 tokenId) external;
}