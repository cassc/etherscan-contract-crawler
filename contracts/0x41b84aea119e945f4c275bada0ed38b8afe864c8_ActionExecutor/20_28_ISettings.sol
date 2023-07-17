// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title ISettings
 * @notice Settings data structure declarations
 */
interface ISettings {
    /**
     * @notice Settings for a single-chain swap
     * @param router The swap router contract address
     * @param routerTransfer The swap router transfer contract address
     * @param systemFeeLocal The system fee value in milli-percent, e.g., 100 is 0.1%
     * @param feeCollectorLocal The address of the single-chain action fee collector
     * @param isWhitelist The whitelist flag
     */
    struct LocalSettings {
        address router;
        address routerTransfer;
        uint256 systemFeeLocal;
        address feeCollectorLocal;
        bool isWhitelist;
    }

    /**
     * @notice Source chain settings for a cross-chain swap
     * @param gateway The cross-chain gateway contract address
     * @param router The swap router contract address
     * @param routerTransfer The swap router transfer contract address
     * @param vault The vault contract address
     * @param sourceVaultDecimals The value of the vault decimals on the source chain
     * @param targetVaultDecimals The value of the vault decimals on the target chain
     * @param systemFee The system fee value in milli-percent, e.g., 100 is 0.1%
     * @param feeCollector The address of the cross-chain action fee collector
     * @param isWhitelist The whitelist flag
     * @param swapAmountMin The minimum cross-chain swap amount in USD, with decimals = 18
     * @param swapAmountMax The maximum cross-chain swap amount in USD, with decimals = 18
     */
    struct SourceSettings {
        address gateway;
        address router;
        address routerTransfer;
        address vault;
        uint256 sourceVaultDecimals;
        uint256 targetVaultDecimals;
        uint256 systemFee;
        address feeCollector;
        bool isWhitelist;
        uint256 swapAmountMin;
        uint256 swapAmountMax;
    }

    /**
     * @notice Target chain settings for a cross-chain swap
     * @param router The swap router contract address
     * @param routerTransfer The swap router transfer contract address
     * @param vault The vault contract address
     * @param gasReserve The target chain gas reserve value
     */
    struct TargetSettings {
        address router;
        address routerTransfer;
        address vault;
        uint256 gasReserve;
    }

    /**
     * @notice Variable balance repayment settings
     * @param vault The vault contract address
     */
    struct VariableBalanceRepaymentSettings {
        address vault;
    }

    /**
     * @notice Cross-chain message fee estimation settings
     * @param gateway The cross-chain gateway contract address
     */
    struct MessageFeeEstimateSettings {
        address gateway;
    }

    /**
     * @notice Swap result calculation settings for a single-chain swap
     * @param systemFee The system fee value in milli-percent, e.g., 100 is 0.1%
     * @param isWhitelist The whitelist flag
     */
    struct LocalAmountCalculationSettings {
        uint256 systemFeeLocal;
        bool isWhitelist;
    }

    /**
     * @notice Swap result calculation settings for a cross-chain swap
     * @param fromDecimals The value of the vault decimals on the source chain
     * @param toDecimals The value of the vault decimals on the target chain
     * @param systemFee The system fee value in milli-percent, e.g., 100 is 0.1%
     * @param isWhitelist The whitelist flag
     */
    struct VaultAmountCalculationSettings {
        uint256 fromDecimals;
        uint256 toDecimals;
        uint256 systemFee;
        bool isWhitelist;
    }
}