// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title ITokenMint
 * @notice Token minting interface
 */
interface ITokenMint {
    /**
     * @notice Mints tokens to the account, increasing the total supply
     * @param _to The token receiver account address
     * @param _amount The number of tokens to mint
     * @return Token burning success status
     */
    function mint(address _to, uint256 _amount) external returns (bool);
}