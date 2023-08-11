/**
 *Submitted for verification at Etherscan.io on 2023-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStoreOfValue {
    function increment() external;
    function getValue() external view returns (uint);
}

contract Incrementer {
    IStoreOfValue public storeOfValue;

    constructor(address _storeOfValue) {
        storeOfValue = IStoreOfValue(_storeOfValue);
    }

    function incrementBy(uint _value) public {
        for (uint i = 0; i < _value; i++) {
            storeOfValue.increment();
        }
    }
}