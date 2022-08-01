// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRoyaltySplitter {
  function releaseable(uint256 tokenId) external view returns(uint256);
  function releaseable(IERC20 token, uint256 tokenId) external view returns(uint256);
}