pragma solidity 0.6.12;

import "./StakePrizePoolHarness.sol";
import "../external/openzeppelin/ProxyFactory.sol";

/// @title Stake Prize Pool Proxy Factory
/// @notice Minimal proxy pattern for creating new Stake Prize Pools
contract StakePrizePoolHarnessProxyFactory is ProxyFactory {

  /// @notice Contract template for deploying proxied Prize Pools
  StakePrizePoolHarness public instance;

  /// @notice Initializes the Factory with an instance of the Stake Prize Pool
  constructor () public {
    instance = new StakePrizePoolHarness();
  }

  /// @notice Creates a new Stake Prize Pool as a proxy of the template instance
  /// @return A reference to the new proxied Stake Prize Pool
  function create() external returns (StakePrizePoolHarness) {
    return StakePrizePoolHarness(deployMinimal(address(instance), ""));
  }
}