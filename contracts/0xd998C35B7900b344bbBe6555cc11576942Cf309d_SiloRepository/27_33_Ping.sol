// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;


library Ping {
    function pong(function() external pure returns(bytes4) pingFunction) internal pure returns (bool) {
        return pingFunction.address != address(0) && pingFunction.selector == pingFunction();
    }
}