//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./interfaces/IExchangeHook.sol";
import "./interfaces/IExchangeLedger.sol";
import "../incentives/IExternalBalanceIncentives.sol";
import "../incentives/interfaces/ITradingFeeIncentives.sol";
import "../lib/FsMath.sol";
import "../lib/Utils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @dev This contract needs to have an owner who can add/remove incentive contracts.
contract IncentivesHook is Ownable, IExchangeHook, GitCommitHash {
    /// @notice Max number of incentives contracts per type (e.g. trading fee).
    uint8 public constant INCENTIVES_LIMIT_PER_TYPE = 10;

    /// @notice The exchange address that this contract listens to for trade position changes.
    address public immutable exchange;

    address[] public openInterestIncentivesContracts;
    address[] public tradingFeeIncentivesContracts;
    uint8 public openInterestIncentivesCount;
    uint8 public tradingFeeIncentivesCount;

    /// @notice Emitted when a call to the trader incentives fails.
    ///         Note: This event should not be fired in regular operations, however
    ///         to ensure that the exchange would function even if the incentives are broken
    ///         the exchange does not revert if the incentives revert.
    ///         This event is used in monitoring to see issues with the incentives and potentially
    ///         upgrade and fix.
    /// @param trader The trader that failed to update for the incentives call.
    /// @param openInterestIncentives The address of the open interest incentives contract that failed the update.
    /// @param incentivesTradeSize The calculated size of the incentives update.
    event OpenInterestIncentivesUpdateFailed(
        address indexed trader,
        address openInterestIncentives,
        uint256 incentivesTradeSize
    );

    /// @notice Emitted when a call to the trading fee incentives fails.
    ///         Note: This event should not be fired in regular operations, however
    ///         to ensure that the exchange would function even if the incentives are broken
    ///         the exchange does not revert if the incentives revert.
    ///         This event is used in monitoring to see issues with the incentives and potentially
    ///         upgrade and fix.
    /// @param trader The trader that failed to update for the incentives call.
    /// @param tradingFeeIncentives The address of the trading fee incentives contract that failed the update.
    /// @param incentivesFeeSize The calculated size of the incentives update.
    event TradingFeeIncentivesUpdateFailed(
        address indexed trader,
        address tradingFeeIncentives,
        uint256 incentivesFeeSize
    );

    event TradingFeeIncentivesAdded(address tradingFeeIncentives);
    event TradingFeeIncentivesRemoved(address tradingFeeIncentives);
    event OpenInterestIncentivesAdded(address openInterestIncentives);
    event OpenInterestIncentivesRemoved(address openInterestIncentives);

    modifier exchangeOnly() {
        require(msg.sender == exchange, "Not the right sender");
        _;
    }

    constructor(address _exchange) {
        // slither-disable-next-line missing-zero-check
        exchange = FsUtils.nonNull(_exchange);
    }

    /// @notice Register the given open interest incentives contract with the hook so that it'll get called when
    /// there's a position change in the exchange.
    function addOpenInterestIncentives(address openInterestIncentives) external onlyOwner {
        if (addIncentivesContract(openInterestIncentivesContracts, openInterestIncentives)) {
            openInterestIncentivesCount++;
            emit OpenInterestIncentivesAdded(openInterestIncentives);
        }
    }

    /// @notice Register the given trading fee incentives contract with the hook so that it'll get called when
    /// there's a position change in the exchange.
    function addTradingFeeIncentives(address tradingFeeIncentives) external onlyOwner {
        if (addIncentivesContract(tradingFeeIncentivesContracts, tradingFeeIncentives)) {
            tradingFeeIncentivesCount++;
            emit TradingFeeIncentivesAdded(tradingFeeIncentives);
        }
    }

    /// @notice Remove the given open interest incentives contract so that it'll no longer get called when there's a
    /// position change in the exchange. This does not destroy the incentives contract so users will still be able
    /// call it to claim rewards if there's any.
    function removeOpenInterestIncentives(address openInterestIncentives) external onlyOwner {
        if (removeIncentivesContract(openInterestIncentivesContracts, openInterestIncentives)) {
            openInterestIncentivesCount--;
            emit OpenInterestIncentivesRemoved(openInterestIncentives);
        }
    }

    /// @notice Remove the given trading feeincentives contract so that it'll no longer get called when there's a
    /// position change in the exchange. This does not destroy the incentives contract so users will still be able
    /// call it to claim rewards if there's any.
    function removeTradingFeeIncentives(address tradingFeeIncentives) external onlyOwner {
        if (removeIncentivesContract(tradingFeeIncentivesContracts, tradingFeeIncentives)) {
            tradingFeeIncentivesCount--;
            emit TradingFeeIncentivesRemoved(tradingFeeIncentives);
        }
    }

    /// @notice onChangePosition is called by the ExchangeLedger when there's a position change. This function will
    /// call all registered incentives contracts to inform them of the update so they can update rewards accordingly.
    /// This allows partial failures so if an update call to any incentives contract fails (unlikely to happen), the
    /// rest of the incentives contracts would still get updated.
    /// @dev We rely on try catch to tolerate partial failures when updating individual incentives contracts.
    function onChangePosition(IExchangeLedger.ChangePositionData calldata cpd)
        external
        override
        exchangeOnly
    {
        for (uint8 i = 0; i < openInterestIncentivesContracts.length; i++) {
            updateIncentivesPosition(
                openInterestIncentivesContracts[i],
                cpd.trader,
                cpd.totalAsset,
                cpd.totalStable,
                cpd.oraclePrice
            );
        }

        // We don't generate trading fee incentives for liquidations (liquidator is set).
        if (cpd.liquidator == address(0)) {
            for (uint8 i = 0; i < tradingFeeIncentivesContracts.length; i++) {
                updateTradingFeeIncentives(
                    tradingFeeIncentivesContracts[i],
                    cpd.trader,
                    FsMath.safeCastToUnsigned(cpd.tradeFee)
                );
            }
        }
    }

    /// Returns true if the specified incentives contract wasn't already there and was added.
    function addIncentivesContract(address[] storage contracts, address _incentivesContract)
        private
        returns (bool)
    {
        require(contracts.length < INCENTIVES_LIMIT_PER_TYPE, "Too many incentives contracts");

        address incentivesContract = FsUtils.nonNull(_incentivesContract);
        // Avoid adding duplicates.
        for (uint8 i = 0; i < contracts.length; i++) {
            if (contracts[i] == incentivesContract) {
                return false;
            }
        }
        contracts.push(incentivesContract);
        return true;
    }

    /// @dev This doesn't do anything if we try to remove a contract that's a zero address or not there.
    /// Returns true if the specified incentives contract exists and was removed.
    function removeIncentivesContract(address[] storage contracts, address incentivesContract)
        private
        returns (bool)
    {
        // We can assume there will be no duplicates as adding checks against that.
        for (uint8 i = 0; i < contracts.length; i++) {
            // Remove the contract by moving it to the end and then decrease the length.
            // We do this instead of delete array[i] because it leaves a gap in the array.
            if (contracts[i] == incentivesContract) {
                contracts[i] = contracts[contracts.length - 1];
                contracts[contracts.length - 1] = incentivesContract;
                // No concurrent modification here as we return immediately after popping.
                contracts.pop();
                return true;
            }
        }
        return false;
    }

    /// @dev Internal function to add a given incentives contract to the right list by type
    /// (trading fee vs open interest).
    function updateIncentivesPosition(
        address openInterestIncentives,
        address trader,
        int256 asset,
        int256 stable,
        int256 price
    ) private {
        uint256 incentivesSize = calculateIncentivesSize(asset, stable, price);

        // We try catch here so that if updating one incentives contract fails, we can still continue to update others.
        // `updateIncentivesPosition` is called inside a loop, but it is limited to
        // `INCENTIVES_LIMIT_PER_TYPE` iteration.
        // slither-disable-next-line calls-loop
        try
            IExternalBalanceIncentives(openInterestIncentives).updateBalance(trader, incentivesSize)
        {} catch {
            // We rely on the ExternalBalanceIncentives contract not to call us back, causing events
            // to be emitted in an incorrect order.  This is the issue Slither is flagging here.
            // slither-disable-next-line reentrancy-events
            emit OpenInterestIncentivesUpdateFailed(trader, openInterestIncentives, incentivesSize);
        }
    }

    function updateTradingFeeIncentives(
        address tradingFeeIncentives,
        address trader,
        uint256 tradeFee
    ) private {
        // We try catch here so that if updating one incentives contract fails, we can still continue to update others.
        // `updateIncentivesPosition` is called inside a loop, but it is limited to
        // `INCENTIVES_LIMIT_PER_TYPE` iteration.
        // slither-disable-next-line calls-loop
        try ITradingFeeIncentives(tradingFeeIncentives).addFee(trader, tradeFee) {} catch {
            // We rely on the TradingFeeIncentives contract not to call us back, causing events to
            // be emitted in an incorrect order.  This is the issue Slither is flagging here.
            // slither-disable-next-line reentrancy-events
            emit TradingFeeIncentivesUpdateFailed(trader, tradingFeeIncentives, tradeFee);
        }
    }

    /// @dev Calculates the size of the incentives update for a given trade
    ///      The size is the position size (in asset) times its leverage
    ///      e.g a long trade of 10A with a leverage of 5x would return a
    ///      value of 50
    function calculateIncentivesSize(
        int256 asset,
        int256 stable,
        int256 price
    ) private pure returns (uint256) {
        uint256 leverage = FsMath.calculateLeverage(asset, stable, price);
        uint256 incentiveSize = (FsMath.abs(asset) * leverage) / 1 ether;
        return incentiveSize;
    }
}