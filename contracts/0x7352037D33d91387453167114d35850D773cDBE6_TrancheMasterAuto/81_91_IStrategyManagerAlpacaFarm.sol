//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IStrategyManagerAlpacaFarm {
    function deposit(
        address vaultAddress,
        uint256 vaultPositionId,
        address worker,
        address wantAddr,
        uint256 wantAmt,
        bytes memory data
    ) external returns (uint256);

    function withdraw(
        address wantAddress,
        address vaultAddress,
        uint256 vaultPositionId,
        address worker,
        bytes memory data
    ) external payable;
}