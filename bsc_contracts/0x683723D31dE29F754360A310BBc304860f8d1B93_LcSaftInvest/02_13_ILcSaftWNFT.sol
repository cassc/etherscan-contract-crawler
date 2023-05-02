// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ILcSaftWNFT is IERC1155 {
  function mint(address account, uint256 amount, string memory uri) payable external returns (uint256);
}