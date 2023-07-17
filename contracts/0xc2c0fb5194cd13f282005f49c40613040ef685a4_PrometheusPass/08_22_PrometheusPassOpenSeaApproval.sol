//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";



abstract contract OwnableDelegateProxy {}

abstract contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract PrometheusPassOpenSeaApproval is ERC721 {

  address private _proxyRegistryAddress;
  constructor(
    address proxyRegistryAddress
  ) {
    _proxyRegistryAddress = proxyRegistryAddress;
  }
  
  /**
    * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    */
  function isApprovedForAll(address owner, address operator)
      override virtual
      public view
      returns (bool)
  {
      // Whitelist OpenSea proxy contract for easy trading.
      ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
      if (address(proxyRegistry.proxies(owner)) == operator) {
          return true;
      }

      return super.isApprovedForAll(owner, operator);
  }

}