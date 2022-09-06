// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface INetwork {
    function increaseShare(address _shareholder, uint256 _unlocks) external;
    function decreaseShare(address _shareholder) external;

    function deposit() external payable;

    function distributeDividend(address _shareholder) external;
}