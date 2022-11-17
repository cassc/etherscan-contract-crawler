// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../mint/MintManager.sol";

/**
 * @author [email protected]
 * @dev Mock MintManager
 */
contract TestMintManager is MintManager {
    /**
     * @dev Test function to test upgrades
     */
    function test() external pure returns (string memory) {
        return "test";
    }
}