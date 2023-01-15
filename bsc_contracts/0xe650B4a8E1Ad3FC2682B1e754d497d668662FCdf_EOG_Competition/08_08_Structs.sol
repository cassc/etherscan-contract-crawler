/* SPDX-License-Identifier: MIT OR Apache-2.0 */
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

    struct Token {
        IERC20 tokenAddress;
        uint256 stablePrice;
        uint256 totalBalance;
        uint256 lockedBalance;
        bool isActive;
    }
    
    struct Preset {
        uint256 entryFeeInUSD;
        uint256 numberOfTeamMemebr;
        uint256 date;
        uint256 createAt;
        uint256 rakeAmountInUSD;
        bool isActive;
    }

    struct Competition {
        // uint8 teamsCount;
        // uint8 winnerTeam;
        uint8 teamSize;
        CompetitionStatus status;
        CompetitionWinner winnerTeam;
        uint256 presetId;
        uint256 createAt;
    }

    struct Competitor {
        address account;
        uint256 tokenIndex;
        uint256 payableInUSD;
    }

    struct Team {
        Competitor[] competitors;
    }

    enum CompetitionStatus { PENDING, CANCELED, DONE }
    enum CompetitionWinner {TEAMA , TEAMB , DRAW, OPEN}
    enum PaymentType{EARNING , PAYBACK}