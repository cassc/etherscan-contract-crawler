// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IUniqOperator {
    function isOperator(uint256 operatorType, address operatorAddress)
        external
        view
        returns (bool);

    function uniqAddresses(uint256 index) external view returns (address);
}