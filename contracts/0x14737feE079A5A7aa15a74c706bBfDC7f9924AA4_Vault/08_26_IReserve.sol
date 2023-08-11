// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IReserve {
    function addVault(address vault) external;
    function deposit_for(address user, uint256 amount) external;
    function withdraw_from_vault(address user, uint256 debtFees, uint256 debtTreasuryFees) external;
}