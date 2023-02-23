import "./IPairManager.sol";
interface ISpotHouse {
    enum Side {
        BUY,
        SELL
    }
    function openLimitOrder(
        IPairManager _spotManager,
        Side _side,
        uint256 _quantity,
        uint128 _pip
    ) external payable;

    function openBuyLimitOrderExactInput(
        IPairManager pairManager,
        Side side,
        uint256 quantity,
        uint128 pip
    ) external payable;

    function openMarketOrder(
        IPairManager _spotManager,
        Side _side,
        uint256 _quantity
    ) external payable;

    function openMarketOrderWithQuote(
        IPairManager _pairManager,
        Side _side,
        uint256 _quoteAmount
    ) external payable;

    function cancelLimitOrder(
        IPairManager _spotManager,
        uint64 _orderIdx,
        uint128 _pip
    ) external;

    function claimAsset(IPairManager _spotManager) external;

    function getAmountClaimable(IPairManager _spotManager, address _trader)
    external
    view
    returns (
        uint256 quoteAsset,
        uint256 baseAsset
    //            uint256 feeQuoteAmount,
    //            uint256 feeBaseAmount
    );

    function cancelAllLimitOrder(IPairManager _spotManager) external;

    function setFactory(address _factoryAddress) external;

    function updateFee(uint16 _fee) external;

    function openMarketOrder(
        IPairManager _pairManager,
        Side _side,
        uint256 _quantity,
        address _payer,
        address _recipient
    ) external payable returns (uint256[] memory);

    function openMarketOrderWithQuote(
        IPairManager _pairManager,
        Side _side,
        uint256 _quoteAmount,
        address _payer,
        address _recipient
    ) external payable returns (uint256[] memory);
}