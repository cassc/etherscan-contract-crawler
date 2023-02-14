interface IAnyswapRouter {
    function anySwapOut(
        address token,
        address to,
        uint amount,
        uint toChainID
    ) external;

    function anySwapOutUnderlying(
        address token,
        address to,
        uint amount,
        uint toChainID
    ) external;
}