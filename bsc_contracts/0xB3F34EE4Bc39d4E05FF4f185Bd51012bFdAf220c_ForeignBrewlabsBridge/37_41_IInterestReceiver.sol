// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IInterestReceiver {
    function onInterestReceived(address _token) external;
}