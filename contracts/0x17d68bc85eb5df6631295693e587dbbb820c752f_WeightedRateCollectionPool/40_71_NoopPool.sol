// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/**
 * @title No Operation Pool Configuration (for emergency pause on proxied
 * pools)
 * @author MetaStreet Labs
 */
contract NoopPool {
    /**
     * @notice Get implementation name
     * @return Implementation name
     */
    function IMPLEMENTATION_NAME() external pure virtual returns (string memory) {
        return "NoopPool";
    }

    /**
     * @notice Get implementation version
     * @return Implementation version
     */
    function IMPLEMENTATION_VERSION() external pure returns (string memory) {
        return "0.0";
    }
}