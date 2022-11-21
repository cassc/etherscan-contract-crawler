pragma solidity ^0.8.0;
// SPDX-License-Identifier: GPL-3.0

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";



contract Invitation {
    function getInvitation(address user) external view returns (address inviter, address[] memory invitees) {}
}

contract WorldCup {
    function generateNFT(address _msgSender) public returns (uint256){}
}


contract WorldCupQuizMode is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 public usdtContract;
    Invitation public invitation;
    WorldCup public worldCup;

    uint256 public upperLimitU = 1000000 * 10 ** 18;
    uint256 public lowerLimitU = 50 * 10 ** 18;

    uint256 public stopDay = 7;
    uint256 public allocationRatio = 84;
    uint256 public wAmount = 500 * 10 ** 18;

    bool public isWithdrawContract;

    address public impl;

    mapping(uint256 => mapping(uint256 => uint256)) public playerGoals;
    mapping(uint256 => uint256[]) public playerId;
    mapping(uint256 => uint256[]) public playerIdGoals;

    mapping(uint256 => mapping(uint256 => uint256)) public playerIdNumber;
    mapping(uint256 => mapping(uint256 => uint256)) public playerNumber;
    mapping(uint256 => uint256) public playerUserNumberA;
    mapping(uint256 => uint256) public playerUserNumberB;
    mapping(address => mapping(uint256 => bool)) public is11FullA;
    mapping(address => mapping(uint256 => bool)) public is11FullB;
    mapping(uint256 => address) public tokenIdAddress;
    mapping(uint256 => mapping(uint256 => uint256)) public tokenIdNumber;
    mapping(uint256 => mapping(address => bool)) public isPledge;
    mapping(uint256 => bool) public isDestroy;
    mapping(uint256 => uint256) public specialAmount;

    mapping(uint256 => ScreeningsInfo) public screeningsInfos;

    struct ScreeningsInfo {
        uint64 teamA;
        uint64 teamB;
        uint64 goalsA;
        uint64 goalsB;
        uint256 contestType;
        string grouping;
        bool isDistribute;
        uint256 stopWithdraw;
        uint256 stopBetting;
    }

    mapping(uint256 => ScreeningsInfo2) public screeningsInfos2;

    struct ScreeningsInfo2 {
        uint256 totalGoals;
        uint256 totalNumber;
        uint256 totalAmount;
        uint256 withdrawAmount;
        bool isTotalGoal;
        bool isResult;
        bool isGoals;
        bool isNumber;
        uint256 openNumber;
        uint256 amounts;

    }

    mapping(address => mapping(uint256 => UserBetTokenIdInfo)) userBetTokenIdInfos;

    struct UserBetTokenIdInfo {
        mapping(uint256 => bool) isWithdrawTotalGoal;
        mapping(uint256 => bool) isWithdrawResult;
        mapping(uint256 => mapping(uint256 => bool)) isWithdrawGals;
        uint256[] tokenIdsA;
        uint256[] tokenIdsB;
    }

    mapping(address => mapping(uint256 => BetInfo)) public userBetInfosW;
    mapping(uint256 => BetInfo) public screeningsBetInfosW;

    struct BetInfo {
        mapping(uint256 => uint256) totalGoalAmount;
        mapping(uint256 => uint256) resultAmount;
        mapping(uint256 => mapping(uint256 => uint256)) goalsAmount;
        uint256 totalGoalWithdrawAmount;
        uint256 resultWithdrawAmount;
        uint256 goalsWithdrawAmount;
        uint256 totalGoalAmounts;
        uint256 resultAmounts;
        uint256 goalsAmounts;
    }


    event SetPlayerGoals(uint256 _number, uint256 _name, uint256 _goal, uint256 _time1);
    event SetTotalGoals(uint256 number, uint256 _totalGoals, uint256 _time1);
    event SetScreeningsInfoTeam(uint256 _number, uint256 teamA, uint256 teamB, uint256 _time1);
    event SetScreeningsInfoGoals(uint256 _number, uint256 goalsA, uint256 goalsB, uint256 _time1);
    event SetScreeningsInfoStopBetting(uint256 _number, uint256 stopBetting, uint256 _time1);
    event SetScreeningsInfoIsDistribute(uint256 _number, bool _isDistribute, uint256 _time1);
    event SetDestroy(address indexed _msgSender,uint256 _number, uint256 _amount, uint256 _time1);
    event SetContestType(uint256 _number, uint256 _contestType, uint256 _time1);
    event SetGrouping(uint256 _number, string _grouping, uint256 _time1);
    event Bet(address indexed _msgSender, uint256 _number, uint256 uamount, uint256 amount, uint256 _goalA, uint256 _goalB, uint256 _betType, uint256 a,uint256 _time1);
    event Withdraw(address indexed _msgSender, uint256 _number, uint256 _betType,uint256 _goalA, uint256 _goalB, uint256 _amount, uint256 _time);
    event WorldCupNFT(address indexed _msgSender, uint256 number, uint256 _betType,uint256 _goalA, uint256 _goalB, uint256 _tookenId, uint256 _time);
    event Rebate(address indexed _msgSender, address indexed _inviter, uint256 _number, uint256 _rebateAmount, uint256 _time);

    function earningsOf(address _msgSender, uint256 _number, uint256 _goalA, uint256 _goalB, uint256 _betType) public view returns (uint256){
        ScreeningsInfo storage scc = screeningsInfos[_number];
        ScreeningsInfo2 storage scc2 = screeningsInfos2[_number];

        uint256 earningsAmount;
        uint256 amounts = scc2.amounts.div(scc2.openNumber);

        if (scc.isDistribute) {

            BetInfo storage bet = screeningsBetInfosW[_number];
            BetInfo storage userBet = userBetInfosW[_msgSender][_number];

            uint256 ratio = allocationRatio;

            if (_betType == 1) {
                if (scc2.isResult) {
                    uint256 result;
                    if (scc.goalsA > scc.goalsB) {
                        result = 1;
                    } else if (scc.goalsA < scc.goalsB) {
                        result = 2;
                    } else {
                        result = 3;
                    }
                    uint256 _proportion = bet.resultAmounts.add(amounts).mul(ratio).div(100);
                    if (_goalA == result) {
                        earningsAmount = _proportion.mul(100000000000).div(bet.resultAmount[result]).mul(userBet.resultAmount[result]);
                    }
                }


            } else if (_betType == 2) {
                if (scc2.isTotalGoal) {
                    uint256 totalGoals = uint256(scc.goalsA).add(uint256(scc.goalsB));
                    uint256 _proportion = bet.totalGoalAmounts.add(amounts).mul(ratio).div(100);
                    if (_goalA == totalGoals) {
                        earningsAmount = _proportion.mul(100000000000).div(bet.totalGoalAmount[totalGoals]).mul(userBet.totalGoalAmount[totalGoals]);
                    }
                }


            } else if (_betType == 3) {
                if (scc2.isGoals) {
                    uint256 _proportion = bet.goalsAmounts.add(amounts).mul(ratio).div(100);
                    if (_goalA == scc.goalsA && _goalB == scc.goalsB) {
                        earningsAmount = _proportion.mul(100000000000).div(bet.goalsAmount[uint256(scc.goalsA)][uint256(scc.goalsB)]).mul(userBet.goalsAmount[uint256(scc.goalsA)][uint256(scc.goalsB)]);
                    }
                }


            }
        }

        return earningsAmount.div(100000000000);
    }




    function totalAmountOf(uint256 _number, uint256 goalsA, uint256 goalsB, uint256 _betType) public view returns (uint256){
        BetInfo storage betInfoW = screeningsBetInfosW[_number];
        uint256 amount;
        if (_betType == 1) {
            amount = betInfoW.resultAmount[goalsA];
        } else if (_betType == 2) {
            amount = betInfoW.totalGoalAmount[goalsA];
        } else if (_betType == 3) {
            amount = betInfoW.goalsAmount[goalsA][goalsB];
        }
        return amount;
    }


    function userTotalGoalsAmountOf(address _msgSender, uint256 _number, uint256 goalsA, uint256 goalsB, uint256 _betType) public view returns (uint256){

        BetInfo storage betInfoW = userBetInfosW[_msgSender][_number];
        uint256 amount;
        if (_betType == 1) {
            amount = betInfoW.resultAmount[goalsA];
        } else if (_betType == 2) {
            amount = betInfoW.totalGoalAmount[goalsA];
        } else if (_betType == 3) {
            amount = betInfoW.goalsAmount[goalsA][goalsB];
        }
        return amount;
    }


    function userTokenIdOf(address _msgSender, uint256 _number) public view returns (uint256[] memory, uint256[] memory){
        UserBetTokenIdInfo storage userBetTokenIdInfo = userBetTokenIdInfos[_msgSender][_number];
        return (userBetTokenIdInfo.tokenIdsA, userBetTokenIdInfo.tokenIdsB);
    }

    function playerIdOf(uint256 _number) public view returns (uint256[] memory){
        return playerId[_number];
    }

    function playerIdGoalsOf(uint256 _number) public view returns (uint256[] memory){
        return playerIdGoals[_number];
    }


    function userIsWithdraw(address _msgSender, uint256 _number, uint256 goalsA, uint256 goalsB, uint256 _betType) public view returns (bool){
        UserBetTokenIdInfo storage userBetTokenIdInfo = userBetTokenIdInfos[_msgSender][_number];
        bool isWithdraw;
        if (_betType == 1) {
            isWithdraw = userBetTokenIdInfo.isWithdrawResult[goalsA];
        } else if (_betType == 2) {
            isWithdraw = userBetTokenIdInfo.isWithdrawTotalGoal[goalsA];
        } else if (_betType == 3) {
            isWithdraw = userBetTokenIdInfo.isWithdrawGals[goalsA][goalsB];
        }
        return isWithdraw;
    }



}