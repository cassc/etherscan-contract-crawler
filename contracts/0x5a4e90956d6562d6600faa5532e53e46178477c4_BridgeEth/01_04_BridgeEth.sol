pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BridgeEth{

  using SafeERC20 for IERC20;

  address public admin;
  IERC20 public token;
  uint public nonce;

  enum Step { Burn }
  event Transfer(
    address from,
    address to,
    uint amount,
    uint date,
    uint nonce,
    Step indexed step
  );

  constructor(address _token) {
    admin = msg.sender;
    token = IERC20(_token);
  }

  function burn(address to, uint amount) external {
    token.safeTransferFrom(msg.sender, address(this), amount);
    emit Transfer(
      msg.sender,
      to,
      amount,
      block.timestamp,
      nonce,
      Step.Burn
    );
    nonce++;
  }

}