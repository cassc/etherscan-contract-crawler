// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.12;

interface IFinance {
    function deposit(
        address _token,
        uint256 _amount,
        string calldata _reference
    )
        external;
}