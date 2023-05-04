// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SHIELD is ERC20, ERC20Burnable, Ownable {
  // ,dpomDPImiKMDLkmdpOJDMPOmdkDKSMDPdjmPOMD steve aoki protection spell OSJMojsoJSDoimdlDMlijdpiDDPpimdlkMDLkmdlim

  uint256 private constant INITIAL_SUPPLY = 69420000000 * 10 ** 18;

  constructor() ERC20("SHIELD", "SHIELD") {
    _mint(msg.sender, INITIAL_SUPPLY);
  }

  function distributeTokens(address distributionWallet) external onlyOwner {
    uint256 supply = balanceOf(msg.sender);
    require(supply == INITIAL_SUPPLY, "Tokens already distributed");

    _transfer(msg.sender, distributionWallet, supply);
  }
}