// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from './OperatorFilterer.sol';
import '../utils/NiftysAccessControl.sol';

abstract contract DefaultOperatorFilterer is OperatorFilterer, NiftysAccessControl {
    address public DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor(address _owner)
        OperatorFilterer(DEFAULT_SUBSCRIPTION, true)
        NiftysAccessControl(_owner)
    {}

    function updateFilterRegistry(address _registry) public onlyOwner {
        _updateFilterRegistry(_registry);
    }
}