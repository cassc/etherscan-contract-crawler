// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

library OrderOrEndpoint {
    
    function getOrderOrEndptVal(mapping(int24 =>int24) storage self, int24 point, int24 pd) internal view returns(int24 val) {
        if (point % pd != 0) {
            return 0;
        }
        val = self[point / pd];
    }
    function setOrderOrEndptVal(mapping(int24 =>int24) storage self, int24 point, int24 pd, int24 val) internal {
        self[point / pd] = val;
    }
    
}