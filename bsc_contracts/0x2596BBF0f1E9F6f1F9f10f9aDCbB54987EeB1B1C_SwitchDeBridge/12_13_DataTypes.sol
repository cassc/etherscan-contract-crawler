// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
/**
 * @title DataTypes
 * @dev Definition of shared types
 */
library DataTypes {
    /// @notice Type for representing a swapping status type
    enum SwapStatus {
        Null,
        Succeeded,
        Failed,
        Fallback
    }

    enum DepositStatus {
        Null,
        Succeeded,
        Failed,
        Fallback
    }

    /// @notice Type for representing a paraswap usage status
    enum ParaswapUsageStatus {
        None,
        OnSrcChain,
        OnDestChain,
        Both
    }

    /// @notice Swap params
    struct SwapInfo {
        address srcToken;
        address dstToken;
    }
}