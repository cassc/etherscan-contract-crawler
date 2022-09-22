// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @notice Governable interface
 */
interface IGovernable {
    function governor() external view returns (address _governor);
}