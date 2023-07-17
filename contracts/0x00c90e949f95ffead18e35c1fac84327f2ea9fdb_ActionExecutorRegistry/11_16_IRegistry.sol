// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ISettings } from './ISettings.sol';

interface IRegistry is ISettings {
    /**
     * @notice Getter of the registered gateway flag by the account address
     * @param _account The account address
     * @return The registered gateway flag
     */
    function isGatewayAddress(address _account) external view returns (bool);

    /**
     * @notice Settings for a single-chain swap
     * @param _caller The user's account address
     * @param _routerType The type of the swap router
     * @return Settings for a single-chain swap
     */
    function localSettings(
        address _caller,
        uint256 _routerType
    ) external view returns (LocalSettings memory);

    /**
     * @notice Getter of source chain settings for a cross-chain swap
     * @param _caller The user's account address
     * @param _targetChainId The target chain ID
     * @param _gatewayType The type of the cross-chain gateway
     * @param _routerType The type of the swap router
     * @param _vaultType The type of the vault
     * @return Source chain settings for a cross-chain swap
     */
    function sourceSettings(
        address _caller,
        uint256 _targetChainId,
        uint256 _gatewayType,
        uint256 _routerType,
        uint256 _vaultType
    ) external view returns (SourceSettings memory);

    /**
     * @notice Getter of target chain settings for a cross-chain swap
     * @param _vaultType The type of the vault
     * @param _routerType The type of the swap router
     * @return Target chain settings for a cross-chain swap
     */
    function targetSettings(
        uint256 _vaultType,
        uint256 _routerType
    ) external view returns (TargetSettings memory);

    /**
     * @notice Getter of variable balance repayment settings
     * @param _vaultType The type of the vault
     * @return Variable balance repayment settings
     */
    function variableBalanceRepaymentSettings(
        uint256 _vaultType
    ) external view returns (VariableBalanceRepaymentSettings memory);

    /**
     * @notice Getter of cross-chain message fee estimation settings
     * @param _gatewayType The type of the cross-chain gateway
     * @return Cross-chain message fee estimation settings
     */
    function messageFeeEstimateSettings(
        uint256 _gatewayType
    ) external view returns (MessageFeeEstimateSettings memory);

    /**
     * @notice Getter of swap result calculation settings for a single-chain swap
     * @param _caller The user's account address
     * @return Swap result calculation settings for a single-chain swap
     */
    function localAmountCalculationSettings(
        address _caller
    ) external view returns (LocalAmountCalculationSettings memory);

    /**
     * @notice Getter of swap result calculation settings for a cross-chain swap
     * @param _caller The user's account address
     * @param _vaultType The type of the vault
     * @param _fromChainId The ID of the swap source chain
     * @param _toChainId The ID of the swap target chain
     * @return Swap result calculation settings for a cross-chain swap
     */
    function vaultAmountCalculationSettings(
        address _caller,
        uint256 _vaultType,
        uint256 _fromChainId,
        uint256 _toChainId
    ) external view returns (VaultAmountCalculationSettings memory);

    /**
     * @notice Getter of amount limits in USD for cross-chain swaps
     * @param _vaultType The type of the vault
     * @return min Minimum cross-chain swap amount in USD, with decimals = 18
     * @return max Maximum cross-chain swap amount in USD, with decimals = 18
     */
    function swapAmountLimits(uint256 _vaultType) external view returns (uint256 min, uint256 max);
}