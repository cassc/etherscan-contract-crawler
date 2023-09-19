// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {DecimalMath} from "contracts/DODOV3MM/lib/DecimalMath.sol";
import {DODOMath} from "contracts/DODOV3MM/lib/DODOMath.sol";

/**
 * @title PMMPricing
 * @author DODO Breeder
 *
 * @notice DODO Pricing model
 */
library PMMPricing {
    struct PMMState {
        uint256 i;
        uint256 K;
        uint256 B;
        uint256 B0;
        uint256 BMaxAmount;
        uint256 BLeft;
    }

    function _queryBuyBaseToken(PMMState memory state, uint256 amount) internal pure returns (uint256 payQuote) {
        payQuote = _BuyBaseToken(state, amount, state.B, state.B0);
    }

    function _querySellQuoteToken(
        PMMState memory state,
        uint256 payQuoteAmount
    ) internal pure returns (uint256 receiveBaseAmount) {
        receiveBaseAmount = _SellQuoteToken(state, payQuoteAmount);
    }

    // ============ R > 1 cases ============

    function _BuyBaseToken(
        PMMState memory state,
        uint256 amount,
        uint256 baseBalance,
        uint256 targetBaseAmount
    ) internal pure returns (uint256 payQuoteToken) {
        require(amount < baseBalance, "DODOstate.BNOT_ENOUGH");
        uint256 B2 = baseBalance - amount;
        return DODOMath._GeneralIntegrate(targetBaseAmount, baseBalance, B2, state.i, state.K);
    }

    function _SellQuoteToken(
        PMMState memory state,
        uint256 payQuoteAmount
    ) internal pure returns (uint256 receiveBaseToken) {
        return DODOMath._SolveQuadraticFunctionForTrade(
            state.B0, state.B, payQuoteAmount, DecimalMath.reciprocalFloor(state.i), state.K
        );
    }
}