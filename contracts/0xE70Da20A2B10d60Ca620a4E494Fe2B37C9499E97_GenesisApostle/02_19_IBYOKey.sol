// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract IBYOKey {
    function balanceOf(address owner, uint256 index) external virtual view returns (uint256 balance);
    function burnFromRedeem(address _account, uint256 _keyIdx, uint256 _amount) external virtual;
}