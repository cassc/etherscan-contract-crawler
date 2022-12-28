// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library LibAddressArray {
    function contains(
        address[] memory self,
        address _address
    ) internal pure returns (bool contained) {
        for (uint256 i; i < self.length; ) {
            if (_address == self[i]) {
                return true;
            }
            unchecked {
                i++;
            }
        }
        return false;
    }
}