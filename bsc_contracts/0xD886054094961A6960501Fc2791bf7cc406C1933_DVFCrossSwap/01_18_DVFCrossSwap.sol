// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.4;

import "./Swap.sol";

/**
 * Deversifi escrow contract for performing swaps and bridging while maintaining user's custody
 */
contract DVFCrossSwap is Swap {
  // constructor() initializer { }

  function initialize(address admin, address paraswap, address paraswapTransferProxy) external initializer {
    __DVFAccessControl_init(admin);
    __Swap_init(paraswap, paraswapTransferProxy);
  }
}