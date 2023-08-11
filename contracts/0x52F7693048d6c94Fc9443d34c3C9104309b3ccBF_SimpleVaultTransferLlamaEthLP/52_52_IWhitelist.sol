// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ISafeOwnable } from '@solidstate/contracts/access/ownable/ISafeOwnable.sol';

/**
 * @title General whitelist interface for Insrt product instances
 */
interface IWhitelist is ISafeOwnable {
    /**
     * @notice returns whitelisted state of a given account for an Insrt product instance (eg ShardVault)
     * @param instance address of Insrt product instance
     * @param account account to check whitelisted state for
     * @param data any encoded data required to perform whitelist check
     * @return isWhitelisted whitelist state of account for given Insrt product instance
     */
    function isWhitelisted(
        address instance,
        address account,
        bytes calldata data
    ) external view returns (bool isWhitelisted);
}