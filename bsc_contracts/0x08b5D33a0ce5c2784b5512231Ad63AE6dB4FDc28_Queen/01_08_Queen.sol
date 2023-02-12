// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Queen is Context, AccessControl, ERC20{

  using SafeMath for uint256;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  uint256 private maxSupply = 10000000000 * 10 ** 18;

  //REAL ADDRESS
  address public constant TEAM_ADDRESS = 0x01FFb8761C7c409B39db86E60136f6edDC26E42e;

  constructor(
    string memory name,
    string memory symbol
  ) ERC20(name,symbol) {

    //ROLE DEFINITION
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());

    mint(TEAM_ADDRESS, maxSupply);
  }

  function mint(address to, uint256 amount) public virtual {
    require(
      hasRole(MINTER_ROLE,_msgSender()),
      "THIS USER DOES NOT HAVE MINTER_ROLE");

    require(
      totalSupply().add(amount) <= maxSupply,
      "MAXSUPPLY EXCEEDED");

    _mint(to, amount);
  }

  function burn(uint256 amount) public virtual {
    _burn(_msgSender(), amount);
  }

}