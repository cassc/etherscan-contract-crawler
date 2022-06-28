// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract TimeContract {
    function passed(uint _timestamp) internal view returns(bool) {
        return _timestamp < block.timestamp;
    }

    function notPassed(uint _timestamp) internal view returns(bool) {
        return !passed(_timestamp);
    }
}