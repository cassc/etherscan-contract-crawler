// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IOpenOceanCaller {
    struct CallDescription {
        uint256 target;
        uint256 gasLimit;
        uint256 value;
        bytes data;
    }
}