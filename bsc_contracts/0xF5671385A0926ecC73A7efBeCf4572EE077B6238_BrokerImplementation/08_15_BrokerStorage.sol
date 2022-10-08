// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/Admin.sol';

abstract contract BrokerStorage is Admin {

    address public implementation;

    // user => pool => symbolId => asset => client
    mapping (address => mapping (address => mapping (bytes32 => mapping (address => address)))) public clients;

}