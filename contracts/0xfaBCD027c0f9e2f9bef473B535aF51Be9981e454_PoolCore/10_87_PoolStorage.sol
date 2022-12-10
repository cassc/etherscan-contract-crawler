// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {UserConfiguration} from "../libraries/configuration/UserConfiguration.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {ReserveLogic} from "../libraries/logic/ReserveLogic.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

/**
 * @title PoolStorage
 *
 * @notice Contract used as storage of the Pool contract.
 * @dev It defines the storage layout of the Pool contract.
 */
contract PoolStorage {
    bytes32 constant POOL_STORAGE_POSITION =
        bytes32(uint256(keccak256("paraspace.proxy.pool.storage")) - 1);

    function poolStorage()
        internal
        pure
        returns (DataTypes.PoolStorage storage rgs)
    {
        bytes32 position = POOL_STORAGE_POSITION;
        assembly {
            rgs.slot := position
        }
    }
}