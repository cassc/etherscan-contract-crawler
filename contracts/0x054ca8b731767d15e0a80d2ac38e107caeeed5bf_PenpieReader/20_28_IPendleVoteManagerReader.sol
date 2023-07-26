// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;


interface IPendleVoteManagerReader {
  
    function getPoolsLength() external view returns(uint256);
    function lastCastTime() external view returns(uint256);
    function totalVlPenpieInVote() external view returns(uint256);
    function poolInfos(uint256) external view returns (address, uint256, uint256, bool);
    function userVotedForPoolInVlPenpie(address, address) external view returns (uint256);
     
    function userTotalVotedInVlPenpie(address _user) external view returns(uint256);
    function getUserVotable(address _user) external view returns (uint256);
    function getUserVoteForPoolsInVlPenpie(address[] calldata lps, address _user)
        external
        view
        returns (uint256[] memory votes);
}