// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/******************* Imports **********************/
import "./IERC721Mintable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

/// @author NoBorderz
/// @notice Globals and utilities for staking contract
abstract contract GlobalsAndUtils {
    

    /******************* Events **********************/
    event StakeStart(address staker, uint256 stakeIndex, uint256 tokenId, uint256[] geneTokenIds);
    event StakeEnd(address staker, uint256 stakeIndex, uint256 tokenId, uint256[] geneTokenIds);
    event AppliedUnstake(address staker, uint256 stakeIndex, uint256 tokenId, uint256[] geneTokenIds);
    event CampaignStarted(uint256 rewardCount, uint256 startTime, uint256 endTime);
    event CampaignEdited(uint256 startTime, uint256 endTime);
    event CampaignReward(uint256 campaignId, address collection, uint256 from, uint256 to, address user);
    event RuffleJoined(address user, uint256 campaignId, uint256 start, uint256 end);

    /******************* Modifiers **********************/
    modifier campaignEnded() {
        if (latestCampaignId > 0) {
            Campaign storage campaign = campaigns[latestCampaignId];
            require(campaign.endTime <= block.timestamp, "Campaign not ended yet");
        }
        _;
    }

    modifier CampaignOnGoing() {
        require(latestCampaignId > 0, "Campaign not initalized");
        Campaign memory campaign = campaigns[latestCampaignId];
        require(campaign.startTime <= block.timestamp, "campign not started");
        require(campaign.endTime > block.timestamp, "campign has ended");
        _;
    }

    modifier ClaimXTicketAllowed() {
        require(latestCampaignId > 0, "Campaign not initalized");
        Campaign memory campaign = campaigns[latestCampaignId];

        require(campaign.endTime + CLAIM_X_TICKET_DURATION >= block.timestamp, "claim ticket time ended");
        _;
    }
   

    modifier CalculateRewardAllowed() {
        require(latestCampaignId > 0, "Campaign not initalized");
        Campaign memory campaign = campaigns[latestCampaignId];

        require(campaign.endTime + CLAIM_X_TICKET_DURATION < block.timestamp, "claim x duration");
        _;
    }



    modifier onlyOracle() {
        require(msg.sender == oracle, "not allowed");
        _;
    }

    /******************* State Variables **********************/
    uint256 internal  MIN_STAKE_DAYS;
    uint256 internal  EARLY_UNSTAKE_PENALTY;
    uint256 internal  STAKING_TOKEN_DECIMALS;
    uint256 internal  CLAIM_X_TICKET_DURATION;
    uint256 internal  MIN_STAKE_TOKENS;
    address internal  LAND_ADDRESS;
    address internal  GENESIS_ADDRESS;

   

    /// @notice This struct stores information regarding campaigns
    struct Campaign {
        uint256 rewardCount;
        uint256 startTime;
        uint256 endTime;
        address collection;
    }

    /// @notice Array to store campaigns.
    mapping(uint256 => Campaign) internal campaigns;

    /// @notice Stores the ID of the latest campaign
    uint256 internal latestCampaignId;

    /// @notice Stores the current total number of claimable xtickets.
    uint256 internal totalClaimableTickets;

    /// @notice Mapping to store current total claimable tickets for a user
    mapping(address => mapping(uint256 => uint256)) internal totalUserXTickets;

    /// @notice Stores the Id of the latest stake.
    uint256 internal latestStakeId;

    /// @notice This struct stores information regarding a user stakes
    struct Stake {
        uint256 stakedAt;
        uint256 tokenId;
        address landCollection;
        uint256[] genesisTokenIds;
        uint256 size;
        string  rarity;
        uint256 xTickets;
    }

    /// @notice Mapping to store user stakes.
    mapping(address => mapping(uint256 => Stake)) internal stakes;

    /// @notice Array to store users with active stakes
    address[] internal activeStakeOwners;

    /// @notice Mapping to store user stake ids in array
    mapping(address => uint256[]) internal userStakeIds;

    /// @notice This struct stores information regarding a user unstakes
    struct UnStake {
        uint256 stakedAt;
        uint256 appliedAt;
        uint256 unStakedAt;
        uint256 tokenId;
        address landCollection;
        uint256[] genesisTokenIds;
        uint256 size;
        string  rarity;
        uint256 xTickets;
        bool isAppliedFor;
    }

    /// @notice Mapping to store user unstakes.
    mapping(address => mapping(uint256 => UnStake)) internal unStakes;

     /// @notice Mapping to store user unstake ids in array
    mapping(address => uint256[]) internal userUnStakeIds;


    /// @notice Mapping to store index of owner address in activeStakeOwners array
    mapping(address => uint256) internal stakeOwnerIndex;

    /// @notice Mapping to nftsIds user was awarded against a collection
    mapping(address => mapping(address => uint256[])) internal claimableAwards;

    /// @notice Mapping to store total number of awards received by a user
    mapping(address => mapping(uint256 => uint256)) internal rewardsReceived;

    /// @notice ERC721 Token for awarding users NFTs
    IERC721 internal rewardsToken;

    /// @notice array of winning tickets ids against campaing id
    mapping(uint256 => uint256[]) internal winningTicketIds;

    struct XTicketRange {
        uint256 start;
        uint256 end;
    }

    /// @notice mapping for xticket range for each user
    mapping(address => mapping(uint256 => XTicketRange)) public userXTicketRange;

     /// @notice Variable to store total amount currently staked in the contract
    uint256 public totalStakedAmount;

    /// @notice Mapping to store total amount staked of a user
    mapping(address => uint256) public userStakedAmount;

    /// @notice Variable to store total amount currently staked in the contract
    uint256 public totalStakedNFT;

    /// @notice Mapping to store total amount staked of a user
    mapping(address => uint256) public userStakedAmountNFT;


    /// @notice Mapping campaign id, ticket id
    mapping(uint256 => mapping (uint256=>bool)) public ticketIdUsed;

    /// @notice Mapping campaign id, ticket id
    mapping(uint256 => mapping (uint256=>bool)) public winningTixketIdExist;

    address internal oracle;

    uint256 public isRequested;

    mapping(uint256 => bool) public isRewardOpen;

    bytes32 internal landRootHash;

    mapping(string => mapping(uint256 => uint256 )) XticketEarnPerDay;

    mapping (uint256=> bytes32) public campaignRewardsRoot;
}