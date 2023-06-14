// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface FoundryAppraiserInterface {
  function appraise(uint256 id, string memory label)
    external
    view
    returns (uint256, IERC20);
}