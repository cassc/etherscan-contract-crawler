//SPDX-License-Identifier: MIT
pragma solidity 0.6.8;

// Inheritance
import "@openzeppelin/contracts/access/Ownable.sol";

import "./extensions/Registrable.sol";

contract Registry is Ownable {
  mapping(bytes32 => address) public registry;

  // ========== EVENTS ========== //

  event LogRegistered(address indexed destination, bytes32 name);

  // ========== MUTATIVE FUNCTIONS ========== //

  function importAddresses(bytes32[] calldata _names, address[] calldata _destinations) external onlyOwner {
    require(_names.length == _destinations.length, "Input lengths must match");

    for (uint i = 0; i < _names.length; i++) {
      registry[_names[i]] = _destinations[i];
      emit LogRegistered(_destinations[i], _names[i]);
    }
  }

  function importContracts(address[] calldata _destinations) external onlyOwner {
    for (uint i = 0; i < _destinations.length; i++) {
      bytes32 name = Registrable(_destinations[i]).getName();
      registry[name] = _destinations[i];
      emit LogRegistered(_destinations[i], name);
    }
  }

  function atomicUpdate(address _newContract) external onlyOwner {
    Registrable(_newContract).register();

    bytes32 name = Registrable(_newContract).getName();
    address oldContract = registry[name];
    registry[name] = _newContract;

    Registrable(oldContract).unregister();

    emit LogRegistered(_newContract, name);
  }

  // ========== VIEWS ========== //

  function requireAndGetAddress(bytes32 name) external view returns (address) {
    address _foundAddress = registry[name];
    require(_foundAddress != address(0), string(abi.encodePacked("Name not registered: ", name)));
    return _foundAddress;
  }

  function getAddress(bytes32 _bytes) external view returns (address) {
    return registry[_bytes];
  }

  function getAddressByString(string memory _name) public view returns (address) {
    return registry[stringToBytes32(_name)];
  }

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