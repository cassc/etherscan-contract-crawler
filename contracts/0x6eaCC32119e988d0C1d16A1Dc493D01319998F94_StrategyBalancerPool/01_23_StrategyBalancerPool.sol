// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/
pragma solidity 0.8.4;

import "../strategies/balancer/BalancerPoolBoostedStrategyBase.sol";

contract StrategyBalancerPool is BalancerPoolBoostedStrategyBase {

  function initialize(
    address controller_,
    address vault_,
    address depositToken_,
    bytes32 poolId_,
    address gauge_,
    uint buybackRatio_
  ) external initializer {
    initializeStrategy(
      controller_,
      vault_,
      depositToken_,
      poolId_,
      gauge_,
      buybackRatio_
    );
  }

}