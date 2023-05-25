// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

/**
 * BaseERC20 is a basic erc20, burnable, token that is used for accounting purposes
 */
contract BaseERC20 is ERC20, ERC20Burnable, Multicall {
  constructor(uint256 supply, string memory name_, string memory symbol_) ERC20(name_, symbol_) {
    _mint(msg.sender, supply);
  }
}