// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "rain.interface.interpreter/IInterpreterStoreV1.sol";
import "rain.interface.orderbook/IOrderBookV2.sol";
import "../math/LibFixedPointMath.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

/// All information resulting from an order calculation that allows for vault IO
/// to be calculated and applied, then the handle IO entrypoint to be dispatched.
/// @param outputMax The UNSCALED maximum output calculated by the order
/// expression. WILL BE RESCALED ACCORDING TO TOKEN DECIMALS to an 18 fixed
/// point decimal number for the purpose of calculating actual vault movements.
/// The output max is CAPPED AT THE OUTPUT VAULT BALANCE OF THE ORDER OWNER.
/// The order is guaranteed that the total output of this single clearance cannot
/// exceed this (subject to rescaling). It is up to the order expression to track
/// values over time if the output max is to impose a global limit across many
/// transactions and counterparties.
/// @param IORatio The UNSCALED order ratio as input/output from the perspective
/// of the order. As each counterparty's input is the other's output, the IORatio
/// calculated by each order is inverse of its counterparty. IORatio is SCALED
/// ACCORDING TO TOKEN DECIMALS to allow 18 decimal fixed point math over the
/// vault balances. I.e. `1e18` returned from the expression is ALWAYS "one" as
/// ECONOMIC EQUIVALENCE between two tokens, but this will be rescaled according
/// to the decimals of the token. For example, if DAI and USDT have a ratio of
/// `1e18` then in reality `1e12` DAI will move in the vault for every `1` USDT
/// that moves, because DAI has `1e18` decimals per $1 peg and USDT has `1e6`
/// decimals per $1 peg. THE ORDER DEFINES THE DECIMALS for each token, NOT the
/// token itself, because the token MAY NOT report its decimals as per it being
/// optional in the ERC20 specification.
/// @param context The entire 2D context array, initialized from the context
/// passed into the order calculations and then populated with the order
/// calculations and vault IO before being passed back to handle IO entrypoint.
/// @param namespace The `StateNamespace` to be passed to the store for calculate
/// IO state changes.
/// @param kvs KVs returned from calculate order entrypoint to pass to the store
/// before calling handle IO entrypoint.
struct OrderIOCalculation {
    uint256 outputMax;
    //solhint-disable-next-line var-name-mixedcase
    uint256 IORatio;
    uint256[][] context;
    StateNamespace namespace;
    uint256[] kvs;
}

library LibOrderBook {
    using LibFixedPointMath for uint256;
    using Math for uint256;

    /// Calculates the clear state change given both order calculations for order
    /// alice and order bob. The input of each is their output multiplied by
    /// their IO ratio and the output of each is the smaller of their maximum
    /// output and the counterparty IO * max output.
    /// @param aliceOrderIOCalculation_ Order calculation A.
    /// @param bobOrderIOCalculation_ Order calculation B.
    /// @return The clear state change with absolute inputs and outputs for A and
    /// B.
    function _clearStateChange(
        OrderIOCalculation memory aliceOrderIOCalculation_,
        OrderIOCalculation memory bobOrderIOCalculation_
    ) internal pure returns (ClearStateChange memory) {
        ClearStateChange memory clearStateChange_;
        {
            clearStateChange_.aliceOutput = aliceOrderIOCalculation_
                .outputMax
                .min(
                    // B's input is A's output.
                    // A cannot output more than their max.
                    // B wants input of their IO ratio * their output.
                    // Always round IO calculations up.
                    bobOrderIOCalculation_.outputMax.fixedPointMul(
                        bobOrderIOCalculation_.IORatio,
                        Math.Rounding.Up
                    )
                );
            clearStateChange_.bobOutput = bobOrderIOCalculation_.outputMax.min(
                // A's input is B's output.
                // B cannot output more than their max.
                // A wants input of their IO ratio * their output.
                // Always round IO calculations up.
                aliceOrderIOCalculation_.outputMax.fixedPointMul(
                    aliceOrderIOCalculation_.IORatio,
                    Math.Rounding.Up
                )
            );

            // A's input is A's output * their IO ratio.
            // Always round IO calculations up.
            clearStateChange_.aliceInput = clearStateChange_
                .aliceOutput
                .fixedPointMul(
                    aliceOrderIOCalculation_.IORatio,
                    Math.Rounding.Up
                );
            // B's input is B's output * their IO ratio.
            // Always round IO calculations up.
            clearStateChange_.bobInput = clearStateChange_
                .bobOutput
                .fixedPointMul(
                    bobOrderIOCalculation_.IORatio,
                    Math.Rounding.Up
                );
        }
        return clearStateChange_;
    }
}