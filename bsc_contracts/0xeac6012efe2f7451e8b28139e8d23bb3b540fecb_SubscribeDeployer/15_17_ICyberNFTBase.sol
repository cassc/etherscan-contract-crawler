// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface ICyberNFTBase {
    /**
     * @notice Gets total number of tokens in existence, burned tokens will reduce the count.
     *
     * @return uint256 The total supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the total number of minted tokens.
     *
     * @return uint256 The total minted tokens.
     */
    function totalMinted() external view returns (uint256);

    /**
     * @notice Gets the total number of burned tokens.
     *
     * @return uint256 The total burned tokens.
     */
    function totalBurned() external view returns (uint256);

    /**
     * @notice The EIP-712 permit function.
     *
     * @param spender The spender address.
     * @param tokenId The token ID to approve.
     * @param sig Must produce valid EIP712 signature with `s`, `r`, `v` and `deadline`.
     */
    function permit(
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Burns a token.
     *
     * @param tokenId The token ID to burn.
     */
    function burn(uint256 tokenId) external;
}