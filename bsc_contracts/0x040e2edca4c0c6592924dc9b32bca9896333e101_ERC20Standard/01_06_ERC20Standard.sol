// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Standard is ERC20, Ownable {
  uint8 private _decimal;

  constructor(
    address _owner,
    string memory name,
    string memory symbol,
    uint8 decimal,
    uint256 initialSupply
  ) ERC20(name, symbol) {
    require(_owner != address(0), "ERC20: address is not zero");
    transferOwnership(_owner);

    _decimal = decimal;
    _mint(_owner, initialSupply);
  }

  function decimals() public view virtual override returns (uint8) {
    return _decimal;
  }
}