// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract EnumerableArrays {

    mapping(uint256 => address[]) _rewardCandidates;
    mapping(uint256 => address[]) _lotteryCandidates;
    mapping(uint256 => address[]) _lotteryWinners;
    mapping(uint256 => mapping(address => uint8)) _userTodayPoints;

    uint256 rcIndex;
    uint256 lcIndex;
    uint256 lwIndex;
    uint256 pIndex;

    function _resetRewardCandidates() internal {
        rcIndex++;
    }
    function _resetLotteryCandidates() internal {
        lcIndex++;
    }
    function _resetLotteryWinners() internal {
        lwIndex++;
    }
    function _resetUserPoints() internal {
        pIndex++;
    }

    function todayRewardCandidates() public view returns(address[] memory addr) {
        uint256 len = _rewardCandidates[rcIndex].length;
        addr = new address[](len);

        for(uint256 i; i < len; i++) {
            addr[i] = _rewardCandidates[rcIndex][i];
        }
    }

    function todayLotteryCandidates() public view returns(address[] memory addr) {
        uint256 len = _lotteryCandidates[lcIndex].length;
        addr = new address[](len);

        for(uint256 i; i < len; i++) {
            addr[i] = _lotteryCandidates[lcIndex][i];
        }
    }

    function lastLotteryWinners() public view returns(address[] memory addr) {
        uint256 len = _lotteryWinners[lwIndex].length;
        addr = new address[](len);

        for(uint256 i; i < len; i++) {
            addr[i] = _lotteryWinners[lwIndex][i];
        }
    }

    function userTodayPoints(address userAddr) public view returns(uint256) {
        return _userTodayPoints[pIndex][userAddr];
    }

    function todayRewardCandidatesCount() public view returns(uint256) {
        return _rewardCandidates[rcIndex].length;
    }

    function todayLotteryCandidatesCount() public view returns(uint256) {
        return _lotteryCandidates[lcIndex].length;
    }

    function lastLotteryWinnersCount() public view returns(uint256) {
        return _lotteryWinners[lwIndex].length;
    }
}