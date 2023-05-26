// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IKEY3InvitationRegistry {
    event CloseRound(uint256 indexed round, uint256 maxTicket);
    event NewRound(uint256 indexed round, uint256 minTicket);

    function addController(address controller) external;

    function removeController(address controller) external;

    function startNewRound() external;

    function register(address user, address inviter) external;

    function currentTicket() external view returns (uint256);

    function currentRound() external view returns (uint256);

    function ticketsOf(address inviter)
        external
        view
        returns (uint256[] memory);

    function invitationsOf(address inviter_)
        external
        view
        returns (address[] memory);
}