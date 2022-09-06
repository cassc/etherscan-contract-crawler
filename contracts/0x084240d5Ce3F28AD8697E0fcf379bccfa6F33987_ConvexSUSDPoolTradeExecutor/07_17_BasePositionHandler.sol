/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

abstract contract BasePositionHandler {
    /// @notice To be emitted when a deposit is made by position handler
    /// @param amount The amount of tokens deposited
    event Deposit(uint256 indexed amount);

    /// @notice To be emitted when a withdraw is made by position handler
    /// @param amount The amount of tokens withdrawn
    event Withdraw(uint256 indexed amount);

    /// @notice To be emitted with rewards are claimed by position handler
    /// @param amount The amount that was withdrawn
    event Claim(uint256 indexed amount);

    /// @notice struct to store data related to position
    /// @param posValue The value of the position in vault wantToken
    /// @param lastUpdatedBlock The block number of last update in position value
    struct Position {
        uint256 posValue;
        uint256 lastUpdatedBlock;
    }

    function positionInWantToken()
        external
        view
        virtual
        returns (uint256, uint256);

    function _openPosition(bytes calldata _data) internal virtual;

    function _closePosition(bytes calldata _data) internal virtual;

    function _deposit(bytes calldata _data) internal virtual;

    function _withdraw(bytes calldata _data) internal virtual;

    function _claimRewards(bytes calldata _data) internal virtual;
}