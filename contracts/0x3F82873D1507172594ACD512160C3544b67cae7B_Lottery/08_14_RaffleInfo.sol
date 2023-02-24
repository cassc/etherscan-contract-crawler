pragma solidity = 0.8.14;

library RaffleStorage {
    struct RaffleInfo {
        uint256 number;
        string raffleName;
        uint16 maxTickets;
        uint256 ticketPrice;
        uint16 ticketCounter;
        uint32 startTime;
        uint32 endTime;
    }
    struct RaffleInfo1 {
        address raffleRewardToken;
        bool isTaxed;
        uint256 raffleRewardTokenAmount;
        address winner;
        uint256 winningTicket;
        uint16 rewardPercent; // How much of the total tokens or eth will be rewarded from the total ticket buying price. In BP 10000.
        uint16 burnPercent;
        bool isWinnerDeclared;
        bool isClaimed;
        mapping(uint256 => address) ticketOwner;
    }
    struct UserTickets {
        uint256[] ticketsNumber;
    }
}