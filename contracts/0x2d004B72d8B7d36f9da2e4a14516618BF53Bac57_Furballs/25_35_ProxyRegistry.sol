// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

// Contract doesn't really provide anything...
contract OwnableDelegateProxy {}

// Required format for OpenSea of proxy delegate store
// https://github.com/ProjectOpenSea/opensea-creatures/blob/f7257a043e82fae8251eec2bdde37a44fee474c4/contracts/ERC721Tradable.sol
// https://etherscan.io/address/0xa5409ec958c83c3f309868babaca7c86dcb077c1#code
contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}