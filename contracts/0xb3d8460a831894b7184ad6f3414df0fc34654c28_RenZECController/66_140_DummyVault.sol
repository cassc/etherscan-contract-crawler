// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import { yVault } from "../vendor/yearn/vaults/yVault.sol";
import { IERC20 } from "oz410/token/ERC20/IERC20.sol";
import { ERC20 } from "oz410/token/ERC20/ERC20.sol";

contract DummyVault is ERC20 {
  address public immutable want;
  address public immutable controller;

  constructor(
    address _want,
    address _controller,
    string memory _name,
    string memory _symbol
  ) ERC20(_name, _symbol) {
    want = _want;
    controller = _controller;
  }

  function estimateShares(uint256 _amount) external view returns (uint256) {
    return _amount;
  }

  function deposit(uint256 _amount) public returns (uint256) {
    IERC20(want).transferFrom(msg.sender, address(this), _amount);
    _mint(msg.sender, _amount);
    return _amount;
  }

  function withdraw(uint256 _amount) public returns (uint256) {
    _burn(msg.sender, _amount);
    IERC20(want).transfer(msg.sender, _amount);
    return _amount;
  }

  function pricePerShare() public pure returns (uint256) {
    return uint256(1e18);
  }
}