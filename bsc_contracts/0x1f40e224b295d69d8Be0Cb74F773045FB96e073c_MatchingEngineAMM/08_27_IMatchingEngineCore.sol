/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface IMatchingEngineCore {
    struct LiquidityOfEachPip {
        uint128 pip;
        uint256 liquidity;
    }

    /// @notice Emitted when market order filled
    /// @param isBuy side of order
    /// @param amount amount filled
    /// @param toPip fill to pip
    /// @param startPip fill start pip
    /// @param remainingLiquidity remaining liquidity in pip
    /// @param filledIndex number of index filled
    event MarketFilled(
        bool isBuy,
        uint256 indexed amount,
        uint128 toPip,
        uint256 startPip,
        uint128 remainingLiquidity,
        uint64 filledIndex
    );

    /// @notice Emitted when market order filled
    /// @param orderId side of order
    /// @param pip amount filled
    /// @param size fill to pip
    /// @param isBuy fill start pip
    event LimitOrderCreated(
        uint64 orderId,
        uint128 pip,
        uint128 size,
        bool isBuy
    );

    /// @notice Emitted limit order cancel
    /// @param size size of order
    /// @param pip of order
    /// @param orderId id of order cancel
    /// @param isBuy fill start pip
    event LimitOrderCancelled(
        bool isBuy,
        uint64 orderId,
        uint128 pip,
        uint256 size
    );

    /// @notice Emitted when update max finding word
    /// @param pairManager address of pair
    /// @param newMaxFindingWordsIndex new value
    event UpdateMaxFindingWordsIndex(
        address pairManager,
        uint128 newMaxFindingWordsIndex
    );

    /// @notice Emitted when update max finding word for limit order
    /// @param newMaxWordRangeForLimitOrder new value
    event MaxWordRangeForLimitOrderUpdated(
        uint128 newMaxWordRangeForLimitOrder
    );

    /// @notice Emitted when update max finding word for market order
    /// @param newMaxWordRangeForMarketOrder new value
    event MaxWordRangeForMarketOrderUpdated(
        uint128 newMaxWordRangeForMarketOrder
    );

    /// @notice Emitted when snap shot reserve
    /// @param pip pip snap shot
    /// @param timestamp time snap shot
    event ReserveSnapshotted(uint128 pip, uint256 timestamp);

    /// @notice Emitted when limit order updated
    /// @param pairManager address of pair
    /// @param orderId id of order
    /// @param pip at order
    /// @param size of order
    event LimitOrderUpdated(
        address pairManager,
        uint64 orderId,
        uint128 pip,
        uint256 size
    );

    /// @notice Emitted when order fill for swap
    /// @param sender address of trader
    /// @param amount0In amount 0 int
    /// @param amount1In amount 1 in
    /// @param amount0Out amount 0 out
    /// @param amount1Out amount 1 out
    /// @param to swap for address
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    /// @notice Update the order when partial fill
    /// @param pip the price of order
    /// @param orderId id of order in pip
    function updatePartialFilledOrder(uint128 pip, uint64 orderId) external;

    /// @notice Cancel the limit order
    /// @param pip the price of order
    /// @param orderId id of order in pip
    function cancelLimitOrder(
        uint128 pip,
        uint64 orderId
    ) external returns (uint256 remainingSize, uint256 partialFilled);

    /// @notice Open limit order with size and price
    /// @param pip the price of order
    /// @param baseAmountIn amount of base asset
    /// @param isBuy side of the limit order
    /// @param trader the owner of the limit order
    /// @param quoteAmountIn amount of quote asset
    /// @param feePercent fee of the order
    /// @dev Calculate the order in insert to queue
    /// @return orderId id of order in pip
    /// @return baseAmountFilled when can fill market amount has filled
    /// @return quoteAmountFilled when can fill market amount has filled
    /// @return fee when can fill market amount has filled
    function openLimit(
        uint128 pip,
        uint128 baseAmountIn,
        bool isBuy,
        address trader,
        uint256 quoteAmountIn,
        uint16 feePercent
    )
        external
        returns (
            uint64 orderId,
            uint256 baseAmountFilled,
            uint256 quoteAmountFilled,
            uint256 fee
        );

    /// @notice Open market order with size is base and price
    /// @param size the amount want to open market order
    /// @param isBuy the side of market order
    /// @param trader the owner of the market order
    /// @param feePercent fee of the order
    /// @dev Calculate full the market order with limit order in queue
    /// @return mainSideOut the amount fill of main asset
    /// @return flipSideOut the amount fill of main asset convert to flip asset
    /// @return fee the amount of fee
    function openMarket(
        uint256 size,
        bool isBuy,
        address trader,
        uint16 feePercent
    ) external returns (uint256 mainSideOut, uint256 flipSideOut, uint256 fee);

    /// @notice Open market order with size is base and price
    /// @param quoteAmount the quote amount want to open market order
    /// @param isBuy the side of market order
    /// @param trader the owner of the market order
    /// @param feePercent fee of the order
    /// @dev Calculate full the market order with limit order in queue
    /// @return mainSideOut the amount fill of main asset
    /// @return flipSideOut the amount fill of main asset convert to flip asset
    /// @return fee the amount of fee
    function openMarketWithQuoteAsset(
        uint256 quoteAmount,
        bool isBuy,
        address trader,
        uint16 feePercent
    ) external returns (uint256 mainSideOut, uint256 flipSideOut, uint256 fee);

    /// @notice check at this pip has liquidity
    /// @param pip the price of order
    /// @dev load and check flag of liquidity
    /// @return the bool of has liquidity
    function hasLiquidity(uint128 pip) external view returns (bool);

    /// @notice Get detail pending order
    /// @param pip the price of order
    /// @param orderId id of order in pip
    /// @dev Load pending order and calculate the amount of base and quote asset
    /// @return isFilled the order is filled
    /// @return isBuy the side of the order
    /// @return size the size of order
    /// @return partialFilled the amount partial order is filled
    function getPendingOrderDetail(
        uint128 pip,
        uint64 orderId
    )
        external
        view
        returns (
            bool isFilled,
            bool isBuy,
            uint256 size,
            uint256 partialFilled
        );

    /// @notice Get amount liquidity pending at current price
    /// @return the amount liquidity pending
    function getLiquidityInCurrentPip() external view returns (uint128);

    function getLiquidityInPipRange(
        uint128 fromPip,
        uint256 dataLength,
        bool toHigher
    ) external view returns (LiquidityOfEachPip[] memory, uint128);

    function calculatingQuoteAmount(
        uint256 quantity,
        uint128 pip
    ) external view returns (uint256);

    /// @notice Get basis point of pair
    /// @return the basis point of pair
    function basisPoint() external view returns (uint256);

    /// @notice Get current price
    /// @return return the current price
    function getCurrentPip() external view returns (uint128);

    /// @notice Calculate the amount of quote asset
    /// @param quoteAmount the quote amount
    /// @param pip the price
    /// @return the base converted
    function quoteToBase(
        uint256 quoteAmount,
        uint128 pip
    ) external view returns (uint256);
}