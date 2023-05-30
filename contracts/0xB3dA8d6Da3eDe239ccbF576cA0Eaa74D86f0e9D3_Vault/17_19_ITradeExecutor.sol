/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface ITradeExecutor {
    function vault() external view returns (address);

    // function withdraw(bytes calldata _data) external;

    function totalFunds()
        external
        view
        returns (uint256 posValue, uint256 lastUpdatedBlock);
}