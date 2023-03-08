// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {LibDiamond} from "../../diamond/LibDiamond.sol";
import {LibBridge} from "../LibBridge.sol";
import {LibStargate} from "../LibStargate.sol";
import {LibWormhole} from "../LibWormhole.sol";
import {IBridge} from "../interfaces/IBridge.sol";
import {WormholeSettings, WormholeBridgeSettings, StargateSettings} from "../../libraries/LibMagpieAggregator.sol";

contract BridgeFacet is IBridge {
    function updateStargateSettings(StargateSettings calldata stargateSettings) external {
        LibDiamond.enforceIsContractOwner();
        LibStargate.updateSettings(stargateSettings);
    }

    function updateWormholeBridgeSettings(WormholeBridgeSettings calldata wormholeBridgeSettings) external {
        LibDiamond.enforceIsContractOwner();
        LibWormhole.updateSettings(wormholeBridgeSettings);
    }

    function sgReceive(
        uint16,
        bytes calldata,
        uint256,
        address assetAddress,
        uint256 amount,
        bytes calldata payload
    ) external override {
        LibStargate.enforce();
        LibStargate.sgReceive(assetAddress, amount, payload);
    }
}