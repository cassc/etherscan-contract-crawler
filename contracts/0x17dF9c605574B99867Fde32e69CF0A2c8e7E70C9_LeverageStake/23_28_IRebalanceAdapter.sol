// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IETF} from './IETF.sol';
import {IBpool} from './IBpool.sol';

interface IRebalanceAdapter {
  enum SwapType {
    UNISWAPV2,
    UNISWAPV3,
    ONEINCH
  }

  struct RebalanceInfo {
    address etf; // etf address
    address token0;
    address token1;
    address aggregator; // the swap router to use
    SwapType swapType;
    uint256 quantity;
    bytes data; // v3: (uint,uint256[]) v2: (uint256,address[])
  }

  function getUnderlyingInfo(
    IBpool bpool,
    address token
  ) external view returns (uint256 tokenBalance, uint256 tokenWeight);

  function approve(IETF etf, address token, address spender, uint256 amount) external;

  function approveSwapRouter(address router, bool isApproved) external;

  function rebalance(RebalanceInfo calldata rebalanceInfo) external;
}