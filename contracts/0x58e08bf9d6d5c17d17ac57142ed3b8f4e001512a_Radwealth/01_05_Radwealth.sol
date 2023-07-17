// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./ERC20.sol";

contract Radwealth is ERC20 {
  uint256 public initialSupply;
  uint256 public rate = 685;
  address public ownerWallet;

  IERC20 public token;

  constructor(address _ownerWallet) ERC20("Radwealth", "Radwealth") {
    initialSupply = 400000 ether;
    ownerWallet = _ownerWallet;
    token = IERC20(address(this));

    // Initially assign all tokens to the contract's creator.
    _mint(ownerWallet, initialSupply);
  }

  function exchange() external payable {
    uint256 amount = msg.value;
    uint256 total = amount * rate / 1000;
    payable(ownerWallet).transfer(amount);
    token.transferFrom(ownerWallet, msg.sender, total);
  }

  function setRate(uint256 _rate) external {
    require(msg.sender == ownerWallet, "Not authorized");
    rate = _rate;
  }
}