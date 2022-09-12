pragma solidity ^0.8.0;

interface IMigratable {

    event MigratedFrom(address indexed owner, address fromContract, uint256 amount);
    event MigratedTo(address indexed owner, address toContract, uint256 amount);

    function migrateFrom() external;
    function migrateTo(address owner) external;
}