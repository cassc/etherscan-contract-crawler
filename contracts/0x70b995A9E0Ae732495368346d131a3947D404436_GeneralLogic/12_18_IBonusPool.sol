// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IBonusPool {
    function updatePoolUser(address _token, address _account, uint256 _amount) external;
}