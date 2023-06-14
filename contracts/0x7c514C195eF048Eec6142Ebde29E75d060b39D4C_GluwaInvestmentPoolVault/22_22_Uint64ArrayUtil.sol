// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/** @title Library functions used by contracts within this ecosystem.*/
library Uint64ArrayUtil {
    function removeByIndex(uint64[] storage self, uint64 index) internal {
        if (index >= self.length) return;

        for (uint64 i = index; i < self.length - 1; ) {
            unchecked {
                self[i] = self[++i];
            }
        }
        self.pop();
    }

    /// @dev the value for each item in the array must be unique
    function removeByValue(uint64[] storage self, uint64 val) internal {
        if (self.length == 0) return;
        uint64 j;
        for (uint64 i; i < self.length - 1; ) {
            unchecked {
                if (self[i] == val) {
                    j = i + 1;
                }
                self[i] = self[j];
                ++j;
                ++i;
            }
        }
        self.pop();
    }

    /// @dev add new item into the array
    function add(uint64[] storage self, uint64 val) internal {
        self.push(val);
    }
}