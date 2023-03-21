// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Beacon with upgradeable implementation
contract UpgradeableBeacon is IBeacon, Ownable {
    using Address for address;

    address private implementation_;

    /// @notice Emitted when the implementation returned by the beacon is changed.
    event Upgraded(address indexed implementation);

    /// @param _implementation Address of the logic contract
    constructor(address _implementation, address _owner) {
        _setImplementation(_implementation);

        transferOwnership(_owner);
    }

    /// @return current implementation address
    function implementation() override external view returns (address) {
        return implementation_;
    }

    /// @notice Allows an admin to change the implementation / logic address
    /// @param _implementation Address of the new implementation
    function updateImplementation(address _implementation) external onlyOwner {
        _setImplementation(_implementation);
    }

    /// @dev internal method for setting the implementation making sure the supplied address is a contract
    function _setImplementation(address _implementation) private {
        require(_implementation != address(0), "Invalid implementation");
        require(_implementation.isContract(), "_setImplementation: Implementation address does not have a contract");
        implementation_ = _implementation;
        emit Upgraded(implementation_);
    }
}

// Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/0db76e98f90550f1ebbb3dea71c7d12d5c533b5c/contracts/proxy/UpgradeableBeacon.sol