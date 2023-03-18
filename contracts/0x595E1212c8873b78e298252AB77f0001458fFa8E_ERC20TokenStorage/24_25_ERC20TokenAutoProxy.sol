// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';
import { GovernedERC20 } from './GovernedERC20.sol';
import { ERC20TokenGovernedProxy } from './ERC20TokenGovernedProxy.sol';

contract ERC20TokenAutoProxy is GovernedERC20 {
    constructor(
        address _proxy,
        IGovernedContract _impl,
        address _owner
    ) public GovernedERC20(_proxy, _owner) {
        if (_proxy == address(0)) {
            _proxy = address(new ERC20TokenGovernedProxy(_impl));
        }
        proxy = _proxy;
    }
}