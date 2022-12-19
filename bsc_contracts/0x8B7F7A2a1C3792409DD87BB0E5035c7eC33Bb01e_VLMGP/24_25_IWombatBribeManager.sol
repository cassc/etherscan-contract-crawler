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

    function userTotalVotedInVlmgp(address) external view returns(uint256);
}