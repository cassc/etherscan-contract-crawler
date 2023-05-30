// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IAddrMapper} from "../interfaces/IAddrMapper.sol";

contract MockAddrMapper is IAddrMapper, Ownable {
  // provider name => key address => returned address
  // (e.g. Compound_V2 => public erc20 => protocol Token)
  mapping(string => mapping(address => address)) private _addrMapping;
  // provider name => key1 address => key2 address => returned address
  // (e.g. Compound_V3 => collateral erc20 => borrow erc20 => Protocol market)
  mapping(string => mapping(address => mapping(address => address))) private _addrNestedMapping;

  string[] private _providerNames;

  mapping(string => bool) private _isProviderNameAdded;

  function getProviders() public view returns (string[] memory) {
    return _providerNames;
  }

  function getAddressMapping(string memory providerName, address inputAddr)
    external
    view
    override
    returns (address)
  {
    return _addrMapping[providerName][inputAddr];
  }

  function getAddressNestedMapping(
    string memory providerName,
    address inputAddr1,
    address inputAddr2
  )
    external
    view
    override
    returns (address)
  {
    return _addrNestedMapping[providerName][inputAddr1][inputAddr2];
  }

  /**
   * @dev Adds an address mapping.
   * Requirements:
   * - ProviderName should be formatted: Name_Version or Name_Version_Asset
   */
  function setMapping(string memory providerName, address keyAddr, address returnedAddr)
    public
    override
  {
    if (!_isProviderNameAdded[providerName]) {
      _isProviderNameAdded[providerName] = true;
    }
    _addrMapping[providerName][keyAddr] = returnedAddr;
    address[] memory inputAddrs = new address[](1);
    inputAddrs[0] = keyAddr;
    emit MappingChanged(inputAddrs, returnedAddr);
  }

  /**
   * @dev Adds a nested address mapping.
   * Requirements:
   * - ProviderName should be formatted: Name_Version or Name_Version_Asset
   */
  function setNestedMapping(
    string memory providerName,
    address keyAddr1,
    address keyAddr2,
    address returnedAddr
  )
    public
    override
  {
    if (!_isProviderNameAdded[providerName]) {
      _isProviderNameAdded[providerName] = true;
    }
    _addrNestedMapping[providerName][keyAddr1][keyAddr2] = returnedAddr;
    address[] memory inputAddrs = new address[](2);
    inputAddrs[0] = keyAddr1;
    inputAddrs[1] = keyAddr2;
    emit MappingChanged(inputAddrs, returnedAddr);
  }

  function prepareToRedeploythisAddress() public onlyOwner {
    selfdestruct(payable(owner()));
  }
}