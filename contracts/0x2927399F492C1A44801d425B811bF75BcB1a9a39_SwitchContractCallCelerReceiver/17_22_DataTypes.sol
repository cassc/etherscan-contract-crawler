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

    enum ContractCallStatus {
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

    struct ContractCallInfo {
        address toContractAddress; // The address of the contract to interact with.
        address toApprovalAddress; // the approval address for contract call
        address contractOutputsToken; // Some contract interactions will output a token (e.g. staking)
        uint32 toContractGasLimit; // The estimated gas used by the destination call.
        bytes toContractCallData; // The callData to be sent to the contract for the interaction on the destination chain.
    }

    struct ContractCallRequest {
        bytes32 id;
        bytes32 bridge;
        address srcToken;
        address bridgeToken;
        address callToken;
        address recipient;
        uint256 srcAmount;
        uint256 bridgeDstAmount;
        uint256 estimatedCallAmount;
        uint256[] dstDistribution;
        bytes dstParaswapData;
        ContractCallInfo callInfo;
        ParaswapUsageStatus paraswapUsageStatus;
    }
}