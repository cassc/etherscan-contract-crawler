// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWombatBribeManager {
    function castVotes(bool swapForBnb)
        external
        returns (address[][] memory finalRewardTokens, uint256[][] memory finalFeeAmounts);

    function claimAllBribes(address _for)
        external
        returns (address[] memory finalRewardTokens, uint256[] memory finalFeeAmounts);

    function vote(address[] calldata _lps, int256[] calldata _deltas) external;

    function userVotedForPoolInVlmgp(address, address) external view returns (uint256);

    function userTotalVotedInVlmgp(address _user) external view returns(uint256);

    function getUserVoteForPoolsInVlmgp(address[] calldata lps, address _user)
        external
        view
        returns (uint256[] memory votes);

    function isPoolActive(address pool) external view returns (bool);

    function unvote(address _lp) external;

}