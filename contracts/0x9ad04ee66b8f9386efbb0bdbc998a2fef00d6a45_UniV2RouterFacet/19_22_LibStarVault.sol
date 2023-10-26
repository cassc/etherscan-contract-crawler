// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * NOTE: Events and errors must be copied to ILibStarVault
 */
library LibStarVault {
  /**
   * The swap fee is over the maximum allowed
   */
  error FeeTooHigh(uint256 maxFeeBps);

  event Fee(
    address indexed partner,
    address indexed token,
    uint256 partnerFee,
    uint256 protocolFee
  );

  struct State {
    /**
     * Token balances per partner
     * Mapping: Partner -> token -> balance
     */
    mapping(address => mapping(address => uint256)) partnerBalances;
    /**
     * Total balances per token for all partners.
     * Mapping: token -> balance
     */
    mapping(address => uint256) partnerBalancesTotal;
  }

  uint256 private constant MAX_FEE_BPS = 2_000;

  function state() internal pure returns (State storage s) {
    /**
     * NOTE: Three storage slots used to store all partners addresses and partner tokens were
     * removed to save gas.
     */
    unchecked {
      uint256 storagePosition = uint256(keccak256('diamond.storage.LibStarVault')) + 3;

      assembly {
        s.slot := storagePosition
      }
    }
  }

  /**
   * By using a library function we ensure that the storage used by the library is whichever contract
   * is calling this function
   */
  function registerCollectedFee(
    address partner,
    address token,
    uint256 partnerFee,
    uint256 protocolFee
  ) internal {
    State storage s = state();

    unchecked {
      s.partnerBalances[partner][token] += partnerFee;
      s.partnerBalancesTotal[token] += partnerFee;
    }

    emit Fee(partner, token, partnerFee, protocolFee);
  }

  function calculateAndRegisterFee(
    address partner,
    address token,
    uint256 feeBps,
    uint256 amountOutQuoted,
    uint256 amountOutActual
  ) internal returns (uint256 amountOutUser_) {
    if (feeBps > MAX_FEE_BPS) {
      revert FeeTooHigh(MAX_FEE_BPS);
    }

    unchecked {
      uint256 feeTotal;
      uint256 feeBasis = amountOutActual;

      if (amountOutActual > amountOutQuoted) {
        // Positive slippage
        feeTotal = amountOutActual - amountOutQuoted;

        // Change the fee basis for use below
        feeBasis = amountOutQuoted;
      }

      // Fee taken from actual
      feeTotal += (feeBasis * feeBps) / 10_000;

      // If a partner is set, split the fee in half
      uint256 feePartner = partner == address(0) ? 0 : (feeTotal * 50) / 100;
      uint256 feeProtocol = feeTotal - feePartner;

      if (feeProtocol > 0) {
        registerCollectedFee(partner, token, feePartner, feeProtocol);
      }

      return amountOutActual - feeTotal;
    }
  }
}