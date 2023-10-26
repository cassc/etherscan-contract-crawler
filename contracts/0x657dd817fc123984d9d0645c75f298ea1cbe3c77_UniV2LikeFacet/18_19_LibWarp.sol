// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IWETH} from '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import {IPermit2} from '../interfaces/external/IPermit2.sol';
import {IStargateComposer} from '../interfaces/external/IStargateComposer.sol';

library LibWarp {
  bytes32 constant DIAMOND_STORAGE_SLOT = keccak256('diamond.storage.LibWarp');

  struct State {
    IWETH weth;
    IPermit2 permit2;
    IStargateComposer stargateComposer;
  }

  function state() internal pure returns (State storage s) {
    bytes32 slot = DIAMOND_STORAGE_SLOT;

    assembly {
      s.slot := slot
    }
  }

  function applySlippage(uint256 amount, uint16 slippage) internal pure returns (uint256) {
    return (amount * (10_000 - slippage)) / 10_000;
  }
}