// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

library Types {
    struct ICall {
        address _to;
        uint256 _value;
        bytes _calldata;
    }
}