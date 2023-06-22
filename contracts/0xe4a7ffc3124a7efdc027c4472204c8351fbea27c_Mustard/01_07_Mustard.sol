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

  function getClaimable(address account) external view returns (uint256) {
    return rewards[account] + getPending(account);
  }

  function getPending(address account) internal view returns (uint256) {
    if (START == 0) {
      return 0;
    } else {
      return GlizzyGang.balanceOf(account)
        * BASE_RATE
        * (block.timestamp - (lastUpdate[account] > START ? lastUpdate[account] : START))
        / 1 days;
    }
  }

  function migrate(address to, uint256 amount) external onlyAllowed {
    if (START != 0) {
      rewards[to] = amount * BASE_RATE * (block.timestamp - START) / 1 days;
    }
  }

  function update(address from, address to) external onlyAllowed {
    if (from != address(0)) {
      rewards[from] += getPending(from);
      lastUpdate[from] = block.timestamp;
    }
    if (to != address(0)) {
      rewards[to] += getPending(to);
      lastUpdate[to] = block.timestamp;
    }
  }

  function burn(address from, uint256 amount) external onlyAllowed {
    _burn(from, amount);
  }

  function claim(address account) external nonReentrant {
    require(msg.sender == account || allowed[msg.sender], "Caller not allowed");

    _mint(account, rewards[account] + getPending(account));
    rewards[account] = 0;
    lastUpdate[account] = block.timestamp;
  }
}