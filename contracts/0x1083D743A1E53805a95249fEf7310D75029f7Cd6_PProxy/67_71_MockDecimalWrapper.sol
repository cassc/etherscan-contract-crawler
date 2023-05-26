//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract MockDecimalWrapper is ERC20 {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 public conversion;
  IERC20 public underlying;

  event Deposit(address indexed dst, uint wad);
  event Withdrawal(address indexed src, uint wad);

  constructor(string memory _name, string memory _symbol, address _underlying, uint256 _conversion) ERC20(_name, _symbol) {
    underlying = IERC20(_underlying);
    conversion = _conversion;
  }

  function deposit(uint256 _amount) external {
    underlying.safeTransferFrom(msg.sender, address(this), _amount);
    _mint(msg.sender, _amount.mul(conversion));
    emit Deposit(msg.sender, _amount);
  }

  function withdraw(uint256 _amount) external {
    _burn(msg.sender, _amount);
    underlying.safeTransfer(msg.sender, _amount.div(conversion));
    emit Withdrawal(msg.sender, _amount);
  }
}