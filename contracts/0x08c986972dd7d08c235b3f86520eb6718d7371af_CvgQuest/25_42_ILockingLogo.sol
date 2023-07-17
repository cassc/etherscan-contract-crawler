// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILockingLogo {
    struct LogoInfos {
        uint256 tokenId;
        uint256 cvgLocked;
        uint256 lockEnd;
        uint256 ysPercentage;
        uint256 mgCvg;
        uint256 unlockingTimestamp;
    }
    struct GaugePosition {
        uint256 ysWidth; // width of the YS gauge part
        uint256 veWidth; // width of the VE gauge part
    }

    struct LogoInfosFull {
        uint256 tokenId;
        uint256 cvgLocked;
        uint256 lockEnd;
        uint256 ysPercentage;
        uint256 mgCvg;
        uint256 unlockingTimestamp;
        uint256 cvgLockedInUsd;
        uint256 ysCvg;
        uint256 veCvg;
        GaugePosition gaugePosition;
        uint256 claimableInUsd;
        uint256 hoursLock;
    }

    function _tokenURI(LogoInfos memory logoInfos) external pure returns (string memory output);
}