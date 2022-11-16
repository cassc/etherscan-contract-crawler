// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

import "./IBetAdminActions.sol";

interface IBettingPlatform is IBetAdminActions {

    struct PlayerBetInfo {
        address holdingToken;
        uint256 betAmount;
        uint256 betSideId;
    }

    struct BettingPool {
        uint256 startTime;
        uint256 endTime;
        uint256 totalBetAmount;
        uint256[] betedAmounts;
        string[] betSides;
        string betConditionStr;
        string betConditionImg;
        int256 winBetSideId;
        bool finished;
    }

    struct BetAmountInfo {
        uint256 sideId;
        string sideDescription;
        uint256 totalBetAmount;
    }

    struct IBetSide {
        uint256 betSideId;
        string betSide;
    }

    struct IBettingPool {
        uint256 bettingId;
        uint256 startTime;
        uint256 endTime;
        IBetSide[] betSides;
        string betConditionStr;
        string betConditionImg;
    }

    struct BettingInfo {
        uint256 bettingId;
        uint256 startTime;
        uint256 endTime;
        int256 winBetSideId;
        bool finished;
        string betConditionStr;
        string betConditionImg;
    }

    /// @notice Let users bet to a betting side.
    /// @param bettingId_ Id of betting pool.
    /// @param sideId_ Id of betting sides.
    function placeBet(
        uint256 bettingId_,
        uint256 sideId_,
        address holdingTokenAddr_
    ) external payable;

    /// @notice Get information for placed betting pools.
    /// @return Information for placed betting pools.
    function getPlacedBettingList() external view returns (IBettingPool[] memory);

    /// @notice Get information for all betting pools.
    /// @return Information for all betting pools.
    function getAllBettingList() external view returns (BettingInfo[] memory);

    /// @notice Get information about betting amount by bettingId.
    /// @param bettingId_ The Id of betting.
    function getBetAmountBySide(uint256 bettingId_) external view returns (BetAmountInfo[] memory);

    /// @notice Get holding token list that added to Betting Platform.
    function getHoldingTokens() external view returns (address[] memory);

    event PlaceBet(address indexed player, uint256 bettingId, uint256 sideId, uint256 betAmount);
}