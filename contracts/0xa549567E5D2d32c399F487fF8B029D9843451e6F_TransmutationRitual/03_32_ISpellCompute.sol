// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface ISpellCompute is IERC165 {
  function compute(uint256 tokenId, bytes32 spell)
    external
    view
    returns (bytes5);

  function manaCost(bytes32 spell) external view returns (uint256);
}