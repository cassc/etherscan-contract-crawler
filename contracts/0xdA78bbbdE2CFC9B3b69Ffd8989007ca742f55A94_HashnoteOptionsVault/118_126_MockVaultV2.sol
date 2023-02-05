// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @title   MockVaultV2
 * @notice  Mock contract to test upgradability
 */
contract MockVaultV2 {
    function version() external pure returns (uint256) {
        return 2;
    }
}