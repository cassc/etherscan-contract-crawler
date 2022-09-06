// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IPunko {
  function balanceOf(address owner) external view returns (uint256);
}

contract PunkoCoin is ERC20, Ownable, ReentrancyGuard {
  IPunko public Punko;
  address public burnerWallet;
  uint256 public rateStaking = 1000 ether;
  uint256 public START;

  mapping(address => uint256) public rewards;
  mapping(address => uint256) public lastUpdate;
  mapping(address => bool) public allowed;

  constructor(address PunkoContract) ERC20("Punko Coin", "Punko Coin") {
    Punko = IPunko(PunkoContract);
    allowed[PunkoContract] = true;
    _mint(msg.sender, rateStaking);
  }

  modifier onlyAllowed() {
    require(allowed[msg.sender], "Caller not allowed");
    _;
  }

  function start() public onlyOwner {
    require(START == 0, "Already started");
    START = block.timestamp;
  }

  function setStaking(uint256 _baseRate) public onlyOwner {
    rateStaking = _baseRate;
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
    } 
    else 
    {
      return Punko.balanceOf(account) * rateStaking* (block.timestamp - (lastUpdate[account] > START ? lastUpdate[account] : START))/ 1 days;
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
  
  function payment(uint256 amount) external nonReentrant {
    _transfer(msg.sender,burnerWallet, amount);
  }

  function claim(address account) external nonReentrant {
    require(msg.sender == account || allowed[msg.sender], "Caller not allowed");
    _mint(account, rewards[account] + getPending(account));
    rewards[account] = 0;
    lastUpdate[account] = block.timestamp;
  }
}