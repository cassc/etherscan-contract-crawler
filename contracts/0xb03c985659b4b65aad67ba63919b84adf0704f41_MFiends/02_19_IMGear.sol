// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";

interface IMGear is IERC721Enumerable {
  function tokenIdToMGear(uint256 mgearId) external view returns (uint256 mgearData);

  function renderData(uint256 mgear) external view returns (string memory svg);
}