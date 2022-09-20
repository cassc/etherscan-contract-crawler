// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVotingContract {
    /**
     * send as array to external method instead two arrays with same length  [names[], values[]]
     */
    struct VoterData {
        string name;
        uint256 value;
    }
    
    struct CommunitySettings {
        uint8 communityRole;
        uint256 communityFraction;
        uint256 communityMinimum;
    }
    struct Vote {
        string voteTitle;
        uint256 startBlock;
        uint256 endBlock;
        uint256 voteWindowBlocks;
        address contractAddress;
        address communityAddress;
        CommunitySettings[] communitySettings;
        mapping(uint8 => uint256) communityRolesWeight;
    }
    
    struct Voter {
        address contractAddress;
        string contractMethodName;
        VoterData[] voterData;
        bool alreadyVoted;
    }
    
    struct InitSettings {
        string voteTitle;
        uint256 blockNumberStart;
        uint256 blockNumberEnd;
        uint256 voteWindowBlocks;
    }

    function init(
        InitSettings memory initSettings,
        address contractAddress,
        address communityAddress,
        CommunitySettings[] memory communitySettings,
        address releaseManager,
        address costManager,
        address producedBy
    ) external;
}