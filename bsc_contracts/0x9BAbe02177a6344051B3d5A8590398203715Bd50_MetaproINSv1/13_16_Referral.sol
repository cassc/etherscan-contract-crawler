//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Define the struct in the SharedStruct contract
contract Referral {
    struct ReferralFees {
        // @dev: Level 1 referral fee - integer value - example: 1000 -> 10%
        uint256 level1ReferrerFee;
        // @dev: Level 1 referral fee - integer value - example: 1000 -> 10%
        uint256 level2ReferrerFee;
        // @dev: Level 1 referral fee - integer value - example: 1000 -> 10%
        uint256 level3ReferrerFee;
    }
}

//  referral
interface MetaproReferral {
    function saveReferralDeposit(
        address _referrer,
        address _contractAddress,
        uint256 _auctionId,
        uint256 _tokenId,
        address _depositer,
        uint256 _level,
        uint256 _provision
    ) external;

    function setReferral(address _referred, address _referrer) external;

    function getReferral(address _referred) external view returns (address);
}