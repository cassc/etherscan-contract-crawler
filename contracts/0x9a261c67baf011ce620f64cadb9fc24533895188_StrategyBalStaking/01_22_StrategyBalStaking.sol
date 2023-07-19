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

import "../strategies/balancer/BalStakingStrategyBase.sol";

contract StrategyBalStaking is BalStakingStrategyBase {

  // !!! ONLY CONSTANTS AND DYNAMIC ARRAYS/MAPS !!!
  // push elements to arrays instead of predefine setup
  address private constant _BPT_BAL_WETH = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
  address[] private _assets;
  address[] private _poolRewards;

  function initialize(
    address controller_,
    address vault_,
    address depositor_,
    address veLocker_
  ) external initializer {
    _assets.push(_BAL_TOKEN);
    _assets.push(_WETH_TOKEN);
    _poolRewards.push(_BAL_TOKEN);
    _poolRewards.push(_BB_USD_TOKEN);
    BalStakingStrategyBase.initializeStrategy(
      controller_,
      _BPT_BAL_WETH,
      vault_,
      _poolRewards,
      veLocker_,
      depositor_
    );
  }

  // assets should reflect underlying tokens need to investing
  function assets() external override view returns (address[] memory) {
    return _assets;
  }
}