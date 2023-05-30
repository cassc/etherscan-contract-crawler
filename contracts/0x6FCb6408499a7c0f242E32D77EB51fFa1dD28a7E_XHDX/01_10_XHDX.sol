pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";


contract XHDX is ERC20Detailed, ERC20Pausable {

  constructor () public ERC20Detailed("xHDX", "xHDX", 12) {
    _mint(msg.sender, 500000000 * (10 ** uint256(decimals())));
  }
}