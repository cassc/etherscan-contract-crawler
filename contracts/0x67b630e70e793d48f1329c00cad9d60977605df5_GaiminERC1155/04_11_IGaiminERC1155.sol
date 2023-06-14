// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IGaiminERC1155 is IERC1155 {
  function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
  
  function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

  function burn(address account, uint256 id, uint256 value) external;


}