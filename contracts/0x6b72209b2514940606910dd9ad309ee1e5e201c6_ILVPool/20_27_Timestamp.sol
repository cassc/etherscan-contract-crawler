// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @title Function for getting block timestamp.
/// @dev Base contract that is overridden for tests.
abstract contract Timestamp {
    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override time in helper test smart contracts.
     *
     * @return `block.timestamp` in mainnet, custom values in testnets (if overridden).
     */
    function _now256() internal view virtual returns (uint256) {
        // return current block timestamp
        return block.timestamp;
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}