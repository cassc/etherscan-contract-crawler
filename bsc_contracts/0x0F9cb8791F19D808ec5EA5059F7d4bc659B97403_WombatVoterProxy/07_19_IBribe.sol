// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IBribe {
    function onVote(
        address user,
        uint256 newVote,
        uint256 originalTotalVotes
    ) external returns (uint256[] memory rewards);

    function pendingTokens(address _user)
        external
        view
        returns (uint256[] memory rewards);

    function rewardTokens() external view returns (address[] memory tokens);

    function rewardLength() external view returns (uint256);
}