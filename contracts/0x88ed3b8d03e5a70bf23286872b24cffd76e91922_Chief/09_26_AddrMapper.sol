// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title AddrMapper
 *
 * @author Fujidao Labs
 *
 * @notice Contract that stores and returns addresses mappings
 * Required for getting contract addresses for some providers and flashloan providers.
 */

import {SystemAccessControl} from "../access/SystemAccessControl.sol";
import {IAddrMapper} from "../interfaces/IAddrMapper.sol";

contract AddrMapper is IAddrMapper, SystemAccessControl {
  // provider name => key address => returned address
  // (e.g. Compound_V2 => public erc20 => protocol Token)
  mapping(string => mapping(address => address)) private _addrMapping;
  // provider name => key1 address => key2 address => returned address
  // (e.g. Compound_V3 => collateral erc20 => borrow erc20 => Protocol market)
  mapping(string => mapping(address => mapping(address => address))) private _addrNestedMapping;

  string[] private _providerNames;

  mapping(string => bool) private _isProviderNameAdded;

  constructor(address chief) SystemAccessControl(chief) {}

  /**
   * @notice Returns a list of all the providers who have a mapping.
   */
  function getProviders() public view returns (string[] memory) {
    return _providerNames;
  }

  /// @inheritdoc IAddrMapper
  function getAddressMapping(
    string memory providerName,
    address inputAddr
  )
    external
    view
    override
    returns (address)
  {
    return _addrMapping[providerName][inputAddr];
  }

  /// @inheritdoc IAddrMapper
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

  /// @inheritdoc IAddrMapper
  function setMapping(
    string memory providerName,
    address keyAddr,
    address returnedAddr
  )
    public
    override
    onlyTimelock
  {
    if (!_isProviderNameAdded[providerName]) {
      _isProviderNameAdded[providerName] = true;
      _providerNames.push(providerName);
    }
    _addrMapping[providerName][keyAddr] = returnedAddr;
    address[] memory inputAddrs = new address[](1);
    inputAddrs[0] = keyAddr;
    emit MappingChanged(inputAddrs, returnedAddr);
  }

  /// @inheritdoc IAddrMapper
  function setNestedMapping(
    string memory providerName,
    address keyAddr1,
    address keyAddr2,
    address returnedAddr
  )
    public
    override
    onlyTimelock
  {
    if (!_isProviderNameAdded[providerName]) {
      _isProviderNameAdded[providerName] = true;
      _providerNames.push(providerName);
    }
    _addrNestedMapping[providerName][keyAddr1][keyAddr2] = returnedAddr;
    address[] memory inputAddrs = new address[](2);
    inputAddrs[0] = keyAddr1;
    inputAddrs[1] = keyAddr2;
    emit MappingChanged(inputAddrs, returnedAddr);
  }
}