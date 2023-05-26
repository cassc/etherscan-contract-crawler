// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title ITokenBurn
 * @notice Token burning interface
 */
interface ITokenBurn {
    /**
     * @notice Burns tokens from the account, reducing the total supply
     * @param _from The token holder account address
     * @param _amount The number of tokens to burn
     * @return Token burning success status
     */
    function burn(address _from, uint256 _amount) external returns (bool);
}