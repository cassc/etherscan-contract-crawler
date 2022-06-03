// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IDistributer.sol";

interface IDealer {
  event CardCreated(uint256[] tokenIds, bool mintable);
  event CardEnabled(uint256[3] tokenIds);
  event CardDisabled(uint256[3] tokenIds);

  function getIdsAndShares(uint256[] memory rnds) external returns (uint256[] memory ids, uint256 shares);

  function getEditionByTokenId(uint256 id) external returns (uint256);

  function getSharesOf(uint256 id) external returns (uint256 shares);
  function getSharesOf(uint256[] memory ids) external returns (uint256 shares);

  function create() external returns (uint256[] memory);
  function createNonMintable() external returns (uint256[] memory);
}