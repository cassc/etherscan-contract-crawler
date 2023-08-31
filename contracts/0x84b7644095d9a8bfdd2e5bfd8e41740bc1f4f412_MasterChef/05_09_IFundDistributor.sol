// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFundDistributor {
    function distributeTo(address _receiver, uint256 _amount) external;
}