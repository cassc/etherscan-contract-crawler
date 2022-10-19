// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

interface IAddrMapper {
  /**
   * @dev Log a change in address mapping
   */
  event MappingChanged(address[] keyAddress, address mappedAddress);

  function getAddressMapping(string memory providerName, address keyAddr)
    external
    view
    returns (address returnedAddr);

  function getAddressNestedMapping(string memory providerName, address keyAddr1, address keyAddr2)
    external
    view
    returns (address returnedAddr);

  function setMapping(string memory providerName, address keyAddr, address returnedAddr) external;

  function setNestedMapping(
    string memory providerName,
    address keyAddr1,
    address keyAddr2,
    address returnedAddr
  )
    external;
}