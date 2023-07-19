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

interface IFeeRewardForwarder {

  function LIQUIDITY_DENOMINATOR() external view returns (uint256);

  function MINIMUM_AMOUNT() external view returns (uint256);

  function SLIPPAGE_DENOMINATOR() external view returns (uint256);

  function VERSION() external view returns (string memory);

  function liquidityRouter() external view returns (address);

  function liquidityNumerator() external view returns (uint);

  function distribute(
    uint256 _amount,
    address _token,
    address _vault
  ) external returns (uint256);

  function fund() external view returns (address);

  function fundToken() external view returns (address);

  function liquidate(
    address tokenIn,
    address tokenOut,
    uint256 amount
  ) external returns (uint256);

  function notifyCustomPool(
    address,
    address,
    uint256
  ) external pure returns (uint256);

  function notifyPsPool(address, uint256) external pure returns (uint256);

  function slippageNumerator() external view returns (uint256);

  function tetu() external view returns (address);
}