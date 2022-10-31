// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

library StringUtils {
    function getSlice(uint256 begin, uint256 end, string memory text) internal pure returns (string memory) {
        bytes memory a = new bytes(end - begin + 1);
        for (uint i = 0; i <= end - begin; i++) {
            a[i] = bytes(text)[i + begin - 1];
        }
        return string(a);
    }
}