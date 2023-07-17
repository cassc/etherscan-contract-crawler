// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IRollStaker {
    function depositFor(uint256 _amount, address _receiver) external;
}