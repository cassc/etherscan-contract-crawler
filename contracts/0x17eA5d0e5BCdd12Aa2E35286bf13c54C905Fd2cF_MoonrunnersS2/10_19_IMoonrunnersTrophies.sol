//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IMoonrunnersTrophies is IERC1155 {
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

}