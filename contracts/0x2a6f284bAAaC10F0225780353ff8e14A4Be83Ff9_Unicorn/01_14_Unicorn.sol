// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721.sol";

/**
 * @title MasterchefMasatoshi
 * NFT + DAO = NEW META
 * Vitalik, remove contract size limit pls
 */
contract Unicorn is ERC721, Ownable {
  using ECDSA for bytes32;

  uint256 public maxPossibleSupply;

  bool public paused;

  event Received(address, uint256);

  event Tweet(address from, string tweet);

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  constructor(
      string memory _name,
      string memory _symbol,
      uint256 _maxPossibleSupply
  ) ERC721(_name, _symbol, 1) {
    maxPossibleSupply = _maxPossibleSupply;
  }

  function preMint(uint amount) public onlyOwner {
    require(totalSupply() + amount <= maxPossibleSupply, "m");  
    _safeMint(msg.sender, amount);
  }

  function flipPaused() external onlyOwner {
    paused = !paused;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _setBaseURI(baseURI);
  }

  function tweet(string memory _tweet) public {
    require(balanceOf(msg.sender) == 1);
    emit Tweet(
      msg.sender,
      _tweet
    );
  }

  function withdraw() external onlyOwner() {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawTokens(address tokenAddress) external onlyOwner() {
    IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
  }
}

// The High Table