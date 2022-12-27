// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract EnumerableArrays {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(uint256 => EnumerableSet.AddressSet) _rewardCandidates;
    mapping(uint256 => EnumerableSet.AddressSet) _lotteryCandidates;
    mapping(uint256 => EnumerableSet.AddressSet) _lotteryWinners;

    uint256 rcIndex;
    uint256 lcIndex;
    uint256 lwIndex;

    function _resetRewardCandidates() internal {
        rcIndex++;
    }
    function _resetLotteryCandidates() internal {
        lcIndex++;
    }
    function _resetLotteryWinners() internal {
        lwIndex++;
    }

    function todayRewardCandidates() public view returns(address[] memory) {
        return _rewardCandidates[rcIndex].values();
    }

    function todayLotteryCandidates() public view returns(address[] memory) {
        return _lotteryCandidates[lcIndex].values();
    }

    function lastLotteryWinners() public view returns(address[] memory) {
        return _lotteryWinners[lwIndex].values();
    }

    function todayRewardCandidatesCount() public view returns(uint256) {
        return _rewardCandidates[rcIndex].length();
    }

    function todayLotteryCandidatesCount() public view returns(uint256) {
        return _lotteryCandidates[lcIndex].length();
    }

    function lastLotteryWinnersCount() public view returns(uint256) {
        return _lotteryWinners[lwIndex].length();
    }
}