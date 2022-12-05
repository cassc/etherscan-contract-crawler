// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract Refer is OwnableUpgradeable {
    struct UserInfo {
        uint refer_n;
        uint refer;
        uint referAmount;
        uint level;
        address invitor;
        mapping(uint => uint) levelRefer;
        uint toClaim;
    }

    IERC20Upgradeable public optc;
    mapping(address => UserInfo) public userInfo;
    mapping(address => bool) public admin;
    address public wallet;
    uint public walletAmount;
    uint[] referRate;
    uint[] referAmountRate;
    uint[] levelRewardRate;
    address public stake;
    mapping(address => bool) public  isRefer;
    mapping(address => address[]) referList;
    mapping(address => bool) isDone;
    function initialize() initializer public {
        __Ownable_init_unchained();
        admin[msg.sender] = true;
        referRate = [0, 2, 3, 4, 5, 6, 7, 8];
        referAmountRate = [0, 10000 ether, 20000 ether, 50000 ether, 200000 ether, 500000 ether, 1500000 ether, 5000000 ether];
        levelRewardRate = [0, 10, 20, 30, 40, 50, 60, 70];
        isRefer[address(this)] = true;
        wallet = 0xFDD4de4f105e9cd9d241cEb7492F1722f93d7419;
    }

    function setOPTC(address addr) external onlyOwner {
        optc = IERC20Upgradeable(addr);
    }

    function setAdmin(address addr, bool b) external onlyOwner {
        admin[addr] = b;
    }

    function setUserLevel(address addr, uint level_) external onlyOwner {
        userInfo[addr].level = level_;
    }

    function setStake(address addr) external onlyOwner {
        stake = addr;
        admin[stake] = true;
    }

    function setReferRate(uint[]memory rate_) external onlyOwner {
        referRate = rate_;
    }

    function setWallet(address addr) external onlyOwner {
        wallet = addr;
    }

    function checkLevel(address addr) internal returns (bool){
        uint _level = userInfo[addr].level;
        if (_level == 7) {
            return false;
        }
        for (uint i = _level; i < referAmountRate.length - 1; i++) {
            if (userInfo[addr].referAmount >= referAmountRate[i + 1] && userInfo[addr].refer_n >= referRate[i + 1] && userInfo[addr].levelRefer[_level] >= 2) {
                userInfo[addr].level ++;
                userInfo[userInfo[addr].invitor].levelRefer[i + 1] ++;
                return true;
            }
        }
        return true;
    }

    function getUserLevel(address addr) public view returns (uint){
        return userInfo[addr].level;
    }

    function getUserRefer(address addr) public view returns (uint){
        return userInfo[addr].refer_n;
    }


    function checkUserInvitor(address addr) external view returns (address){
        return userInfo[addr].invitor;
    }

    function getUserLevelRefer(address addr, uint level) public view returns (uint){
        return userInfo[addr].levelRefer[level];
    }

    function checkUserToClaim(address addr) external view returns (uint){
        return userInfo[addr].toClaim;
    }

    function setIsRefer(address addr, bool b) external {
        require(admin[msg.sender], 'not admin');
        isRefer[addr] = b;
    }


    function bond(address addr, address invitor, uint amount, uint stakeAmount) external {
        require(admin[msg.sender], 'not admin');
        bool first;
        if (userInfo[addr].invitor == address(0)) {
            first = true;
            require(isRefer[invitor], 'wrong invitor');
            userInfo[addr].invitor = invitor;
            userInfo[invitor].refer_n += 1;
            userInfo[invitor].levelRefer[0] ++;
        }
        address temp = userInfo[addr].invitor;

        {
            uint rew;
            uint index;
            uint left = amount;
            uint lastLevel = 0;
            bool isSame = false;
            while (temp != address(this)) {
                if (temp == address(0)) {
                    break;
                }
                UserInfo storage user = userInfo[temp];
                if (first) {
                    user.refer += 1;
                }
                if (stakeAmount != 0) {
                    user.referAmount += stakeAmount;
                    checkLevel(temp);
                    index ++;
                    if (left > 1 ether) {
                        if (index == 1) {
                            rew += amount * 10 / 100;
                        } else if (index == 2) {
                            rew += amount * 10 / 100;
                        }

                        if (user.level > lastLevel) {
                            rew += (levelRewardRate[user.level] - levelRewardRate[lastLevel]) * amount / 100;
                            lastLevel = user.level;
                        } else if (user.level == lastLevel && user.level >= 5 && !isSame) {
                            rew += amount * 10 / 100;
                            isSame = true;
                        }

                        left -= rew;
                        user.toClaim += rew;
                        rew = 0;
                    }

                }
                temp = user.invitor;
            }
            walletAmount += left;
        }
    }

    function claimReward(address addr, uint amount) external {
        require(admin[msg.sender], 'not admin');
        require(amount <= userInfo[addr].toClaim, 'out of amount');
        optc.transfer(stake, amount);
        userInfo[addr].toClaim -= amount;
        if (walletAmount != 0) {
            optc.transfer(wallet, walletAmount);
            walletAmount = 0;
        }
    }

    function updateReferList(address addr) external {
        address temp = userInfo[addr].invitor;
        address last = addr;
        for (uint i = 0; i < 100; i ++) {
            if (temp == address(this) || temp == address(0) || isDone[last]) {
                break;
            }
            isDone[last] = true;
            referList[temp].push(last);
            last = temp;
            temp = userInfo[temp].invitor;
        }
    }

    function checkReferList(address addr) external view returns(address[] memory,uint[] memory,uint[] memory){
        address[] memory _referList = referList[addr];
        uint[] memory _level = new uint[](_referList.length);
        uint[] memory _referAmount = new uint[](_referList.length);
        for(uint i = 0; i < _referList.length; i++){
            _level[i] = userInfo[_referList[i]].level;
            _referAmount[i] = userInfo[_referList[i]].referAmount;
        }
        return (_referList,_level,_referAmount);
    }
}