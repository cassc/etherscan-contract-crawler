// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IOlympus {
    /**
     * @notice index is used to convert from sOhm to gOhm
     */
    function index() external view returns (uint256);
}