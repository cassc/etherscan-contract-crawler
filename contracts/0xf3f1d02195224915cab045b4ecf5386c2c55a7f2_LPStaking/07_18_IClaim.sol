// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IClaim {
    function claim(uint256 requested_) external payable;
    function setClaim(address _from, uint256 _amount) external;
}