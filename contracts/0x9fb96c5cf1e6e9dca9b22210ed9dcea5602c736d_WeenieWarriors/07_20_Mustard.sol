// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IGlizzyGang {
  function balanceOf(address owner) external view returns (uint256);
}

contract Mustard is ERC20, Ownable, ReentrancyGuard {
  IGlizzyGang public GlizzyGang;

  uint256 public BASE_RATE = 5 ether;
  uint256 public START;

  mapping(address => uint256) public rewards;
  mapping(address => uint256) public lastUpdate;
  mapping(address => bool) public allowed;

  constructor(address glizzyGang) ERC20("Mustard", "MUSTARD") {
    GlizzyGang = IGlizzyGang(glizzyGang);
    allowed[glizzyGang] = true;
  }

  modifier onlyAllowed() {
    require(allowed[msg.sender], "Caller not allowed");
    _;
  }

  function start() public onlyOwner {
    require(START == 0, "Already started");

    START = block.timestamp;
  }

  function setAllowed(address account, bool isAllowed) public onlyOwner {
    allowed[account] = isAllowed;
  }


  function migrate(address to, uint256 amount) external onlyAllowed {
    if (START != 0) {
      rewards[to] = amount * BASE_RATE * (block.timestamp - START) / 1 days;
    }
  }

  function burn(address from, uint256 amount) external onlyAllowed {
    _burn(from, amount);
  }

  function claim(address account) external nonReentrant {
    _mint(account, 5000 ether);
  }
}