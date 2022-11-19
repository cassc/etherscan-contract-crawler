// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title An interface to RangoAcross.sol contract to improve type hinting
/// @author Uchiha Sasuke
interface IRangoAcross {
    /// @notice The request object for Across bridge call
    /// @param spokePoolAddress The address of Across spoke pool that deposit should be done to
    /// @param recipient Address to receive funds at on destination chain.
    /// @param originToken Token to lock into this contract to initiate deposit.
    /// @param destinationChainId Denotes network where user will receive funds from SpokePool by a relayer.
    /// @param relayerFeePct % of deposit amount taken out to incentivize a fast relayer.
    /// @param quoteTimestamp Timestamp used by relayers to compute this deposit's realizedLPFeePct which is paid to LP pool on HubPool.
    struct AcrossBridgeRequest {
        address spokePoolAddress;
        address recipient;
        address originToken;
        uint256 destinationChainId;
        uint64 relayerFeePct;
        uint32 quoteTimestamp;
    }

    /// @notice Executes an Across bridge call
    /// @param fromToken The erc20 address of the input token, 0x000...00 for native token
    /// @param amount Amount of tokens to deposit. Will be amount of tokens to receive less fees.
    /// @param request The other required fields for across bridge contract
    function acrossBridge(address fromToken, uint256 amount, AcrossBridgeRequest memory request) external payable;
}