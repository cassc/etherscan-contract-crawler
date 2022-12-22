// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './interfaces/IRoles.sol';
import './Ownable.sol';

abstract contract Roles is IRoles, Ownable {
    address private _controllerAddress;

    modifier onlyController() virtual {
        if (_msgSender() != getControllerAddress())
            revert SenderIsNotController();
        _;
    }

    function setControllerAddress(address controllerAddress)
        public
        virtual
        override
        onlyOwner
    {
        _controllerAddress = controllerAddress;

        emit ControllerAddressUpdated(controllerAddress);
    }

    function getControllerAddress()
        public
        view
        virtual
        override
        returns (address)
    {
        return _controllerAddress;
    }
}