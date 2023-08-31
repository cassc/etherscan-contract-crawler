// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IDividendsPairStaking {
    enum Faction {
        DOG,
        FROG
    }

    struct Staker {
        uint256 totalAmount;
        uint256 frogFactionAmount;
        uint256 dogFactionAmount;
        uint256 previousDividendsPerFrog;
        uint256 previousDividendsPerDog;
        uint256 lockingEndDate;
    }

    struct SoupCycle {
        uint256 timestamp;
        Faction soupedUp;
        uint256 totalFrogWins;
    }

    event StakeAdded(address indexed staker, uint256 amount, Faction faction);
    event StakeRemoved(address indexed staker, uint256 amount, Faction faction);
    event VoteSwapped(address indexed staker, uint256 amount, Faction faction);
    event DividendsPerShareUpdated(uint256 dividendsPerFrog, uint256 dividendsPerDog);
    event DividendsEarned(address indexed staker, uint256 amount);
    event SoupCycled(uint256 indexed soupIndex, Faction soupedUp);
    event SoupCycleDurationUpdated(uint256 soupCycleDuration);

    function stakers(address staker) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);
    function currentSoupIndex() external view returns (uint256);
    function addStake(Faction faction, uint256 tokenAmountOutMin) external payable;
    function removeStake(uint256 amount, Faction faction) external;
    function vote(uint256 amount, Faction faction) external;
    function claim() external;
    function deposit(uint256 amount) external;
    function cycleSoup() external;
    function getSoup(uint256 previousSoupIndex)
        external
        view
        returns (uint256, uint256, SoupCycle memory, SoupCycle memory);
    function nextSoupCycle() external view returns (uint256);
    function getSoupedUp() external view returns (Faction);
    function setSoupCycleDuration(uint256 _soupCycleDuration) external;
    function withdrawMucus() external;
    function withdrawEth() external;
}