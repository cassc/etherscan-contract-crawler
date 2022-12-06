// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

library StringsUtils {
    function contains(string memory self, string memory needle) internal pure returns (bool) {
        bytes memory selfBytes = bytes(self);
        bytes memory needleBytes = bytes(needle);

        if (needleBytes.length > selfBytes.length) return false;

        bool found = false;
        for (uint i = 0; i < selfBytes.length - needleBytes.length; i++) {
            bool flag = true;
            for (uint j = 0; j < needleBytes.length; j++)
                if (selfBytes [i + j] != needleBytes [j]) {
                    flag = false;
                    break;
                }
            if (flag) {
                found = true;
                break;
            }
        }

        return found;
    }
}