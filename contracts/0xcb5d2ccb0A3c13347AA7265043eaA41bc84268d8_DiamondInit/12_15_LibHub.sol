// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";
import {LibCurve} from "./LibCurve.sol";

struct HubInfo {
    uint256 startTime;
    uint256 endTime;
    uint256 endCooldown;
    uint256 refundRatio;
    uint256 targetRefundRatio;
    address owner;
    address vault;
    address asset;
    bool updating;
    bool reconfigure;
    bool active;
}

library LibHub {
    event FinishUpdate(uint256 id);

    function finishUpdate(uint256 id) internal {
        HubInfo storage hubInfo = LibAppStorage.diamondStorage().hubs[id];

        require(hubInfo.updating, "Not updating");
        require(block.timestamp > hubInfo.endTime, "Still updating");

        if (hubInfo.targetRefundRatio != 0) {
            hubInfo.refundRatio = hubInfo.targetRefundRatio;
            hubInfo.targetRefundRatio = 0;
        }

        if (hubInfo.reconfigure) {
            LibCurve.finishReconfigure(id);
            hubInfo.reconfigure = false;
        }

        hubInfo.updating = false;
        hubInfo.startTime = 0;
        hubInfo.endTime = 0;

        emit FinishUpdate(id);
    }

    function getHubInfo(uint256 id)
        internal
        view
        returns (HubInfo memory hubInfo)
    {
        HubInfo storage sHubInfo = LibAppStorage.diamondStorage().hubs[id];
        hubInfo.active = sHubInfo.active;
        hubInfo.owner = sHubInfo.owner;
        hubInfo.vault = sHubInfo.vault;
        hubInfo.asset = sHubInfo.asset;
        hubInfo.refundRatio = sHubInfo.refundRatio;
        hubInfo.updating = sHubInfo.updating;
        hubInfo.startTime = sHubInfo.startTime;
        hubInfo.endTime = sHubInfo.endTime;
        hubInfo.endCooldown = sHubInfo.endCooldown;
        hubInfo.reconfigure = sHubInfo.reconfigure;
        hubInfo.targetRefundRatio = sHubInfo.targetRefundRatio;
    }

    function count() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.hubCount;
    }

    function warmup() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.hubWarmup;
    }

    function duration() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.hubDuration;
    }

    function cooldown() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.hubCooldown;
    }
}