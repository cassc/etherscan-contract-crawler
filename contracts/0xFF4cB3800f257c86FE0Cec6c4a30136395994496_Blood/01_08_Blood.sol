// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./MoonBats.sol";
import "@rari-capital/solmate/src/tokens/ERC20.sol";
import "@rari-capital/solmate/src/auth/Owned.sol";

contract Blood is ERC20, Owned {
  uint256 public battleEndTimestamp;
  uint256 public attackInterval = 1 hours;
  uint256 private _minBloodAmount = 1;
  uint256 private _maxBloodAmount = 5;

  MoonBats private immutable moonBatsContract;

  mapping(address => uint256) public lastAttacked;

  constructor(address _moonBatsAddress)
    ERC20("Blood", "$BLOOD", 0)
    Owned(msg.sender)
  {
    moonBatsContract = MoonBats(_moonBatsAddress);
  }

  function bite() external {
    require(block.timestamp < battleEndTimestamp, "Battle has ended");
    require(lastAttacked[msg.sender] + attackInterval < block.timestamp, "Needs to wait until next attack");

    uint256 _ownedBats = moonBatsContract.balanceOf(msg.sender);

    require(_ownedBats > 0, "Does not own any Moon Bats");

    uint256 _totalBlood = getRandom(_ownedBats) * _ownedBats;

    lastAttacked[msg.sender] = block.timestamp;

    _mint(msg.sender, _totalBlood);
  }

  // Get pseudo-random number between 1 and 5
  function getRandom(uint256 _nonce) internal view returns (uint256) {
    uint256 _randomness = uint256(
      keccak256(
        abi.encodePacked(block.timestamp, msg.sender, totalSupply, _nonce)
      )
    );

    return _randomness % (_maxBloodAmount - _minBloodAmount + 1) + _minBloodAmount;
  }

  function burn(uint256 _amount) public {
    _burn(msg.sender, _amount);
  }

  function setBattleEndTimestamp(uint256 _newBattleEndTimestamp)
    external
    onlyOwner
  {
    battleEndTimestamp = _newBattleEndTimestamp;
  }

  function setAttackInterval(uint256 _newAttackInterval)
    external
    onlyOwner
  {
    attackInterval = _newAttackInterval;
  }

  function setMinBloodAmount(uint256 _newMinBloodAmount)
    external
    onlyOwner
  {
    _minBloodAmount = _newMinBloodAmount;
  }

  function setMaxBloodAmount(uint256 _newMaxBloodAmount)
    external
    onlyOwner
  {
    _maxBloodAmount = _newMaxBloodAmount;
  }
}