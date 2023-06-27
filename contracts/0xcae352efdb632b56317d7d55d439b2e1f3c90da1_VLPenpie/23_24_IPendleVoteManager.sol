// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

interface IPendleVoteManager {

    function castVotes() external;

    function getClaimReward() external;

    function claimAllRewards(address _for) external returns (uint256[] memory earnedRewards);

    function vote(address[] calldata _lps, int256[] calldata _deltas) external;

    function userVotedForPoolInVlPenpie(address, address) external view returns (uint256);

    function userTotalVotedInVlPenpie(address _user) external view returns(uint256);

    function getUserVoteForPoolsInVlPenpie(address[] calldata lps, address _user)
        external
        view
        returns (uint256[] memory votes);

    function isPoolActive(address pool) external view returns (bool);

    function unVote(address _lp) external;

    function addPool(address _market, uint16 _chainId) external;

    function removePool(uint256 _index) external;

}