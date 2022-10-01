/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

import "../farm/AppStorage.sol";

/**
 * @title App Storage Library allows libaries to access Farmer's state.
 **/
library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}