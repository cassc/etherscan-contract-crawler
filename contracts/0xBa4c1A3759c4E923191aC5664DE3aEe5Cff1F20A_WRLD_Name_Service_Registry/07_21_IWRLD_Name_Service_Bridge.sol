// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IWRLD_Name_Service_Bridge is IERC165 {
  function transfer(address from, address to, uint256 tokenId, string memory name) external;
  function extendRegistration(string[] calldata _names, uint16[] calldata _additionalYears) external;
  function setController(string calldata _name, address _controller) external;

  function setStringRecord(string calldata _name, string calldata _record, string calldata _value, string calldata _typeOf, uint256 _ttl) external;
  function setAddressRecord(string memory _name, string memory _record, address _value, uint256 _ttl) external;
  function setUintRecord(string calldata _name, string calldata _record, uint256 _value, uint256 _ttl) external;
  function setIntRecord(string calldata _name, string calldata _record, int256 _value, uint256 _ttl) external;

  function setStringEntry(address _setter, string calldata _name, string calldata _entry, string calldata _value) external;
  function setAddressEntry(address _setter, string calldata _name, string calldata _entry, address _value) external;
  function setUintEntry(address _setter, string calldata _name, string calldata _entry, uint256 _value) external;
  function setIntEntry(address _setter, string calldata _name, string calldata _entry, int256 _value) external;

  function migrate(string calldata _name, uint256 _networkFlags) external;
}