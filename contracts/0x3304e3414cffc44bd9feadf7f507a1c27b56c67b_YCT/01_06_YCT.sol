// contracts/YCT.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YCT is ERC20, Ownable {

  struct TimeLocked {
    uint256 amount;
    uint256 releaseTime;
  }

  TimeLocked[4] public lockedItems;

  event Lock(uint256 amount, uint256 releaseTime);
  event Unlock(address indexed to, uint256 amount);
  
  constructor() ERC20("YesCrypto Token", "YCT") {

    uint256 totalAmount = 300000000 * (10 ** uint256(decimals()));
    uint256 sixtyPercent = totalAmount / 100 * 60;
    uint256 tenPercent = totalAmount / 100 * 10;

    _mint(_msgSender(), sixtyPercent);
    lock(0, tenPercent, 1643673600); // 2022-02-01 00:00 GMT
    lock(1, tenPercent, 1651363200); // 2022-05-01 00:00 GMT
    lock(2, tenPercent, 1659312000); // 2022-08-01 00:00 GMT
    lock(3, tenPercent, 1667260800); // 2022-11-01 00:00 GMT
  }

  function lock(uint i, uint256 amount, uint256 releaseTime) internal {
    lockedItems[i] = TimeLocked({amount: amount, releaseTime: releaseTime});
    emit Lock(amount, releaseTime);
  }

  function unlock() public {
    for(uint i = 0; i < lockedItems.length; i++) {
      TimeLocked memory item = lockedItems[i];
      if (item.amount > 0 && item.releaseTime <= block.timestamp) {
        lockedItems[i].amount = 0;
        _mint(owner(), item.amount);
        emit Unlock(owner(), item.amount);
      }
    }
  }

  function totalSupply() public view override returns (uint256) {
    uint256 total = super.totalSupply();
    for(uint i = 0; i < lockedItems.length; i++) {
      total += lockedItems[i].amount;
    }
    return total;
  }
}