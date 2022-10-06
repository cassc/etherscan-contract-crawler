// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

interface IAddrMapper {
  /**
   * @dev Log a change in address mapping
   */
  event MappingChanged(address[] keyAddress, address mappedAddress);

  function getAddressMapping(address keyAddr) external view returns (address returnedAddr);

  function getAddressNestedMapping(address keyAddr1, address keyAddr2)
    external
    view
    returns (address returnedAddr);

  function setMapping(address keyAddr, address returnedAddr) external;

  function setNestedMapping(address keyAddr1, address keyAddr2, address returnedAddr) external;
}