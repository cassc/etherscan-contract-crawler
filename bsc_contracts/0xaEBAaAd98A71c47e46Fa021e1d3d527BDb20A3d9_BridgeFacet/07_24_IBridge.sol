// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {StargateSettings, WormholeBridgeSettings} from "../../libraries/LibMagpieAggregator.sol";

interface IBridge {
    event UpdateStargateSettings(address indexed sender, StargateSettings stargateSettings);

    function updateStargateSettings(StargateSettings calldata stargateSettings) external;

    event UpdateWormholeBridgeSettings(address indexed sender, WormholeBridgeSettings wormholeBridgeSettings);

    function updateWormholeBridgeSettings(WormholeBridgeSettings calldata wormholeBridgeSettings) external;

    function sgReceive(
        uint16 senderChainId,
        bytes calldata stargateBridgeAddress,
        uint256 nonce,
        address assetAddress,
        uint256 amount,
        bytes calldata payload
    ) external;
}