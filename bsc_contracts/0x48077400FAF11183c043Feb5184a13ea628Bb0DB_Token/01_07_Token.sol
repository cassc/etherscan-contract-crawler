// SPDX-License-Identifier: MIT

//**  ERC20 TOKEN for Mainnet */

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Token is ERC20, Ownable {
  using SafeMath for uint256;

  address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  /**
   *
   * @dev mint initialSupply in constructor with symbol and name
   *
   */
  constructor(
    string memory name,
    string memory symbol,
    uint256 initialSupply
  ) ERC20(name, symbol) {
    _mint(_msgSender(), initialSupply);
  }

  /**
   *
   * @dev lock tokens by sending to DEAD address
   *
   */
  function lockTokens(uint256 amount) external onlyOwner returns (bool) {
    _transfer(_msgSender(), DEAD_ADDRESS, amount);
    return true;
  }

  /**
   * @dev Destroys `amount` tokens from the caller.
   *
   * See {ERC20-_burn}.
   */
  function burn(uint256 amount) external onlyOwner returns (bool) {
    _burn(_msgSender(), amount);
    return true;
  }
}