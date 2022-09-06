//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

interface ITradeExecutor {
    struct ActionStatus {
        bool inProcess;
        address from;
    }

    function vault() external view returns (address);

    function depositStatus() external returns (bool, address);

    function withdrawalStatus() external returns (bool, address);

    function initiateDeposit(bytes calldata _data) external;

    function confirmDeposit() external;

    function initiateWithdraw(bytes calldata _data) external;

    function confirmWithdraw() external;

    function totalFunds()
        external
        view
        returns (uint256 posValue, uint256 lastUpdatedBlock);
}