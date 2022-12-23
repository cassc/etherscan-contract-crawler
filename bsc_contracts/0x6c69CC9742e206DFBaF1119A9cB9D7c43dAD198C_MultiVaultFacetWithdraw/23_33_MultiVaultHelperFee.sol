// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/multivault/IMultiVaultFacetFees.sol";
import "../../interfaces/multivault/IMultiVaultFacetTokens.sol";
import "../../interfaces/multivault/IMultiVaultFacetLiquidity.sol";
import "../../interfaces/multivault/IMultiVaultFacetFeesEvents.sol";

import "../storage/MultiVaultStorage.sol";
import "./MultiVaultHelperLiquidity.sol";


abstract contract MultiVaultHelperFee is MultiVaultHelperLiquidity, IMultiVaultFacetFeesEvents {
    modifier respectFeeLimit(uint fee) {
        require(fee <= MultiVaultStorage.FEE_LIMIT);

        _;
    }

    /// @notice Calculates fee for deposit or withdrawal.
    /// @param amount Amount of tokens.
    /// @param _token Token address.
    /// @param fee Fee type (Deposit = 0, Withdraw = 1).
    function _calculateMovementFee(
        uint256 amount,
        address _token,
        IMultiVaultFacetFees.Fee fee
    ) internal view returns (uint256) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        IMultiVaultFacetTokens.Token memory token = s.tokens_[_token];

        uint tokenFee = fee == IMultiVaultFacetFees.Fee.Deposit ? token.depositFee : token.withdrawFee;

        return tokenFee * amount / MultiVaultStorage.MAX_BPS;
    }

    function _increaseTokenFee(
        address token,
        uint _amount
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        if (_amount == 0) return;

        IMultiVaultFacetLiquidity.Liquidity memory liquidity = s.liquidity[token];

        uint amount;

        if (s.liquidity[token].activation == 0) {
            amount = _amount;
        } else {
            uint liquidity_fee = _amount * liquidity.interest / MultiVaultStorage.MAX_BPS;

            amount = _amount - liquidity_fee;

            _increaseTokenCash(token, liquidity_fee);
        }

        if (amount == 0) return;

        s.fees[token] += amount;
        emit EarnTokenFee(token, amount);
    }
}