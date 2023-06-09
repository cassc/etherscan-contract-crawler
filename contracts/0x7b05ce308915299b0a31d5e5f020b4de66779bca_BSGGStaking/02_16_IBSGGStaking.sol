// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IBSGGStaking {
    struct Ticket {
        uint128 id;
        uint32 ticketType;
        uint16 seasonId;
        uint mintTimestamp;
        uint lockedToTimestamp;
        uint amountLocked;
        uint amountToGain;
    }

    struct Season {
        uint startTime;
        uint BSGGAllocation;
        uint BSGGAllTimeAllocation;
        uint BSGGTotalTokensLocked;
    }

    struct TicketType {
        uint32 id;
        bool active;
        uint128 minLockAmount;
        uint32 lockDuration;
        uint32 gainMultiplier;
        Season[] seasons;
        uint APR;
    }

    struct AccountSet {
        Ticket[] accountTickets;
        uint allocatedBSGG;
        uint pendingBSGGEarning;
    }

    event TicketTypeAdded(uint32 ticketTypeId);
    event TicketTypeUpdated(uint32 ticketTypeId);
    event TicketBought(address owner, uint ticketId, uint stakeAmount, uint gainAmount, uint lockDuration);
    event TicketRedeemed(address owner, uint ticketId);
    event AllocatedNewBSGG(uint amount, uint ticketTypeId);
    event EmergencyModeEnabled();
    event PrivilegedMode(bool status);
    event Paused(bool status);
    event MinMaxLimitChanged(uint minAmount, uint maxAmount, bool status);


    function allocateBSGG(uint _amount, uint _ticketTypeId) external returns(bool);
    function addTicketType(uint128 _minLockAmount, uint32 _lockDuration, uint32 _gainMultiplier, uint16 _seasons) external returns(bool);
    function updateTicketType(uint32 _id, uint128 _minLockAmount, uint32 _lockDuration,uint32 _gainMultiplier) external returns(bool);
    function deactivateTicketType(uint32 _ticketTypeId) external returns(bool);
    function activateTicketType(uint32 _ticketTypeId) external returns(bool);
    function buyTicket(uint _amount, uint32 _ticketTypeId, address _to) external returns(bool);
    function redeemTicket(uint _ticketId) external returns(bool);  
    function getPendingTokens(uint _ticketId) external view returns (uint, uint);
    function getPendingRewards(uint _ticketId) external view returns (uint);
    function getAccountInfo(address _account) external view returns(AccountSet memory);
    function getTicketTypes() external view returns(TicketType[] memory);
    function getTVL() external view returns(uint);
    function getActiveStaked(uint _ticketTypeId, address _account) external view returns (uint);
    function triggerEmergency(uint code) external returns(bool);
    function enablePrivilegedMode() external returns(bool);
    function disablePrivilegedMode() external returns(bool);
    function addPrivilegedAccounts(address[] memory _accounts) external returns(bool);
    function removePrivilegedAccounts(address[] memory _accounts) external returns(bool);
    function redeemTicketEmergency(uint _ticketId) external returns(bool);
    function maxAllocationSeason(uint _ticketTypeId) external view returns (uint256);
    function currentSeasonId(uint _ticketTypeId) external view returns (uint16);
    function withdrawNonReservedBSGG(uint _amount, uint32 _ticketTypeId, uint16 _seasonId, address _account) external returns(bool);
    function changeMinMaxLimits(uint _minAmount, uint _maxAmount, bool _status) external returns(bool);

}