// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IBusXCoin is ERC20, Ownable {
  constructor() ERC20("iBusXcoin", "iBx") {
    _mint(msg.sender, 50000000000 * 10 ** decimals());
  }
  function decimals() public view virtual override returns (uint8) {
     return 5;
   }
  function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}