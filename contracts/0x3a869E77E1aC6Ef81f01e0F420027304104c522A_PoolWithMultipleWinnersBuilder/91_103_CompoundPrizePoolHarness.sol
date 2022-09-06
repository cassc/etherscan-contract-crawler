pragma solidity 0.6.12;

import "../prize-pool/compound/CompoundPrizePool.sol";

/* solium-disable security/no-block-members */
contract CompoundPrizePoolHarness is CompoundPrizePool {

  uint256 public currentTime;

  function setCurrentTime(uint256 _currentTime) external {
    currentTime = _currentTime;
  }

  function _currentTime() internal override view returns (uint256) {
    return currentTime;
  }

  function supply(uint256 mintAmount) external {
    _supply(mintAmount);
  }

  function redeem(uint256 redeemAmount) external returns (uint256) {
    return _redeem(redeemAmount);
  }
}