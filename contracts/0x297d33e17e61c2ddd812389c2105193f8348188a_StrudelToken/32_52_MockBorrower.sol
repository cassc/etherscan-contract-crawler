pragma solidity 0.6.6;

import "../IBorrower.sol";
import "../ILender.sol";

contract MockBorrower is IBorrower {
  address lender;
  bool reentrance;

  constructor(address _lender) public {
    lender = _lender;
  }

  event Data(uint256 amount, bytes32 data);

  function executeOnFlashMint(uint256 amount, bytes32 data) external override {
    emit Data(amount, data);
    if (reentrance) {
      ILender(lender).flashMint(amount, data);
    }
  }

  function flashMint(
    uint256 amount,
    bytes32 data,
    bool _reentrance
  ) external {
    reentrance = _reentrance;
    ILender(lender).flashMint(amount, data);
  }
}