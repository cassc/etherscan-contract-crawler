// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BLOW is ERC20, ERC20Burnable, Ownable {
  // $BLOW is a memecoin.
  // People blow, things blow, do you blow?

  uint256 private constant INITIAL_SUPPLY = 69420000000 * 10 ** 18;

  constructor() ERC20("BLOW", "BLOW") {
    _mint(msg.sender, INITIAL_SUPPLY);
  }

  function distributeTokens(address distributionWallet) external onlyOwner {
    uint256 supply = balanceOf(msg.sender);
    require(supply == INITIAL_SUPPLY, "Tokens already distributed");

    _transfer(msg.sender, distributionWallet, supply);
  }
}