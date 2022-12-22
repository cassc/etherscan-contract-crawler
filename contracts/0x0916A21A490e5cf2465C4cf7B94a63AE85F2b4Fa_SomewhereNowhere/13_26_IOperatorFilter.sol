// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './IOperatorFilterRegistry.sol';
import './IRoles.sol';

interface IOperatorFilter is IRoles {
    error OperatorFilterRegistryAddressIsZeroAddress();

    error OperatorIsNotAllowed(address operator);

    event OperatorFilterRegistryAddressUpdated(
        address indexed operatorFilterRegistryAddress
    );

    function register() external;

    function registerAndSubscribe(address subscription) external;

    function setOperatorFilterRegistryAddress(
        address operatorFilterRegistryAddress
    ) external;

    function subscribe(address subscription) external;

    function unregister() external;

    function unsubscribe() external;

    function getOperatorFilterRegistryAddress() external view returns (address);
}