// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface IPaymentSplitterInitializer {
    function initialize(address[] memory payees, uint256[] memory shares_)
        external;
}