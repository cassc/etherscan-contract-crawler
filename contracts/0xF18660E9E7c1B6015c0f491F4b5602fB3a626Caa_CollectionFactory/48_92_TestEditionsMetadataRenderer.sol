// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../metadata/EditionsMetadataRenderer.sol";

/**
 * @author [email protected]
 * @dev Mock EditionsMetadataRenderer
 */
contract TestEditionsMetadataRenderer is EditionsMetadataRenderer {
    /**
     * @dev Test function to test upgrades
     */
    function test() external pure returns (string memory) {
        return "test";
    }
}