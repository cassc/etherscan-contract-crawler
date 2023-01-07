// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface ILudicrous {
    function deposit(uint256 _amount, address _to) external;

    function withdraw(address _from, uint256 _amount) external;
}