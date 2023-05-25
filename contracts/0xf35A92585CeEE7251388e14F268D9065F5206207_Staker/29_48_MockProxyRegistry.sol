// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
  @title An OpenSea mock proxy contract which we use to test whitelisting.
  @author OpenSea
*/
contract MockProxyRegistry is Ownable {
  using SafeMath for uint256;

  /// A mapping of testing proxies.
  mapping(address => address) public proxies;

  /**
    Allow the registry owner to set a proxy on behalf of an address.

    @param _address The address that the proxy will act on behalf of.
    @param _proxyForAddress The proxy that will act on behalf of the address.
  */
  function setProxy(address _address, address _proxyForAddress) external onlyOwner {
    proxies[_address] = _proxyForAddress;
  }
}