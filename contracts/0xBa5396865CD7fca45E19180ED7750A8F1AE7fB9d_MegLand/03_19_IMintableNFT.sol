// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IMintableNFT {
  function mint(address _to, uint256 _id) external; /* onlyRole(MINTER_ROLE) */

  function mintTo(address _to, uint256 _count) external; /* onlyRole(MINTER_ROLE) */

  function bulkMint(address _to, uint256[] memory _ids) external; /* onlyRole(MINTER_ROLE) */

  function bulkMint(address _to, uint256 _fromId, uint256 _toId) external; /* onlyRole(MINTER_ROLE) */

  function changeLandToPremium(uint256 _id) external; /* onlyRole(MINTER_ROLE) */

  function bulkChangeLandToPremium(uint256[] memory _ids) external;

  function changeLandToStandard(uint256 _id) external; /* onlyRole(PREMIUM_ROLE);*/

  function bulkChangeLandToStandard(uint256[] memory _ids) external; /*onlyRole(PREMIUM_ROLE)*/

  function changeLandToGenesis(uint256 _id) external; /*onlyRole(PREMIUM_ROLE)*/

  function bulkChangeLandToGenesis(uint256[] memory _ids) external; /*onlyRole(PREMIUM_ROLE)*/
}