// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract veLSD is ERC20 {
  address public minter;

  constructor() ERC20("veLSD Coin", "veLSD") {
    minter = _msgSender();
  }

  /// @dev Disable normal token transfer
  function _transfer(address, address, uint256) internal pure override {
    revert Unsupported();
  }

  /// @dev Only the minter (aka LsdxTreasury) could mint veLSD tokens on user deposit
  function mint(address to, uint256 amount) public onlyMinter {
    _mint(to, amount);
  }

  /// @dev Only the minter (aka LsdxTreasury) could burn veLSD tokens on user withdraw
  function burnFrom(address account, uint256 amount) public onlyMinter {
    _burn(account, amount);
  }

  /// @dev Should transfer mintership to LsdxTreasury right after deployment
  function setMinter(address newMinter) public onlyMinter {
    require(newMinter != address(0), "New minter is the zero address");
    require(newMinter != minter, "Same minter");
    
    address oldMinter = minter;
    minter = newMinter;
    emit MintershipTransferred(oldMinter, newMinter);
  }

  modifier onlyMinter() {
    require(minter == _msgSender(), "Caller is not the minter");
    _;
  }

  error Unsupported();

  event MintershipTransferred(address indexed previousMinter, address indexed newMinter);
}