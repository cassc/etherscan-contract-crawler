// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

interface IWallet {
    function account(address payable organizer) external payable;
}