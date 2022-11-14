// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

interface IBetAdminActions {

    /// @notice Update platform asset.
    /// @param newAsset_ New platform asset address.
    function updatePlatformAsset(address newAsset_) external;

    /// @notice Update platform fee.
    /// @param newFee_ New platform fee.
    function updatePlatformFee(uint16 newFee_) external;

    /// @notice Update minimum betting amount.
    /// @param newMinAmount_ New min amount for betting.
    function updateMinBetAmount(uint256 newMinAmount_) external;

    /// @notice Start new betting.
    /// @param betConditionStr_ The condition string for betting.
    /// @param betConditionImg_ The condition img url for betting.
    /// @param betSides_ Betting cases that users can bet to.
    /// @param startTime_ The timestamp of betting will starts.
    function startNewBet(
        string memory betConditionStr_,
        string memory betConditionImg_,
        string[] memory betSides_,
        uint256 startTime_,
        uint256 endTime_
    ) external;

    /// @notice Stop betting.
    /// @dev Refund all betting amounts to players without fee.
    /// @param bettingId_ The id of betting pool
    function stopBet(
        uint256 bettingId_
    ) external;

    /// @notice Input winner side.
    /// @dev Take fee and divide rewards to winner side.
    /// @param bettingId_ The id of betting pool
    /// @param sideId_ The id of bet sides.
    function chooseWinner(
        uint256 bettingId_,
        uint256 sideId_
    ) external;

    /// @notice withdraw fee amount and ETH.
    /// @dev this function can be call only after betting is finished.
    function withdrawAsset() external;

    event UpdatePlatformAsset(address indexed newAsset);

    event UpdatePlatfromFee(uint16 newFee);

    event UpdateMinBetAmount(uint256 newMinBetAmount);

    event StartNewBet(
        string betConditionStr,
        string betConditionImg,
        string[] betSides,
        uint256 startTime,
        uint256 endTime
    );

    event StopBet(uint256 bettingId);

    event ChooseWinner(uint256 bettingId, uint256 sideId);
}