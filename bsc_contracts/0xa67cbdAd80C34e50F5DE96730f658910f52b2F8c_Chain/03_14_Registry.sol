//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Inheritance
import "@openzeppelin/contracts/access/Ownable.sol";

import "./extensions/Registrable.sol";
import "./interfaces/IRegistry.sol";

/// @dev contracts registry
/// protocol uses this registry to fetch current contract addresses
contract Registry is IRegistry, Ownable {
    /// name => contract address
    mapping(bytes32 => address) public registry;


    error NameNotRegistered();
    error ArraysDataDoNotMatch();

    /// @inheritdoc IRegistry
    function importAddresses(bytes32[] calldata _names, address[] calldata _destinations) external onlyOwner {
        if (_names.length != _destinations.length) revert ArraysDataDoNotMatch();

        for (uint i = 0; i < _names.length;) {
            registry[_names[i]] = _destinations[i];
            emit LogRegistered(_destinations[i], _names[i]);

            unchecked {
                i++;
            }
        }
    }

    /// @inheritdoc IRegistry
    function importContracts(address[] calldata _destinations) external onlyOwner {
        for (uint i = 0; i < _destinations.length;) {
            bytes32 name = Registrable(_destinations[i]).getName();
            registry[name] = _destinations[i];
            emit LogRegistered(_destinations[i], name);

            unchecked {
                i++;
            }
        }
    }

    /// @inheritdoc IRegistry
    function atomicUpdate(address _newContract) external onlyOwner {
        Registrable(_newContract).register();

        bytes32 name = Registrable(_newContract).getName();
        address oldContract = registry[name];
        registry[name] = _newContract;

        Registrable(oldContract).unregister();

        emit LogRegistered(_newContract, name);
    }

    /// @inheritdoc IRegistry
    function requireAndGetAddress(bytes32 name) external view returns (address) {
        address _foundAddress = registry[name];
        if (_foundAddress == address(0)) revert NameNotRegistered();

        return _foundAddress;
    }

    /// @inheritdoc IRegistry
    function getAddress(bytes32 _bytes) external view returns (address) {
        return registry[_bytes];
    }

    /// @inheritdoc IRegistry
    function getAddressByString(string memory _name) public view returns (address) {
        return registry[stringToBytes32(_name)];
    }

    /// @inheritdoc IRegistry
    function stringToBytes32(string memory _string) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(_string);

        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := mload(add(_string, 32))
        }
    }
}