//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../exchange/interfaces/IExchange.sol";
import "../lib/Utils.sol";

/// @title An interface for liquidations that allows liquidation bots to
///        query multiple trades at the same time.
//
// `receive()` in this contract is used to be able to call `isLiquidatable` inside of a `callStatic`
// JSON-PRC invocation.  `isLiquidatable_exchange` protects `receive()` to be only invokable from
// inside of an exchange, effectively blocking ETH transfers.  Invocation from `isLiquidatable` is,
// unfortunately, still possible at the moment.  But as `isLiquidatable` should not be called
// outside of the `callStatic` by the convention of our API, it is not a high priority issue.
// slither-disable-next-line locked-ether
contract LiquidationBotApi is GitCommitHash {
    /// @dev Is only set by `isLiquidatable` to make sure this contract would not accidentally
    /// accept any payment.
    address isLiquidatable_exchange;

    /// @notice Returns an array of booleans to indicate whether or not a position is
    ///         liquidatable.
    ///         Note: this is not a view function and will cost gas when executed on chain.
    ///         Even worse, this contract would be receiving liquidation funds instead of
    ///         the caller.
    ///         This should only be called with callStatic.
    /// @param _exchange The address of the exchange to query
    /// @param _traders The array of trader address to query
    function isLiquidatable(address _exchange, address[] calldata _traders)
        external
        returns (bool[] memory)
    {
        IExchange exchange = IExchange(payable(_exchange));

        // Safe cast detector gives a false positive, taking this as a conversion from
        // `bool` to `bool[]`.  Safe cast version 9f13fafe6a903708ac82b49a738efd97551de3c4, slither
        // version 0.8.2.
        // slither-disable-next-line safe-cast
        bool[] memory liquidations = new bool[](_traders.length);

        // This function should only be called from `callStatic`, so the null check does not really
        // matter here.
        // slither-disable-next-line missing-zero-check
        isLiquidatable_exchange = _exchange;

        for (uint256 i = 0; i < _traders.length; i++) {
            // We do not care about the payout here, knowing whether
            // or not this liquidation will work at all is good enough.
            // slither-disable-next-line unused-return,calls-loop
            try exchange.liquidate(_traders[i]) {
                liquidations[i] = true;
            } catch Error(string memory) {
                liquidations[i] = false;
            } catch {
                liquidations[i] = false;
            }
        }

        isLiquidatable_exchange = address(0);

        return liquidations;
    }

    /// @dev Need this in order for the `exchange.liquidate()` not to revert when called from
    /// `isLiquidatable`.
    receive() external payable {
        require(msg.sender == isLiquidatable_exchange, "Not accepting payments");
    }
}