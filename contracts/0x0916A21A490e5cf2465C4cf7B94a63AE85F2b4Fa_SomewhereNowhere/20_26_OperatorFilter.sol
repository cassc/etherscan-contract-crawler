// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './interfaces/IOperatorFilter.sol';
import './interfaces/IOperatorFilterRegistry.sol';
import './Roles.sol';

abstract contract OperatorFilter is IOperatorFilter, Roles {
    address private _operatorFilterRegistryAddress;

    modifier onlyAllowedOperator(address from) virtual {
        if (from != _msgSender()) {
            _checkFilterOperator(_msgSender());
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    function register() public virtual override onlyController {
        if (_operatorFilterRegistryAddress == address(0))
            revert OperatorFilterRegistryAddressIsZeroAddress();

        IOperatorFilterRegistry(_operatorFilterRegistryAddress).register(
            address(this)
        );
    }

    function registerAndSubscribe(address subscription)
        public
        virtual
        override
        onlyController
    {
        if (_operatorFilterRegistryAddress == address(0))
            revert OperatorFilterRegistryAddressIsZeroAddress();

        IOperatorFilterRegistry(_operatorFilterRegistryAddress)
            .registerAndSubscribe(address(this), subscription);
    }

    function setOperatorFilterRegistryAddress(
        address operatorFilterRegistryAddress
    ) public virtual override onlyController {
        _operatorFilterRegistryAddress = operatorFilterRegistryAddress;

        emit OperatorFilterRegistryAddressUpdated(
            operatorFilterRegistryAddress
        );
    }

    function subscribe(address subscription)
        public
        virtual
        override
        onlyController
    {
        if (_operatorFilterRegistryAddress == address(0))
            revert OperatorFilterRegistryAddressIsZeroAddress();

        IOperatorFilterRegistry(_operatorFilterRegistryAddress).subscribe(
            address(this),
            subscription
        );
    }

    function unregister() public virtual override onlyController {
        if (_operatorFilterRegistryAddress == address(0))
            revert OperatorFilterRegistryAddressIsZeroAddress();

        IOperatorFilterRegistry(_operatorFilterRegistryAddress).unregister(
            address(this)
        );
    }

    function unsubscribe() public virtual override onlyController {
        if (_operatorFilterRegistryAddress == address(0))
            revert OperatorFilterRegistryAddressIsZeroAddress();

        IOperatorFilterRegistry(_operatorFilterRegistryAddress).unsubscribe(
            address(this),
            false
        );
    }

    function getOperatorFilterRegistryAddress()
        public
        view
        virtual
        override
        returns (address)
    {
        return _operatorFilterRegistryAddress;
    }

    function _checkFilterOperator(address operator) internal view virtual {
        if (_operatorFilterRegistryAddress != address(0)) {
            if (
                !IOperatorFilterRegistry(_operatorFilterRegistryAddress)
                    .isOperatorAllowed(address(this), operator)
            ) revert OperatorIsNotAllowed(operator);
        }
    }
}