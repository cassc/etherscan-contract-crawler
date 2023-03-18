// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

import { RegistrantAutoProxy } from './RegistrantAutoProxy.sol';
import { Ownable } from '../Ownable.sol';

import { IGovernedContract } from '../interfaces/IGovernedContract.sol';
import { IRegistrantGovernedProxy } from './IRegistrantGovernedProxy.sol';

contract Registrant is Ownable, RegistrantAutoProxy {
    constructor(address _proxy) public RegistrantAutoProxy(_proxy, address(this)) {}

    // This function is called in order to upgrade to a new Registrant implementation
    function destroy(IGovernedContract _newImpl) external requireProxy {
        // Self destruct
        _destroy(_newImpl);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function migrate(IGovernedContract _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }

    function setSporkProxy(address payable _sporkProxy) external onlyOwner {
        IRegistrantGovernedProxy(proxy).setSporkProxy(_sporkProxy);
    }
}