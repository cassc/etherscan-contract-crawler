// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDistinctiveCollection {
    function initialize(
        address payable _creator,
        string memory _name,
        string memory _symbol,
        address _core
    ) external;
}