// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

// TODO ownership role of mappers to be defined at a higher level.
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IAddrMapper} from "../interfaces/IAddrMapper.sol";

/**
 * @dev Contract that stores and returns addresses mappings
 * Required for getting contract addresses for some providers and flashloan providers
 */
contract AddrMapper is IAddrMapper, Ownable {
  string public mapperName;
  // key address => returned address
  // (e.g. public erc20 => protocol Token)
  mapping(address => address) private _addressMapping;
  // key1 address, key2 address => returned address
  // (e.g. collateral erc20 => borrow erc20 => Protocol market)
  mapping(address => mapping(address => address)) private _addressNestedMapping;

  constructor(string memory _mapperName) {
    mapperName = _mapperName;
  }

  function getAddressMapping(address inputAddr) external view override returns (address) {
    return _addressMapping[inputAddr];
  }

  function getAddressNestedMapping(address inputAddr1, address inputAddr2)
    external
    view
    override
    returns (address)
  {
    return _addressNestedMapping[inputAddr1][inputAddr2];
  }

  /**
   * @dev Adds an address mapping.
   */
  function setMapping(address keyAddr, address returnedAddr) public override onlyOwner {
    _addressMapping[keyAddr] = returnedAddr;
    address[] memory inputAddrs = new address[](1);
    inputAddrs[0] = keyAddr;
    emit MappingChanged(inputAddrs, returnedAddr);
  }

  /**
   * @dev Adds a nested address mapping.
   */
  function setNestedMapping(address keyAddr1, address keyAddr2, address returnedAddr)
    public
    override
    onlyOwner
  {
    _addressNestedMapping[keyAddr1][keyAddr2] = returnedAddr;
    address[] memory inputAddrs = new address[](2);
    inputAddrs[0] = keyAddr1;
    inputAddrs[1] = keyAddr2;
    emit MappingChanged(inputAddrs, returnedAddr);
  }
}