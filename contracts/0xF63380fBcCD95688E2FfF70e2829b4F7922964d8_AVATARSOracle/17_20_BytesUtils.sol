// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

library BytesUtils {
    function _sliceDynamicArray(
        uint256 _start,
        uint256 _end,
        bytes memory _data
    ) internal pure returns (bytes memory) {
        bytes memory result = new bytes(_end - _start);
        for (uint256 i = 0; i < _end - _start; ++i) {
            result[i] = _data[_start + i];
        }
        return result;
    }
}