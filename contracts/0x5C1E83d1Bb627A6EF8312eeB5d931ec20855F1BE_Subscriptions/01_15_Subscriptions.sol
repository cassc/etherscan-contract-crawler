//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Subscriptions is ERC721Enumerable {
  uint256 constant public fee = 10e18;

  ERC20 immutable public dai;
  address immutable public owner;

  uint256 public nextToken = 1;
  mapping(uint256 => uint256) public subscriptions;

  event Subscribe(address indexed user);
  event Sweep(address indexed owner, uint256 balance);

  constructor(address _dai) ERC721("Dexcalidraw - Pendragon Plan - One Year Subscription", "Pendragon-1YR") {
    dai = ERC20(_dai);
    owner = msg.sender;
  }

  function subscribe() public {
    dai.transferFrom(msg.sender, address(this), fee);
    subscriptions[nextToken] = block.timestamp;
    _safeMint(msg.sender, nextToken);
    nextToken++;
    emit Subscribe(msg.sender);
  }

  function expired(uint256 token) public view returns (bool) {
    uint256 elapsed = block.timestamp - subscriptions[token];
    return elapsed > (365 days);
  }

  function sweep() public {
    require(msg.sender == owner, "!owner");
    uint256 balance = dai.balanceOf(address(this));
    dai.transferFrom(address(this), msg.sender, balance);
    emit Sweep(msg.sender, balance);
  }
}