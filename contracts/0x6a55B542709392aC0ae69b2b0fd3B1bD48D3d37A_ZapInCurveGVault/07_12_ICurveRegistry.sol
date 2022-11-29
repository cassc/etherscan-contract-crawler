interface ICurveRegistry {
    function getSwapAddress(address tokenAddress)
        external
        view
        returns (address swapAddress);

    function getTokenAddress(address swapAddress)
        external
        view
        returns (address tokenAddress);

    function getDepositAddress(address swapAddress)
        external
        view
        returns (address depositAddress);

    function getPoolTokens(address swapAddress)
        external
        view
        returns (address[4] memory poolTokens);

    function shouldAddUnderlying(address swapAddress)
        external
        view
        returns (bool);

    function getNumTokens(address swapAddress)
        external
        view
        returns (uint8 numTokens);

    function isBtcPool(address swapAddress) external view returns (bool);

    function isEthPool(address swapAddress) external view returns (bool);

    function isUnderlyingToken(
        address swapAddress,
        address tokenContractAddress
    ) external view returns (bool, uint8);
}