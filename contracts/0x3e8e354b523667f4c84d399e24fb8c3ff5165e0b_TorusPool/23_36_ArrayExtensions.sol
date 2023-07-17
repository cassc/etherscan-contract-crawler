// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

library ArrayExtensions {
    function copy(uint256[] memory array) internal pure returns (uint256[] memory) {
        uint256[] memory copy_ = new uint256[](array.length);
        for (uint256 i = 0; i < array.length; i++) {
            copy_[i] = array[i];
        }
        return copy_;
    }
}