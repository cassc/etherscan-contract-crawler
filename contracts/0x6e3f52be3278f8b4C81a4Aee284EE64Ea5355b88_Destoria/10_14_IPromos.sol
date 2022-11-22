// SPDX-License-Identifier: MIT
// Promos v1.0.0
// Creator: promos.wtf

pragma solidity ^0.8.0;

interface IPromos {
    function mintPromos(address _to, uint256 _amount) external payable;

    receive() external payable;
}