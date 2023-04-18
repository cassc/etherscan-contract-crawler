// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IInstaList {
    function accountID(address) external view returns(uint64);
}