pragma solidity 0.6.12;

import "../prize-strategy/BeforeAwardListener.sol";

/* solium-disable security/no-block-members */
contract BeforeAwardListenerStub is BeforeAwardListener {

  event Awarded();

  function beforePrizePoolAwarded(uint256 randomNumber, uint256 prizePeriodStartedAt) external override {
    emit Awarded();
  }
}