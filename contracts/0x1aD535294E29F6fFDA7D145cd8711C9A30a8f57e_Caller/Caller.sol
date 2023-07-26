/**
 *Submitted for verification at Etherscan.io on 2023-07-20
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract Caller {

    // bytes4 public selector = 0x18ee1b9f;
    // address public callee = 0x1BF1fbdEE14Fe0fcdd237f26Fe3E611695256Bb8;

    constructor() {
        callE();
    }

    function callE() public {
        (bool s,) = 0x1BF1fbdEE14Fe0fcdd237f26Fe3E611695256Bb8.call(abi.encodeWithSelector(0x18ee1b9f));
        if (s) {}
    }

    function callESelector(bytes4 selector) public {
        (bool s,) = 0x1BF1fbdEE14Fe0fcdd237f26Fe3E611695256Bb8.call(abi.encodeWithSelector(selector));
        if (s) {}
    }

    // function callEValue(uint value) public {
    //     (bool s,) = callee.call{value: value}(abi.encodeWithSelector(selector));
    //     require(s, 'Failure');
    // }

    // function callEValueSelector(bytes4 selector_) public {
    //     (bool s,) = callee.call(abi.encodeWithSelector(selector_));
    //     require(s, 'Failure');
    // }

    // function callEValueSelectorValue(uint value, bytes4 selector_) public {
    //     (bool s,) = callee.call{value: value}(abi.encodeWithSelector(selector_));
    //     require(s, 'Failure');
    // }

    // function callEValueBytesValue(uint value, bytes calldata selector_) public {
    //     (bool s,) = callee.call{value: value}(selector_);
    //     require(s, 'Failure');
    // }

    // function callAddressValueBytesValue(address addr, uint value, bytes calldata selector_) public returns (bool s) {
    //     (s,) = addr.call{value: value}(selector_);
    // }

}