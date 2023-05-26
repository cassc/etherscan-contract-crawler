// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/utils/Address.sol";
import "./Proxy.sol";
import "./UpgradeabilityStorage.sol";

/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy, UpgradeabilityStorage {
    /**
     * @dev This event will be emitted every time the implementation gets upgraded
     * @param version representing the version name of the upgraded implementation
     * @param implementation representing the address of the upgraded implementation
     */
    event Upgraded(uint256 version, address indexed implementation);

    /**
     * @dev Tells the address of the current implementation
     * @return address of the current implementation
     */
    function implementation() public view override(Proxy, UpgradeabilityStorage) returns (address) {
        return UpgradeabilityStorage.implementation();
    }

    /**
     * @dev Upgrades the implementation address
     * @param newVersion representing the version name of the new implementation to be set
     * @param newImplementation representing the address of the new implementation to be set
     */
    function _upgradeTo(uint256 newVersion, address newImplementation) internal {
        require(_implementation != newImplementation);

        // This additional check verifies that provided implementation is at least a contract
        require(Address.isContract(newImplementation));

        // This additional check guarantees that new version will be at least greater than the previous one,
        // so it is impossible to reuse old versions, or use the last version twice
        require(newVersion > _version);

        _version = newVersion;
        _implementation = newImplementation;
        emit Upgraded(newVersion, newImplementation);
    }
}