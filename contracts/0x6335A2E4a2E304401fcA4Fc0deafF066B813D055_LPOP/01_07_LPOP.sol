pragma solidity ^0.6.12;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {
  ERC20Burnable
} from '@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';

contract LPOP is ERC20, ERC20Burnable, Ownable {
  constructor(string memory _name, string memory _symbol)
    public
    ERC20(_name, _symbol)
  {}

  /// @notice Creates halo token, increasing total supply.
  /// @dev Allows owner to mint HALO tokens.
  /// @param account address of the owner
  /// @param amount amount to mint
  function mint(address account, uint256 amount) external onlyOwner {
    _mint(account, amount);
  }
}