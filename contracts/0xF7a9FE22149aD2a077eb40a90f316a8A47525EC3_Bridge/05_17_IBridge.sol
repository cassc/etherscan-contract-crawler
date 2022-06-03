// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IBridge {
    function bridgeFeeRate() external view returns (uint256);
    function bridgeFeeCollector() external view returns (address);

    function bridgeOut(
        address fromAssetHash,
        uint64 toChainId,
        bytes memory toAddress,
        uint256 amount,
        bytes memory callData
    ) external returns(bool);

    function depositAndBridgeOut(
        address originalTokenAddress,
        address pTokenAddress,
        uint64 toChainId,
        bytes memory toAddress,
        uint256 amount,
        bytes memory callData
    ) external returns(bool);

    function bridgeOutAndWithdraw(
        address pTokenAddress,
        uint64 toChainId,
        bytes memory toAddress,
        uint256 amount
    ) external returns(bool);
}