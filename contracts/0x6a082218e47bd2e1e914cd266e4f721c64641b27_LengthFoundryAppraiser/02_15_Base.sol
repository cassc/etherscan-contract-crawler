// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interface.sol";

contract BaseFoundryAppraiser is FoundryAppraiserInterface {
  function appraise(uint256, string memory)
    external
    view
    virtual
    override
    returns (uint256, IERC20)
  {
    uint256 amount = 0;
    IERC20 token = IERC20(address(0));
    return (amount, token);
  }
}