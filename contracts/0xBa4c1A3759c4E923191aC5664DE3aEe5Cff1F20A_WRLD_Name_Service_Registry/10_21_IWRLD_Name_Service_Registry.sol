// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IWRLD_Name_Service_Registry is IERC165 {
  function register(address _registerer, string[] calldata _names, uint16[] memory _registrationYears) external;
  function extendRegistration(string[] calldata _names, uint16[] calldata _additionalYears) external;

  function getNameTokenId(string calldata _name) external view returns (uint256);

  event NameRegistered(string indexed idxName, string name, uint16 registrationYears);
  event NameRegistrationExtended(string indexed idxName, string name, uint16 additionalYears);
  event NameControllerUpdated(string indexed idxName, string name, address controller);

  event ResolverStringRecordUpdated(string indexed idxName, string name, string record, string value, string typeOf, uint256 ttl, address resolver);
  event ResolverAddressRecordUpdated(string indexed idxName, string name, string record, address value, uint256 ttl, address resolver);
  event ResolverUintRecordUpdated(string indexed idxName, string name, string record, uint256 value, uint256 ttl, address resolver);
  event ResolverIntRecordUpdated(string indexed idxName, string name, string record, int256 value, uint256 ttl, address resolver);

  event ResolverStringEntryUpdated(address indexed setter, string indexed idxName, string indexed idxEntry, string name, string entry, string value);
  event ResolverAddressEntryUpdated(address indexed setter, string indexed idxName, string indexed idxEntry, string name, string entry, address value);
  event ResolverUintEntryUpdated(address indexed setter, string indexed idxName, string indexed idxEntry, string name, string entry, uint256 value);
  event ResolverIntEntryUpdated(address indexed setter, string indexed idxName, string indexed idxEntry, string name, string entry, int256 value);
}