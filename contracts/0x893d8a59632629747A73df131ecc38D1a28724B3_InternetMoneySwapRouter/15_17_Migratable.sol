// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Migratable is Ownable {
    address[] public migrationAddresses;
    event UpdateMigrationAddresses(address indexed executor, address[] addresses);
    function setMigrationAddress(address[] calldata _migrationAddresses) external onlyOwner {
        migrationAddresses = _migrationAddresses;
        emit UpdateMigrationAddresses(_msgSender(), _migrationAddresses);
    }
}