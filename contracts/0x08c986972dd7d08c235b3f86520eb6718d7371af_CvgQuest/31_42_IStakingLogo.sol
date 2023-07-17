// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakingLogo {
    struct LogoInfos {
        uint256 tokenId;
        string symbol;
        uint256 pending;
        uint256 totalStaked;
        uint256 cvgClaimable;
        uint256[] tokeClaimable;
        uint256 unlockingTimestamp;
    }

    struct LogoInfosFull {
        uint256 tokenId;
        string symbol;
        uint256 pending;
        uint256 totalStaked;
        uint256 cvgClaimable;
        uint256[] tokeClaimable;
        uint256 unlockingTimestamp;
        uint256 claimableInUsd;
        uint256 hoursLock;
    }

    function _tokenURI(LogoInfos memory logoInfos) external pure returns (string memory output);
}