//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IMoonrunnersLoot is IERC1155 {
  function totalSupply(uint256 id) external returns (uint256);

  function mint(
    address to,
    uint256 id,
    uint256 amount
  ) external;

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts
  ) external;

  function controlledBurn(
    address from,
    uint256 id,
    uint256 amount
  ) external;
}