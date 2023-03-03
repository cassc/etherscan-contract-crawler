// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ProxyBotConfig.sol";

interface IProxyBot {
  function getMintedBlock(uint256 _tokenId) external view returns (uint256);
  function getVaultWallet(uint256 _tokenId) external view returns (address);
  function getStatus(uint256 _tokenId) external view returns (ProxyBotConfig.Status);
  function getAppliedSpecialEdition(uint256 _tokenId) external view returns (bool, string memory);
}