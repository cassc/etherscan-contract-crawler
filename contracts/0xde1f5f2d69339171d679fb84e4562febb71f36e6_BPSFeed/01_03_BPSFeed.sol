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

    // ================== Constants ==================
    uint256 internal constant INITIAL_RATE = 1e4;
    uint256 internal constant MAX_RATE = 1.5e4;

    constructor() Owned(msg.sender) {
        currentRate = INITIAL_RATE;
    }

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
        if (_rate < INITIAL_RATE || _rate > MAX_RATE) {
            revert InvalidRate();
        }
        if (lastTimestamp > 0) {
            uint256 lastRateDuration = block.timestamp - lastTimestamp;
            _totalRate += currentRate * lastRateDuration;
            _totalDuration += lastRateDuration;
        }

        currentRate = _rate;
        lastTimestamp = block.timestamp;

        emit UpdateRate(currentRate);
    }
}