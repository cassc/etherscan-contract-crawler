// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title ITokenDecimals
 * @notice Token decimals interface
 */
interface ITokenDecimals {
    /**
     * @notice Getter of the token decimals
     * @return Token decimals
     */
    function decimals() external pure returns (uint8);
}