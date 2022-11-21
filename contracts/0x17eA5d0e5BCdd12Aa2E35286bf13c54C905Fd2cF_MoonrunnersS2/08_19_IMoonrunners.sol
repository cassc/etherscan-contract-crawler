//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import {IERC721A} from "erc721a/contracts/IERC721A.sol";
import {IERC721AQueryable} from "erc721a/contracts/extensions/IERC721AQueryable.sol";

interface IMoonrunners is IERC721A, IERC721AQueryable {
  function burn(uint256 tokenId) external;
}