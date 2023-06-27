// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Rebasable is Ownable {
  address private _rebaser;

  event TransferredRebasership(address indexed previousRebaser, address indexed newRebaser);

  constructor() internal {
    address msgSender = _msgSender();
    _rebaser = msgSender;
    emit TransferredRebasership(address(0), msgSender);
  }

  function Rebaser() public view returns(address) {
    return _rebaser;
  }

  modifier onlyRebaser() {
    require(_rebaser == _msgSender(), "caller is not rebaser");
    _;
  }

  function transferRebasership(address newRebaser) public virtual onlyOwner {
    require(newRebaser != address(0), "new rebaser is address zero");
    emit TransferredRebasership(_rebaser, newRebaser);
    _rebaser = newRebaser;
  }
}