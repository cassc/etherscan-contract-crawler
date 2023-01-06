// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IFarmingLPTokenFactory {
    error InvalidAddress();
    error MigratorSet();
    error TokenCreated();

    event UpdateVault(address indexed vault);
    event UpdateMigrator(address indexed migrator);
    event CreateFarmingLPToken(uint256 indexed pid, address indexed token);

    function router() external view returns (address);

    function masterChef() external view returns (address);

    function yieldVault() external view returns (address);

    function migrator() external view returns (address);

    function getFarmingLPToken(uint256 pid) external view returns (address);

    function predictFarmingLPTokenAddress(uint256 pid) external view returns (address token);

    function updateYieldVault(address vault) external;

    function updateMigrator(address vault) external;

    function createFarmingLPToken(uint256 pid) external returns (address token);
}