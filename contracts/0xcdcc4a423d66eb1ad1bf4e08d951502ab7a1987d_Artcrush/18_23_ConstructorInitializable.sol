// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @author emo.eth
 * @notice Abstract smart contract that provides an onlyUninitialized modifier which only allows calling when
 *         from within a constructor of some sort, whether directly instantiating an inherting contract,
 *         or when delegatecalling from a proxy
 */
abstract contract ConstructorInitializable {
    error AlreadyInitialized();

    modifier onlyConstructor() {
        if (address(this).code.length != 0) {
            revert AlreadyInitialized();
        }
        _;
    }
}