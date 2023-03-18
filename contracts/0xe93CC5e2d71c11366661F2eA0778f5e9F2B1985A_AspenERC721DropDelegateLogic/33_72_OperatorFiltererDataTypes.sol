// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IOperatorFiltererDataTypesV0 {
    struct OperatorFilterer {
        bytes32 operatorFiltererId;
        string name;
        address defaultSubscription;
        address operatorFilterRegistry;
    }
}