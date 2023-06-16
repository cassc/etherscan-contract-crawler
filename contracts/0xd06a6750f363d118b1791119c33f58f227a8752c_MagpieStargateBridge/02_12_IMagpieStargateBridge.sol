// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {TransferKey} from "../libraries/LibTransferKey.sol";

interface IMagpieStargateBridge {
    struct Settings {
        address aggregatorAddress;
        address routerAddress;
    }

    function updateSettings(Settings calldata _settings) external;

    struct WithdrawArgs {
        uint16 srcChainId;
        uint256 nonce;
        address assetAddress;
        bytes srcAddress;
        TransferKey transferKey;
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