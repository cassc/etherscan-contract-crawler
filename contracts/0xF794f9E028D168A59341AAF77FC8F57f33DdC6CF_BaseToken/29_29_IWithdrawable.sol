//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

interface IWithdrawable {
    function pendingWithdrawal() external view returns (uint);
    function withdraw(uint amount) external;
    function withdrawAll() external;
}