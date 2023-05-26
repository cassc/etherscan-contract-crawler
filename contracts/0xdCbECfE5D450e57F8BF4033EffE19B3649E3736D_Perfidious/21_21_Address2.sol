// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library Address2 {
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}