pragma solidity 0.8.9;
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
    event SortedIntoQ(bytes32 indexed id, uint256 newIdx, uint256 oldIdx);

    /**
     * @dev assumes that `id` of a single credit line within the Line of Credit facility (same lender/token) is stored only once in the `positions` array 
     since there's no reason for them to be stored multiple times.
     * This means cleanup on _close() and checks on addCredit() are CRITICAL. If `id` is duplicated then the position can't be closed
     * @param ids - all current credit lines on the Line of Credit facility
     * @param id - the hash id of the credit line to be removed from active ids after removePosition() has run
     * @return newPositions - all active credit lines on the Line of Credit facility after the `id` has been removed [Bob - consider renaming to newIds
     * Bob - consider renaming this function removeId()
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
     * @notice - swap the first element in the queue, provided it is null, with the next available valid(non-null) id
     * @dev    - Must perform check for ids[0] being valid (non-zero) before calling
     * @param ids - all current credit lines on the Line of Credit facility
     * @return swapped - returns true if the swap has occurred
     */
    function stepQ(bytes32[] storage ids) external returns (bool) {
        uint256 len = ids.length;
        if (len <= 1) return false;
        if (len == 2 && ids[1] != bytes32(0)) {
            (ids[0], ids[1]) = (ids[1], ids[0]);
            emit SortedIntoQ(ids[0], 0, 1);
            return true;
        } // skip the loop if we don't need

        // we never check the first id, because we already know it's null
        for (uint i = 1; i < len; ) {
            if (ids[i] != bytes32(0)) {
                (ids[0], ids[i]) = (ids[i], ids[0]); // swap the ids
                emit SortedIntoQ(ids[0], 0, i);
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