// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBondLogo {
    struct LogoInfos {
        uint256 tokenId;
        uint256 termTimestamp;
        uint256 pending;
        uint256 cvgClaimable;
        uint256 unlockingTimestamp;
    }
    struct LogoInfosFull {
        uint256 tokenId;
        uint256 termTimestamp;
        uint256 pending;
        uint256 cvgClaimable;
        uint256 unlockingTimestamp;
        uint256 year;
        uint256 month;
        uint256 day;
        uint256 hoursLock;
        uint256 cvgPrice;
    }

    function _tokenURI(LogoInfos memory logoInfos) external pure returns (string memory output);
}