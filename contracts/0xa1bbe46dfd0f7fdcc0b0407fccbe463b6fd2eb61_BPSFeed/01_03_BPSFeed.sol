// SPDX-License-Identifier: BUSL-1.1
/*
██████╗░██╗░░░░░░█████╗░░█████╗░███╗░░░███╗
██╔══██╗██║░░░░░██╔══██╗██╔══██╗████╗░████║
██████╦╝██║░░░░░██║░░██║██║░░██║██╔████╔██║
██╔══██╗██║░░░░░██║░░██║██║░░██║██║╚██╔╝██║
██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚═╝░██║
╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░░░░╚═╝
*/

pragma solidity 0.8.19;

import {Owned} from "solmate/auth/Owned.sol";
import {IBPSFeed} from "./interfaces/IBPSFeed.sol";

contract BPSFeed is IBPSFeed, Owned {
    // =================== Storage ===================

    uint256 public currentRate;
    uint256 public lastTimestamp;
    uint256 internal _totalRate;
    uint256 internal _totalDuration;

    constructor() Owned(msg.sender) {}

    /// @inheritdoc IBPSFeed
    function getWeightedRate() external view returns (uint256) {
        if (lastTimestamp == 0) return 0;

        uint256 lastRateDuration = block.timestamp - lastTimestamp;
        uint256 totalRate = _totalRate + currentRate * lastRateDuration;
        uint256 totalDuration = _totalDuration + lastRateDuration;
        return totalDuration == 0 ? 0 : totalRate / totalDuration;
    }

    /// @inheritdoc IBPSFeed
    function updateRate(uint256 _rate) external onlyOwner {
        if (lastTimestamp > 0) {
            uint256 lastRateDuration = block.timestamp - lastTimestamp;
            _totalRate += currentRate * lastRateDuration;
            _totalDuration += lastRateDuration;
        }
        currentRate = _rate;
        lastTimestamp = block.timestamp;
    }
}