/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

/// @notice this library is used to reduce size contract when require condition
library Require {
    function _require(bool condition, string memory reason) internal pure {
        require(condition, reason);
    }
}