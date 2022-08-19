// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

library LibAddressArray {
    function includes(address[] memory self, address value)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i] == value) {
                return true;
            }
        }

        return false;
    }
}