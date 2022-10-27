// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./IBreedCert.sol";

interface IBreedManager is IBreedCert {
  function getTokenCert(uint256 _tokenId) external view returns(C memory);
}