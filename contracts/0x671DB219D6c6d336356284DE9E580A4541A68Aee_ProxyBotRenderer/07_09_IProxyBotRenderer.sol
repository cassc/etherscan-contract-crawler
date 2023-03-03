// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ProxyBotConfig.sol";

// The ProxyBot Renderer interface is used to render the ProxyBot, swappable as future requirements dictate.
interface IProxyBotRenderer {
  // Override the tokenURI method to return the URI of the ProxyBot image.
  function tokenURI(uint256 _tokenId) external view returns (string memory);
}