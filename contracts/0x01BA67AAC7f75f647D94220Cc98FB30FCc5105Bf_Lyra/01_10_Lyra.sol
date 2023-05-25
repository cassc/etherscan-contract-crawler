// SPDX-License-Identifier: ISC
pragma solidity 0.7.6;

import { ERC20Permit } from "@openzeppelin/contracts/drafts/ERC20Permit.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Lyra
 * @author Lyra
 * @dev Lyra ERC20 token with support for eip-2612
 */
contract Lyra is ERC20Permit {
  /**
   * @dev Initializes the name, symbol, decimals (default 18) and mints the supply.
   * @param name The name of the token
   * @param symbol The symbol of the token
   * @param supply The total supply to be minted to the deployer
   */
  constructor(
    string memory name,
    string memory symbol,
    uint256 supply
  ) ERC20Permit(name) ERC20(name, symbol) {
    _mint(msg.sender, supply);
  }
}