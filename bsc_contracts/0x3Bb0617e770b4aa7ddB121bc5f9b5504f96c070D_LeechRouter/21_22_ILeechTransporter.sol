// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILeechTransporter {
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
}