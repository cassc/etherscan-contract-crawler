pragma solidity 0.6.12;

import "../prize-strategy/PeriodicPrizeStrategy.sol";
import "./PeriodicPrizeStrategyDistributorInterface.sol";

/* solium-disable security/no-block-members */
contract PeriodicPrizeStrategyHarness is PeriodicPrizeStrategy {

  PeriodicPrizeStrategyDistributorInterface distributor;

  function setDistributor(PeriodicPrizeStrategyDistributorInterface _distributor) external {
    distributor = _distributor;
  }

  uint256 internal time;
  function setCurrentTime(uint256 _time) external {
    time = _time;
  }

  function _currentTime() internal override view returns (uint256) {
    return time;
  }

  function setRngRequest(uint32 requestId, uint32 lockBlock) external {
    rngRequest.id = requestId;
    rngRequest.lockBlock = lockBlock;
  }

  function _distribute(uint256 randomNumber) internal override {
    distributor.distribute(randomNumber);
  }

  function forceBeforeAwardListener(BeforeAwardListenerInterface listener) external {
    beforeAwardListener = listener;
  }
}