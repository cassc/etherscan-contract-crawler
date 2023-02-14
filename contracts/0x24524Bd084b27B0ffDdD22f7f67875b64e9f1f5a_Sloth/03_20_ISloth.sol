//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC721AQueryableUpgradeable } from "erc721a-upgradeable/contracts/interfaces/IERC721AQueryableUpgradeable.sol";

interface ISloth is IERC721AQueryableUpgradeable {
  function mint(address sender, uint8 quantity) external;
  function numberMinted(address sender) external view returns (uint256);
}