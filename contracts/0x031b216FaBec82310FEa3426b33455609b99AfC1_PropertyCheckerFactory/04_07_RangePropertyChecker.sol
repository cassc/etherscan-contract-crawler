// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPropertyChecker} from "./IPropertyChecker.sol";
import {Clone} from "clones-with-immutable-args/Clone.sol";

contract RangePropertyChecker is IPropertyChecker, Clone {
    // Immutable params

    /**
     * @return Returns the lower bound of IDs allowed
     */
    function getLowerBoundInclusive() public pure returns (uint256) {
        return _getArgUint256(0);
    }

    /**
     * @return Returns the upper bound of IDs allowed
     */
    function getUpperBoundInclusive() public pure returns (uint256) {
        return _getArgUint256(32);
    }

    function hasProperties(uint256[] calldata ids, bytes calldata) external pure returns (bool isAllowed) {
        isAllowed = true;
        uint256 lowerBound = getLowerBoundInclusive();
        uint256 upperBound = getUpperBoundInclusive();
        uint256 numIds = ids.length;
        for (uint256 i; i < numIds;) {
            if (ids[i] < lowerBound) {
                return false;
            } else if (ids[i] > upperBound) {
                return false;
            }

            unchecked {
                ++i;
            }
        }
    }
}