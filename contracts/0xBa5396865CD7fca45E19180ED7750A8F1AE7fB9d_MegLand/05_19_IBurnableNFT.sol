// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IBurnableNFT {
  function burn(uint256 _id) external; /* onlyRole(BURNER_ROLE) || NFT owner */
}