// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IMintableNFT {
  function mint(address _to, uint256 _id) external; /* onlyRole(MINTER_ROLE) */

  function bulkMint(address _to, uint256[] memory _ids) external; /* onlyRole(MINTER_ROLE) */

  function bulkMint(address _to, uint256 _fromId, uint256 _toId) external; /* onlyRole(MINTER_ROLE) */

  function changeLandToPremium(uint256 _id) external; /* onlyRole(MINTER_ROLE) */

  function bulkChangeLandToPremium(uint256[] memory _ids) external;
}