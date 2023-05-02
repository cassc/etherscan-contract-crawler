// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface IMagpieStargateBridge {
    struct Settings {
        address aggregatorAddress;
        address routerAddress;
    }

    function updateSettings(Settings calldata _settings) external;

    struct WithdrawArgs {
        uint16 srcChainId;
        uint16 networkId;
        uint64 tokenSequence;
        uint256 nonce;
        bytes32 senderAddress;
        address assetAddress;
        bytes srcAddress;
    }

    function withdraw(WithdrawArgs calldata withdrawArgs) external returns (uint256 amountOut);

    function sgReceive(
        uint16,
        bytes calldata,
        uint256,
        address assetAddress,
        uint256 amount,
        bytes calldata payload
    ) external;
}