// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import './IStaderConfig.sol';

interface IVaultProxy {
    error CallerNotOwner();
    error AlreadyInitialized();
    event UpdatedOwner(address owner);
    event UpdatedStaderConfig(address staderConfig);

    //Getters
    function vaultSettleStatus() external view returns (bool);

    function isValidatorWithdrawalVault() external view returns (bool);

    function isInitialized() external view returns (bool);

    function poolId() external view returns (uint8);

    function id() external view returns (uint256);

    function owner() external view returns (address);

    function staderConfig() external view returns (IStaderConfig);

    //Setters
    function updateOwner() external;

    function updateStaderConfig(address _staderConfig) external;
}