// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title IAlloyx
 * @author AlloyX
 */
interface IAlloyx {
  /**
   * @notice Source denotes the protocol to which the component is going to invest
   */
  enum Source {
    USDC,
    GOLDFINCH,
    FIDU,
    TRUEFI,
    MAPLE,
    RIBBON,
    RIBBON_LEND,
    CLEAR_POOL,
    CREDIX,
    FLUX,
    BACKED,
    WALLET,
    OPEN_EDEN,
    ALLOYX_V1
  }

  /**
   * @notice State refers to the pool status
   */
  enum State {
    INIT,
    STARTED,
    NON_GOVERNANCE
  }

  /**
   * @notice State refers to the pool status
   */
  enum WithdrawalStep {
    DEFAULT,
    INIT,
    COMPLETE
  }

  /**
   * @notice Component is the structure containing the information of which protocol to invest in
   * how much to invest, where the proportion has 4 decimals, meaning that 100 is 1%
   */
  struct Component {
    uint256 proportion;
    address poolAddress;
    uint256 tranche;
    Source source;
  }

  /**
   * @notice DepositAmount is the structure containing the information of an address and amount
   */
  struct DepositAmount {
    address depositor;
    uint256 amount;
  }
}