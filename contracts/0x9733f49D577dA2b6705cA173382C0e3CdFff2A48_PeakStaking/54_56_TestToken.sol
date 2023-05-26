pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

/**
 * @title An ERC20 token used for testing.
 * @author Zefram Lou (Zebang Liu)
 */
contract TestToken is ERC20Mintable, ERC20Burnable, ERC20Detailed {
  constructor(string memory name, string memory symbol, uint8 decimals)
    public
    ERC20Detailed(name, symbol, decimals)
  {}
}