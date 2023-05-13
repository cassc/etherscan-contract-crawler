// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDHController {
    enum UserStatus {
        Ok,
        NoTier,
        NotEligiblePool
    }
    
    enum DistributionStatus {
        Ok,
        NoDate,
        PreRegistration,
        Registration,
        Claiming,
        Finished
    }

    struct UserDHState {
        // 0: all ok, 1: no level, 2: staking in non-eligible pool
        UserStatus status;
        bool isRegistered;
        bool isRetroEligible;
        // Does user have (DH25 || anyDH75) > 0?
        bool hasReward;
        uint256 userDH25Share;
        // Sale for DH75
        address[] sales;
        // User DH75 share for each sale
        uint256[] userDH75Shares;
    }

    struct Distribution {
        DistributionStatus status;
        // Unix timestamp
        uint256 start;
        // Unix timestamp
        uint256 registrationStart;
        // Unix timestamp
        uint256 end;
        address[] registrants;
        uint256 registrantsCount;
        mapping(address => bool) isRegistered;
        // Sum of registered AAG participants level multipliers
        uint256 totalDH25Share;
        // Sum of retrospective eligible AAG participants level multipliers
        uint256 totalDH25ShareRetro;
        // User -> DH25 share for the current distribution
        mapping(address => uint256) userDH25Share;
        // Total share for DH75, sum of all registered. Sale -> Share
        mapping(address => uint256) totalDH75Shares;
        // User -> Sale -> Share
        mapping(address => mapping(address => uint256)) userDH75Shares;
    }
    
    struct DistributionView {
        DistributionStatus status;
        uint256 idx;
        // Unix timestamp
        uint256 start;
        // Unix timestamp
        uint256 registrationStart;
        // Unix timestamp
        uint256 end;
        uint256 registrantsCount;
        // Sum of registered AAG participants level multipliers
        uint256 totalDH25Share;
        // Sum of retrospective eligible AAG participants level multipliers
        uint256 totalDH25ShareRetro;
        address[] sales;
        uint256[] totalDH75Shares;
        bool[] isRetroSale;
    }

    function getDistribution(uint256 distrIdx) external view returns (DistributionView memory);
    
    function getRegistrants(uint256 distrIdx) external view returns (address[] memory);

    function register() external;

    function getUserDHState(address account) external view returns (UserDHState memory);
}