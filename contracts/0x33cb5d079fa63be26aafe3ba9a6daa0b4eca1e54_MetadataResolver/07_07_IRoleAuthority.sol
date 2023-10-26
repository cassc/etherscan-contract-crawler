// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IRoleAuthority {
  function isOperator(address _address) external view returns (bool);

  function is721Minter(address _address) external view returns (bool);

  function isMintPassSigner(address _address) external view returns (bool);

  function isPosterMinter(address _address) external view returns (bool);

  function isPosterSigner(address _address) external view returns (bool);
}