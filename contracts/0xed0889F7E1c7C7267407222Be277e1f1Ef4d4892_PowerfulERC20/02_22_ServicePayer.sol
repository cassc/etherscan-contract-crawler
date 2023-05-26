// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface IPayable {
    function pay(string memory serviceName) external payable;
}

/**
 * @title ServicePayer
 * @dev Implementation of the ServicePayer
 */
abstract contract ServicePayer {

    constructor (address payable receiver, string memory serviceName) payable {
        IPayable(receiver).pay{value: msg.value}(serviceName);
    }
}