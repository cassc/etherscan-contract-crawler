pragma solidity ^0.8.10;

interface IStaking {

    ////////////////////
    ////// Events //////
    ////////////////////

    /// @notice Emited a staker changes who they're delegating to
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    /// @notice Emited when staking is paused/unpaused
    event StakingPause(bool status);
    /// @notice Emited when admins change the token's base URI
    event BaseURIChanged(string _baseURI);
    /// @notice Emited when the contract URI is updated
    event ContractURIChanged(string _contractURI);
    /// @notice Emited when refund settings are updated
    event RefundSettingsChanged(bool _stakingRefund, bool _delegatingRefund, uint256 _newCooldown);
    /// @notice Emited when FrankenMonster voting multiplier is changed
    event MonsterMultiplierChanged(uint256 _monsterMultiplier);
    /// @notice Emited when the voting multiplier for passed proposals is changed
    event ProposalPassedMultiplierChanged(uint64 _proposalPassedMultiplier);
    /// @notice Emited when the stake time multiplier is changed
    event StakeTimeChanged(uint128 _stakeTime);
    /// @notice Emited when the staking multiplier is changed
    event StakeAmountChanged(uint128 _stakeAmount);
    /// @notice Emited when the voting multiplier for voting is changed
    event VotesMultiplierChanged(uint64 _votesMultiplier);
    /// @notice Emited when the voting multiplier for creating proposals is changed
    event ProposalsCreatedMultiplierChanged(uint64 _proposalsCreatedMultiplier);
    /// @notice Emited when the base votes for a token is changed
    event BaseVotesChanged(uint256 _baseVotes);

    /////////////////////
    ////// Storage //////
    /////////////////////

    struct CommunityPowerMultipliers {
        uint64 votes;
        uint64 proposalsCreated;
        uint64 proposalsPassed;
    }

    struct StakingSettings {
        uint128 maxStakeBonusTime;
        uint128 maxStakeBonusAmount;
    }

    enum RefundStatus { 
        StakingAndDelegatingRefund,
        StakingRefund, 
        DelegatingRefund, 
        NoRefunds
    }

    /////////////////////
    ////// Methods //////
    /////////////////////

    function baseTokenURI() external view returns (string memory);
    function BASE_VOTES() external view returns (uint256);
    function changeStakeAmount(uint128 _newMaxStakeBonusAmount) external;
    function changeStakeTime(uint128 _newMaxStakeBonusTime) external;
    function communityPowerMultipliers()
        external
        view
        returns (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed);
    function delegate(address _delegatee) external;
    function delegatingRefund() external view returns (bool);
    function evilBonus(uint256 _tokenId) external view returns (uint256);
    function getCommunityVotingPower(address _voter) external view returns (uint256);
    function getDelegate(address _delegator) external view returns (address);
    function getStakedTokenSupplies() external view returns (uint128, uint128);
    function getTokenVotingPower(uint256 _tokenId) external view returns (uint256);
    function getTotalVotingPower() external view returns (uint256);
    function getVotes(address _account) external view returns (uint256);
    function isFrankenPunksStakingContract() external pure returns (bool);
    function lastDelegatingRefund(address) external view returns (uint256);
    function lastStakingRefund(address) external view returns (uint256);
    function paused() external view returns (bool);
    function setBaseURI(string memory _baseURI) external;
    function setPause(bool _paused) external;
    function setProposalsCreatedMultiplier(uint64 _proposalsCreatedMultiplier) external;
    function setProposalsPassedMultiplier(uint64 _proposalsPassedMultiplier) external;
    function setRefunds(bool _stakingRefund, bool _delegatingRefund, uint256 _newCooldown) external;
    function setVotesMultiplier(uint64 _votesmultiplier) external;
    function stake(uint256[] memory _tokenIds, uint256 _unlockTime) external;
    function stakedFrankenMonsters() external view returns (uint128);
    function stakedFrankenPunks() external view returns (uint128);
    function stakingRefund() external view returns (bool);
    function stakingSettings() external view returns (uint128 maxStakeBonusTime, uint128 maxStakeBonusAmount);
    function tokenVotingPower(address) external view returns (uint256);
    function unlockTime(uint256) external view returns (uint256);
    function unstake(uint256[] memory _tokenIds, address _to) external;
    function votesFromOwnedTokens(address) external view returns (uint256);
}