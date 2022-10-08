// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface ICryptoWorldContract {
    function getAccount(address _address)
        external
        view
        returns (
            uint256 entryDate,
            uint256 lastWithdrawal,
            uint256 depositedValue,
            address referrerAccount
        );

    function donation() external payable;
}