// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Airdrop is Ownable {
  IERC20 token;
     
  event TransferredToken(address indexed to, uint256 value);
  event FailedTransfer(address indexed to, uint256 value);

  modifier whenAirdropIsActive() {
    assert(tokensAvailable() > 0);
    _;
  }

  constructor(address _tokenAddr) {
      token = IERC20(_tokenAddr);
  }

  function getTokenAddress() public view returns (address) {
    return address(token);
  }

  function setTokenAddress(address _tokenAddr) public onlyOwner {
    token = IERC20(_tokenAddr);
  }

  // Below function can be used when you want to send every recipeint with different number of tokens
  function sendTokens(address[] calldata dests, uint256[] calldata values) whenAirdropIsActive onlyOwner external {
    uint256 i = 0;

    while (i < dests.length) { 
        sendInternally(dests[i], values[i]);
        i++;
    }
  }

  // This function can be used when you want to send same number of tokens to all the recipients
  function sendTokensSingleValue(address[] calldata dests, uint256 value) whenAirdropIsActive onlyOwner external {
    uint256 i = 0;

    while (i < dests.length) {
        sendInternally(dests[i], value);
        i++;
    }
  }  

  function sendInternally(address recipient, uint256 tokensToSend) internal {
    if(recipient == address(0)) return;

    if(tokensAvailable() >= tokensToSend) {
      token.transfer(recipient, tokensToSend);
      emit TransferredToken(recipient, tokensToSend);
    } else {
      emit FailedTransfer(recipient, tokensToSend);
    }
  }   

  function tokensAvailable() public view returns (uint256) {
    return token.balanceOf(address(this));
  }

  function collectTokens() public onlyOwner {
    uint256 balance = tokensAvailable();
    require (balance > 0);
    token.transfer(owner(), balance);
  }
}