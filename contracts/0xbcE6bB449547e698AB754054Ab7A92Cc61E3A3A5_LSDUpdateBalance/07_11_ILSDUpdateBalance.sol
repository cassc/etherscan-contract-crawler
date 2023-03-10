// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ILSDUpdateBalance {
    function getLastUpdateVitualETHBalanceTime()
        external
        view
        returns (uint256);

    function getVirtualETHBalance() external view returns (uint256);

    function addVirtualETHBalance(uint256 _amount) external;

    function subVirtualETHBalance(uint256 _amount) external;

    function updateVirtualETHBalance() external;

    function getTotalLSETHSupply() external view returns (uint256);

    function getTotalVELSDSupply() external view returns (uint256);

    // Rocket Pool Staking ETH Balance
    function getTotalETHInRP() external view returns (uint256);

    function getTotalETHInLIDO() external view returns (uint256);

    function getTotalETHInSWISE() external view returns (uint256);
}