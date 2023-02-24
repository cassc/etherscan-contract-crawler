interface ILeechTransporter {
    /**
     * @notice This function requires that `leechSwapper` is properly initialized
     * The function first converts `amount` to base token on the target chain
     * The `amount` is then bridged to routerAddress on chain with id `destinationChainId`
     * The `AssetBridged` event is emitted after the bridging is successful
     *
     * @param destinationChainId The ID of the destination chain to send to
     * @param routerAddress The address of the router on the destination chain
     * @param amount The amount of asset to send
     */
    function sendTo(
        uint256 destinationChainId,
        address routerAddress,
        uint256 amount
    ) external;

    /**
     * @notice This function requires that `leechSwapper` is properly initialized
     * @param _destinationToken Address of the asset to be bridged
     * @param _bridgedAmount The amount of asset to send The ID of the destination chain to send to
     * @param _destinationChainId The ID of the destination chain to send to The address of the router on the destination chain
     * @param _destAddress The address on the destination chain
     */
    function bridgeOut(
        address _destinationToken,
        uint256 _bridgedAmount,
        uint256 _destinationChainId,
        address _destAddress
    ) external;

    /// @notice Emitted after successful bridging
    /// @param chainId Destination chain id
    /// @param routerAddress Destanation router address
    /// @param amount Amount of the underlying token
    event AssetBridged(uint256 chainId, address routerAddress, uint256 amount);

    /// @notice Emitted after initializing router
    /// @param anyswapV4Router address of v4 multichain router
    /// @param anyswapV6Router address of v6 multichain router
    /// @param multichainV7Router address of v7 multichain router
    /// @param leechSwapper address of the leechSwapper contract
    event Initialized(
        address anyswapV4Router,
        address anyswapV6Router,
        address multichainV7Router,
        address leechSwapper
    );
}