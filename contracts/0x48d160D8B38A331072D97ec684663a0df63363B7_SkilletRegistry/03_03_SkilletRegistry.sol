//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SkilletRegistry is Ownable {

  address public conduitAddress;
  mapping(bytes32 => address) public implementations;

  /**
   * Set the conduit address and store for reference
   * @param _conduitAddress address of the conduit
   */
  function setConduitAddress(address _conduitAddress) 
    public 
    onlyOwner 
  {
    require(_conduitAddress != address(0), "Invalid conduit address");
    conduitAddress = _conduitAddress;
  }

  /**
   * Add an implementation to mapping by unique key
   * key should be calculated as keccak256(IDENTIFIER)
   * @param _key bytes32 keccak256 of identifier for implementation
   * @param _address address of the implementation
   */
  function addImplementation(bytes32 _key, address _address)
    public
    onlyOwner
  {
    require(_address != address(0), "Invalid implementation address");
    implementations[_key] = _address;
  }
}