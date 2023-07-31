// SPDX-License-Identifier: GPL-3.0
// Copyright: https://github.com/test-org2222/Line-Of-Credit/blog/master/COPYRIGHT.md

 pragma solidity ^0.8.16;
import {ILineOfCredit} from "../interfaces/ILineOfCredit.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {CreditLib} from "./CreditLib.sol";

/**
 * @title Debt DAO Line of Credit Library
 * @author Kiba Gateaux
 * @notice Core logic and variables to be reused across all Debt DAO Marketplace Line of Credit contracts
 */
library CreditListLib {
    event QueueCleared();
    event SortedIntoQ(bytes32 indexed id, uint256 indexed newIdx, uint256 indexed oldIdx, bytes32 oldId);
    error CantStepQ();

    /**
     * @notice  - Removes a position id from the active list of open positions.
     * @dev     - assumes `id` is stored only once in the `positions` array. if `id` occurs twice, debt would be double counted.
     * @param ids           - all current credit lines on the Line of Credit facility
     * @param id            - the hash id of the credit line to be removed from active ids after removePosition() has run
     * @return newPositions - all active credit lines on the Line of Credit facility after the `id` has been removed [Bob - consider renaming to newIds
     */
    function removePosition(bytes32[] storage ids, bytes32 id) external returns (bool) {
        uint256 len = ids.length;

        for (uint256 i; i < len; ++i) {
            if (ids[i] == id) {
                delete ids[i];
                return true;
            }
        }

        return true;
    }

    /**
     * @notice  - swap the first element in the queue, provided it is null, with the next available valid(non-null) id
     * @dev     - Must perform check for ids[0] being valid (non-zero) before calling
     * @param ids       - all current credit lines on the Line of Credit facility
     * @return swapped  - returns true if the swap has occurred
     */
    function stepQ(bytes32[] storage ids) external returns (bool) {
        if (ids[0] != bytes32(0)) {
            revert CantStepQ();
        }

        uint256 len = ids.length;
        if (len <= 1) return false;

        // skip the loop if we don't need
        if (len == 2 && ids[1] != bytes32(0)) {
            (ids[0], ids[1]) = (ids[1], ids[0]);
            emit SortedIntoQ(ids[0], 0, 1, ids[1]);
            return true;
        }

        // we never check the first id, because we already know it's null
        for (uint i = 1; i < len; ) {
            if (ids[i] != bytes32(0)) {
                (ids[0], ids[i]) = (ids[i], ids[0]); // swap the ids in storage
                emit SortedIntoQ(ids[0], 0, i, ids[i]);
                return true; // if we make the swap, return early
            }
            unchecked {
                ++i;
            }
        }
        emit QueueCleared();
        return false;
    }
}