// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;


/// @title An interface to RangoSynapse.sol contract to improve type hinting
/// @author Rango DeXter
interface IRangoSynapse {

    enum SynapseBridgeType {
        SWAP_AND_REDEEM,
        SWAP_ETH_AND_REDEEM,
        SWAP_AND_REDEEM_AND_SWAP,
        SWAP_AND_REDEEM_AND_REMOVE,
        REDEEM,
        REDEEM_AND_SWAP,
        REDEEM_AND_REMOVE,
        DEPOSIT,
        DEPOSIT_ETH,
        DEPOSIT_AND_SWAP,
        DEPOSIT_ETH_AND_SWAP,
        ZAP_AND_DEPOSIT,
        ZAP_AND_DEPOSIT_AND_SWAP
    }

    /// @notice The request object for Synapse bridge call
    struct SynapseBridgeRequest {
        SynapseBridgeType bridgeType;
        address router;
        address to;
        uint256 chainId;
        address token;
        uint8 tokenIndexFrom;
        uint8 tokenIndexTo;
        uint256 minDy;
        uint256 deadline;
        uint8 swapTokenIndexFrom;
        uint8 swapTokenIndexTo;
        uint256 swapMinDy;
        uint256 swapDeadline;
        uint256[] liquidityAmounts;
    }

    event SynapseBridgeEvent(
        address inputToken,
        uint inputAmount,
        SynapseBridgeType bridgeType,
        address to,
        uint256 chainId,
        address token
    );

    event SynapseBridgeDetailEvent(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 minDy,
        uint256 deadline,
        uint8 swapTokenIndexFrom,
        uint8 swapTokenIndexTo,
        uint256 swapMinDy,
        uint256 swapDeadline
    );

    /// @notice Executes a Synapse bridge call
    /// @param inputToken The address of bridging token
    /// @param inputAmount The amount of the token to be bridged
    /// @param request required data for bridge
    function synapseBridge(
        address inputToken,
        uint inputAmount,
        SynapseBridgeRequest memory request
    ) external payable;

}