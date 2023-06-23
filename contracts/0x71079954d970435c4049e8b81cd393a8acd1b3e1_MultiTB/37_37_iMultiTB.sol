// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface iMultiTB {
    /// @notice Store params for swap to token accepted by bidge
    /// @param swapper Address of swapper contract(e.g. 1inch router)
    /// @param token Input token
    /// @param amount Amount of tokens to be swapped
    /// @param swapCallData Calldata that will be send to swapper. swapper.call(swapCallData)
    struct SwapData {
        address swapper;
        address token;
        uint256 amount;
        bytes swapCallData;
    }

    /// @notice Store params for execution on destination chain
    /// @param approveTarget Contract address for which approve will be given(for TB, approve should be given for TBProxy)
    /// @param target Address of contract to be called on destination chain
    /// @param account Address of user, to which token will be transfred
    /// @param finalToken Address of token, that user will get
    /// @param refule True if refule(swap some coins to token of dist chain) needed
    /// @param refuleAmount Amount of tokens on destination chain, that will be swapped to coins
    /// @param minEthOut Minimum amount of eth, that user should get.
    /// @param chunks Chunks of calldata from which tb callData will be formed. callData = chunks.join(tokenAmount)
    struct CallDataParam {
        address approveTarget; // For the case of tb, where approve should be given to PipelineProxy.
        address target;
        address account;
        address finalToken;
        bool refule; // Swap some user token to coins on destination chain
        uint256 refuleAmount;
        uint256 minEthOut;
        bytes[] chunks;
    }

    function decodeAndRun(
        bytes32 transferId,
        uint256 amount,
        address asset,
        address originSender,
        uint32 origin,
        bytes memory callData
    ) external;

    function run(
        uint256 amount,
        address asset,
        CallDataParam memory params
    ) external;
}