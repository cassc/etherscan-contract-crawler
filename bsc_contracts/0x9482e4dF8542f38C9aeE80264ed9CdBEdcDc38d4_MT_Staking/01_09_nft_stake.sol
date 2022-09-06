// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "../interface/I721.sol";

contract MT_Staking is OwnableUpgradeable, ERC721HolderUpgradeable {
    IERC20 public u;
    I721 public nft;

    struct RewardInfo {
        uint normalDebt;
        uint[4] levelDebt;
        uint superDebt;
    }

    struct UserInfo {
        uint stakeAmount;
        uint[] stakeList;
        uint referAmount;
        uint referLevel;
        uint totalReward;
        uint[4] levelDebt;
        uint superDebt;
        uint[12] stakeKind;
        uint toClaim;
        bool isSuperNode;
    }

    struct StakeInfo {
        bool status;
        uint tokenId;
        address owner;
        address invitor;
        uint debt;
        uint stakeTime;
    }

    RewardInfo public rewardInfo;
    uint public totalCard;
    uint[4] levelAmount;
    mapping(address => UserInfo) public userInfo;
    mapping(uint => StakeInfo) public stakeInfo;
    uint public lastU;
    uint public superNodeAmount;
    uint[] normalRate;
    uint[] levelRate;
    uint[] referLevelRate;
    mapping(address => bool) public manager;
    mapping(address => uint) public userAddRefer;
    mapping(address => bool) public isAddSuperNode;

    struct ClaimInfo {
        uint normalClaimed;
        uint levelClaimed;
        uint nodeClaimed;
    }

    mapping(address => ClaimInfo) public claimInfo;

    event Stake(address indexed player, address indexed invitor, uint indexed tokenID);
    event Claim(address indexed player, uint indexed amount);
    event UnStake(address indexed player, uint indexed tokenID);

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC721Holder_init_unchained();
        levelAmount = [0, 0, 0, 0];
        rewardInfo.levelDebt = [0, 0, 0, 0];
        normalRate = [40, 40, 20];
        levelRate = [10, 20, 30, 40];
        referLevelRate = [10, 15, 20, 30];
        manager[msg.sender] = true;
        u = IERC20(0x55d398326f99059fF775485246999027B3197955);
    }

    modifier onlyEOA(){
        require(msg.sender == tx.origin, 'not allowed');
        _;
    }

    modifier onlyManager(){
        require(manager[msg.sender], 'not manager');
        _;
    }

    modifier countingDebt(){
        uint tempBalance = u.balanceOf(address(this));
        if (tempBalance > lastU) {
            uint rew = tempBalance - lastU;
            if (totalCard > 0) {
                rewardInfo.normalDebt += rew * normalRate[0] / 100 / totalCard;
            }
            uint levelRew = rew * normalRate[1] / 100;
            for (uint i = 0; i < 4; i++) {
                if (levelAmount[i] > 0) {
                    rewardInfo.levelDebt[i] += levelRew * levelRate[i] / 100 / levelAmount[i];
                }
            }
            if (superNodeAmount > 0) {
                rewardInfo.superDebt += rew * normalRate[2] / 100 / superNodeAmount;
            }
        }
        _;
        lastU = u.balanceOf(address(this));
    }

    function setU(address addr) external onlyOwner {
        u = IERC20(addr);
    }

    function setNFT(address addr) external onlyOwner {
        nft = I721(addr);
    }

    function getTempDebt() public view returns (uint _normalDebt, uint[4] memory levelDebt, uint nodeDebt){
        uint tempBalance = u.balanceOf(address(this));
        _normalDebt = rewardInfo.normalDebt;
        levelDebt = rewardInfo.levelDebt;
        nodeDebt = rewardInfo.superDebt;
        if (tempBalance > lastU) {
            uint rew = tempBalance - lastU;
            if (totalCard > 0) {
                _normalDebt += rew * normalRate[0] / 100 / totalCard;
            }
            uint levelRew = rew * normalRate[1] / 100;
            for (uint i = 0; i < 4; i++) {
                if (levelAmount[i] > 0) {
                    levelDebt[i] += levelRew * levelRate[i] / 100 / levelAmount[i];
                }
            }
            if (superNodeAmount > 0) {
                nodeDebt += rew * normalRate[2] / 100 / superNodeAmount;
            }
        }
    }

    function checkUserStakeList(address addr) public view returns (uint[] memory, uint[] memory, uint[] memory){
        uint[] memory temp = userInfo[addr].stakeList;
        uint[] memory cardIdList = new uint[](temp.length);
        uint[] memory stakeTime = new uint[](temp.length);
        for (uint i = 0; i < temp.length; i++) {
            cardIdList[i] = nft.cardIdMap(temp[i]);
            stakeTime[i] = stakeInfo[temp[i]].stakeTime;
        }
        return (userInfo[addr].stakeList, cardIdList, stakeTime);
    }

    function checkUserStakeKind(address addr) public view returns (uint[12] memory){
        return userInfo[addr].stakeKind;
    }

    function getUserLevel(address addr) public view returns (uint){
        uint tempAmount = userInfo[addr].referAmount;
        if (tempAmount >= referLevelRate[3]) {
            return 4;
        } else if (tempAmount >= referLevelRate[2]) {
            return 3;
        } else if (tempAmount >= referLevelRate[1]) {
            return 2;
        } else if (tempAmount >= referLevelRate[0]) {
            return 1;
        } else {
            return 0;
        }
    }

    function setManager(address addr, bool b) external onlyOwner {
        manager[addr] = b;
    }

    function _calculateToken(uint token) internal view returns (uint){
        uint tokenDebt = stakeInfo[token].debt;
        return (rewardInfo.normalDebt - tokenDebt);
    }

    function _calculateNodeRew(address addr) internal view returns (uint){
        uint userDebt = userInfo[addr].superDebt;
        return (rewardInfo.superDebt - userDebt);
    }

    function _calculateLevelRew(address addr, uint level) internal view returns (uint){
        uint userDebt = userInfo[addr].levelDebt[level - 1];
        return (rewardInfo.levelDebt[level - 1] - userDebt);
    }

    function calculateAllReward(address addr) public view returns (uint){
        uint[] memory list = userInfo[addr].stakeList;
        uint rew;
        for (uint i = 0; i < list.length; i++) {
            if (stakeInfo[list[i]].status) {
                rew += _calculateToken(list[i]);
            }
        }
        if (userInfo[addr].referLevel > 0) {
            rew += _calculateLevelRew(addr, userInfo[addr].referLevel);
        }
        if (userInfo[addr].isSuperNode) {
            rew += _calculateNodeRew(addr);
        }
        return rew + userInfo[addr].toClaim;
    }


    function _processReferAmount(address addr, bool isAdd) internal {
        if (isAdd) {
            userInfo[addr].referAmount ++;
            uint oldLevel = userInfo[addr].referLevel;
            uint newLevel = getUserLevel(addr);
            if (newLevel != oldLevel) {
                userInfo[addr].referLevel = newLevel;
                levelAmount[newLevel - 1] ++;
                userInfo[addr].levelDebt[newLevel - 1] = rewardInfo.levelDebt[newLevel - 1];
                if (oldLevel != 0) {
                    levelAmount[oldLevel - 1] --;
                    uint tempReward = _calculateLevelRew(addr, oldLevel);
                    if (tempReward > 0) {
                        claimInfo[addr].levelClaimed += tempReward;
                        userInfo[addr].toClaim += tempReward;
                        userInfo[addr].levelDebt[oldLevel - 1] = rewardInfo.levelDebt[oldLevel - 1];
                    }
                }
            }
        } else {
            userInfo[addr].referAmount --;
            uint oldLevel = userInfo[addr].referLevel;
            uint newLevel = getUserLevel(addr);
            if (newLevel != oldLevel) {
                userInfo[addr].referLevel = newLevel;
                levelAmount[oldLevel - 1] --;
                if (newLevel != 0) {
                    levelAmount[newLevel - 1] ++;
                    userInfo[addr].levelDebt[newLevel - 1] = rewardInfo.levelDebt[newLevel - 1];
                    uint tempReward = _calculateLevelRew(addr, oldLevel);
                    if (tempReward > 0) {
                        claimInfo[addr].levelClaimed += tempReward;
                        userInfo[addr].toClaim += tempReward;
                        userInfo[addr].levelDebt[oldLevel - 1] = rewardInfo.levelDebt[oldLevel - 1];
                    }
                }
            }
        }
    }

    function _checkUserIsNode(address addr) internal view returns (bool){
        for (uint i = 0; i < 12; i++) {
            if (userInfo[addr].stakeKind[i] == 0) {
                return false;
            }
        }
        return true;
    }

    function claimReward() external countingDebt onlyEOA {
        uint[] memory list = userInfo[msg.sender].stakeList;
        uint rew;
        uint temp;
        for (uint i = 0; i < list.length; i++) {
            if (stakeInfo[list[i]].status) {
                temp = _calculateToken(list[i]);
                claimInfo[msg.sender].normalClaimed += temp;
                rew += temp;
                stakeInfo[list[i]].debt = rewardInfo.normalDebt;
            }
        }
        uint level = userInfo[msg.sender].referLevel;
        if (level > 0) {
            temp = _calculateLevelRew(msg.sender, level);
            rew += temp;
            claimInfo[msg.sender].levelClaimed += temp;
            userInfo[msg.sender].levelDebt[level - 1] = rewardInfo.levelDebt[level - 1];
        }
        if (userInfo[msg.sender].isSuperNode) {
            temp = _calculateNodeRew(msg.sender);
            rew += temp;
            claimInfo[msg.sender].nodeClaimed += temp;
            userInfo[msg.sender].superDebt = rewardInfo.superDebt;
        }
        if (userInfo[msg.sender].toClaim > 0) {
            rew += userInfo[msg.sender].toClaim;
            userInfo[msg.sender].toClaim = 0;
        }
        u.transfer(msg.sender, rew);
        userInfo[msg.sender].totalReward += rew;
        emit Claim(msg.sender, rew);
    }

    function stake(address invitor, uint tokenId) external onlyEOA countingDebt {
        require(invitor == address(this) || userInfo[invitor].stakeAmount > 0, 'wrong invitor');
        require(invitor != msg.sender, 'wrong invitor');
        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        stakeInfo[tokenId] = StakeInfo({
        status : true,
        tokenId : tokenId,
        owner : msg.sender,
        invitor : invitor,
        debt : rewardInfo.normalDebt,
        stakeTime : block.timestamp
        });
        userInfo[msg.sender].stakeAmount++;
        userInfo[msg.sender].stakeList.push(tokenId);
        userInfo[msg.sender].stakeKind[nft.cardIdMap(tokenId) - 1] ++;
        totalCard++;
        if (invitor != address(this)) {
            _processReferAmount(invitor, true);
        }

        if (userInfo[msg.sender].stakeAmount >= 12 && !userInfo[msg.sender].isSuperNode) {
            if (_checkUserIsNode(msg.sender)) {
                userInfo[msg.sender].isSuperNode = true;
                userInfo[msg.sender].superDebt = rewardInfo.superDebt;
                superNodeAmount ++;
            }
        }
        emit Stake(msg.sender, invitor, tokenId);
    }

    function unStake(uint tokenId) external onlyEOA countingDebt {
        require(stakeInfo[tokenId].status, 'wrong tokenId');
        require(stakeInfo[tokenId].owner == msg.sender, 'not owner');
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        address invitor = stakeInfo[tokenId].invitor;
        uint tempRew = _calculateToken(tokenId);
        if (tempRew > 0) {
            userInfo[msg.sender].toClaim += tempRew;
        }
        delete stakeInfo[tokenId];
        userInfo[msg.sender].stakeAmount--;
        uint _index;
        for (uint i = 0; i < userInfo[msg.sender].stakeList.length; i++) {
            if (userInfo[msg.sender].stakeList[i] == tokenId) {
                _index = i;
            }
        }
        userInfo[msg.sender].stakeList[_index] = userInfo[msg.sender].stakeList[userInfo[msg.sender].stakeList.length - 1];
        userInfo[msg.sender].stakeList.pop();
        userInfo[msg.sender].stakeKind[nft.cardIdMap(tokenId) - 1] --;
        totalCard --;
        if (invitor != address(this)) {
            _processReferAmount(invitor, false);
        }
        if (userInfo[msg.sender].stakeAmount < 12 && userInfo[msg.sender].isSuperNode) {
            if (!_checkUserIsNode(msg.sender)) {
                userInfo[msg.sender].isSuperNode = false;
                uint rew = _calculateNodeRew(msg.sender);
                if (rew > 0) {
                    claimInfo[msg.sender].nodeClaimed += rew;
                    userInfo[msg.sender].toClaim += rew;
                }
                superNodeAmount --;
            }
        }
        emit UnStake(msg.sender, tokenId);
    }

    function checkAllReward(address addr) public view returns (uint, uint, uint, uint){
        uint[] memory list = userInfo[addr].stakeList;
        uint tokenRew;
        uint nodeRew;
        uint levelRew;
        uint totalRew;
        uint userDebt;
        {
            UserInfo memory info = userInfo[addr];
            (uint _normal,uint[4] memory _level,uint _node) = getTempDebt();
            for (uint i = 0; i < list.length; i++) {
                if (stakeInfo[list[i]].status) {
                    uint tokenDebt = stakeInfo[list[i]].debt;
                    tokenRew += _normal - tokenDebt;
                }
            }
            if (info.isSuperNode) {
                userDebt = info.superDebt;
                nodeRew = _node - userDebt;
            }

            uint level = info.referLevel;
            if (level != 0) {
                userDebt = info.levelDebt[level - 1];
                levelRew = _level[level - 1] - userDebt;
            }

            totalRew = tokenRew + levelRew + nodeRew;
        }

        return (totalRew, tokenRew, levelRew, nodeRew);
    }

    function setUserLevel(address addr, uint Amount) external onlyManager countingDebt {
        userInfo[addr].referAmount += Amount - 1;
        userAddRefer[addr] += Amount;
        _processReferAmount(addr, true);
    }

    function clearUserReferLevel(address addr) external onlyManager {
        require(userAddRefer[addr] > 0, 'no add amount');
        userInfo[addr].referAmount -= userAddRefer[addr] - 1;
        _processReferAmount(addr, false);
    }


    function setUserSuperNode(address addr, bool b) external onlyManager countingDebt {
        if (b) {
            require(!isAddSuperNode[addr], 'already add');
            for (uint i = 0; i < 12; i++) {
                userInfo[addr].stakeKind[i] += 1;
            }
            if (_checkUserIsNode(addr)) {
                userInfo[addr].isSuperNode = true;
                userInfo[addr].superDebt = rewardInfo.superDebt;
                superNodeAmount ++;
            }
            isAddSuperNode[addr] = true;
        } else {
            require(isAddSuperNode[addr], 'not add yet');
            for (uint i = 0; i < 12; i++) {
                userInfo[addr].stakeKind[i] += 1;
            }
            if (_checkUserIsNode(addr)) {
                userInfo[addr].isSuperNode = false;
                uint rew = _calculateNodeRew(addr);
                if (rew > 0) {
                    userInfo[addr].toClaim += rew;
                }
                userInfo[addr].superDebt = rewardInfo.superDebt;
                superNodeAmount --;
            }
            isAddSuperNode[addr] = false;
        }
    }

    function checkAllAmount() public view returns (uint[4] memory levels, uint nodeAmount){
        levels = levelAmount;
        nodeAmount = superNodeAmount;
    }


}