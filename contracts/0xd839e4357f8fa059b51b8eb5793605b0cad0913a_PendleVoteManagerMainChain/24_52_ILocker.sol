// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

interface ILocker {
    function lockFor(uint256 _amount, address _for) external;
}