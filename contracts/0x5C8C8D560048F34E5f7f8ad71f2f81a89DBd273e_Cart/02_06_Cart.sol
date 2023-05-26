//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./Address.sol";
import "./DelegateERC20.sol";

interface TokenRecipient {
  // must return ture
  function tokensReceived(
      address from,
      uint amount,
      bytes calldata exData
  ) external returns (bool);
}

contract Cart is DelegateERC20 {
  using Address for address;

  uint256 private constant preMineSupply = 100000000 * 1e18;

  constructor (address owner) DelegateERC20("CryptoArt.Ai", "CART")  {
    _mint(owner, preMineSupply);
  }

  function burn(uint amount) public {
    _burn(msg.sender, amount);
  }

  function burnFrom(address account, uint amount) public {
    _burnFrom(account, amount);
  }

  function send(address recipient, uint amount, bytes calldata exData) external returns (bool) {
    _transfer(msg.sender, recipient, amount);

    if (recipient.isContract()) {
      bool rv = TokenRecipient(recipient).tokensReceived(msg.sender, amount, exData);
      require(rv, "No TokenRecipient");
    }

    return true;
  }

}