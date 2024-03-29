// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

/**
 * @dev interface to interact with multicall (prev anyswap) anycall proxy
 *     see https://github.com/anyswap/multichain-smart-contracts/blob/main/contracts/anycall/AnyswapV6CallProxy.sol
 */
interface Multichain {
  function anyCall(
    address _to,
    bytes calldata _data,
    address _fallback,
    uint256 _toChainID,
    uint256 _flags
  ) external payable;

  function context()
    external
    view
    returns (
      address from,
      uint256 fromChainID,
      uint256 nonce
    );

  function executor() external view returns (address executor);

  function calcSrcFees(
    string calldata _appID,
    uint256 _toChainID,
    uint256 _dataLength
  ) external view returns (uint256);
}