// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IERCOwnable {
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

    function owner() external view returns (address);
}