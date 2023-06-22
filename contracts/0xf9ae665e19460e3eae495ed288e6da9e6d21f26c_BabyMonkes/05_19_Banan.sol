// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Monkes.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Banan is ERC20, Ownable {
  uint256 public constant BANAN_RATE = 10;
  uint256 private startTime;
  address private monkesAddress;

  mapping(address => uint256) public lastUpdate;

  Monkes private monkesContract;

  modifier onlyMonkesAddress() {
    require(msg.sender == address(monkesContract), "Not monkes address");
    _;
  }

  constructor() ERC20("Banan", "$BANAN") {
    startTime = 1637020800;
  }

  function updateTokens(address from, address to) external onlyMonkesAddress {
    if (from != address(0)) {
      _mint(from, getPendingTokens(from));
      lastUpdate[from] = block.timestamp;
    }

    if (to != address(0)) {
      _mint(to, getPendingTokens(to));
      lastUpdate[to] = block.timestamp;
    }
  }

  function getPendingTokens(address _user) public view returns (uint256) {
    uint256[] memory ownedMonkes = monkesContract.walletOfOwner(_user);

    return
      (ownedMonkes.length *
        BANAN_RATE *
        (
          (block.timestamp -
            (lastUpdate[_user] >= startTime ? lastUpdate[_user] : startTime))
        )) / 86400;
  }

  function claim() external {
    _mint(msg.sender, getPendingTokens(msg.sender));
    lastUpdate[msg.sender] = block.timestamp;
  }

  function giveAway(address _user, uint256 _amount) public onlyOwner {
    _mint(_user, _amount);
  }

  function burn(address _user, uint256 _amount) public onlyMonkesAddress {
    _burn(_user, _amount);
  }

  function setMonkesContract(address _monkesAddress) public onlyOwner {
    monkesContract = Monkes(_monkesAddress);
  }
}