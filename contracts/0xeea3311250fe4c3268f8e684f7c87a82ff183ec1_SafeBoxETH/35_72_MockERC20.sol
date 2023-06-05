pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC20/ERC20.sol';

contract MockERC20 is ERC20 {
  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) public ERC20(name, symbol) {
    _setupDecimals(decimals);
  }

  function mint(address to, uint amount) public {
    _mint(to, amount);
  }
}