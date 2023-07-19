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

import "@tetu_io/tetu-contracts/contracts/openzeppelin/IERC20.sol";

interface IBalLocker {

  function VE_BAL() external view returns (address);

  function VE_BAL_UNDERLYING() external view returns (address);

  function BALANCER_MINTER() external view returns (address);

  function BAL() external view returns (address);

  function gaugeController() external view returns (address);

  function feeDistributor() external view returns (address);

  function operator() external view returns (address);

  function voter() external view returns (address);

  function delegateVotes(bytes32 _id, address _delegateContract, address _delegate) external;

  function clearDelegatedVotes(bytes32 _id, address _delegateContract) external;

  function depositVe(uint256 amount) external;

  function claimVeRewards(IERC20[] memory tokens, address recipient) external;

  function investedUnderlyingBalance() external view returns (uint);

  function depositToGauge(address gauge, uint amount) external;

  function withdrawFromGauge(address gauge, uint amount) external;

  function claimRewardsFromGauge(address gauge, address receiver) external;

  function claimRewardsFromMinter(address gauge, address receiver) external returns (uint claimed);

  function changeDepositorToGaugeLink(address gauge, address newDepositor) external;

}