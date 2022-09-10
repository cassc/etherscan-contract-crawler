// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./SafeMath.sol"; // Importa SafeMath
import "./Ownable.sol"; // Importa Owner

abstract contract StakeSystem is Ownable {
    using SafeMath for uint256; // SafeMath para uint256
    /*=== Mapping ===*/
    mapping (address => uint256) public balanceUser; // Saldo 
    mapping (address => uint256) public rewards; // Recompensa
    mapping (address => uint256) public userRewardPerTokenPaid; // Recompensa Paga
    mapping (address => uint256) public harvestTime; // Tempo de Colheita
    /*=== Uints ===*/
    uint256 public lastUpdateTime; // Tempo Stake
    uint256 public periodFinish; // Encerramento Stake
    uint256 public rewardRate; // Gera a Recompensa por Token
    uint256 public rewardsDuration; // Duração da Pool
    uint256 public rewardPerTokenStored; // Armazena Recompensa Por Token
    uint256 private stakingDecimalRate = 10**18; // Fator Decimal
    uint256 public totalSupplyRewards; // Total Aportado dos Usuarios
    uint256 public harvTime; // Tempo entre Colheita
    /*=== Modifier ===*/
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastRewardTimeApplied();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
    /*=== Private/Internal/Public ===*/
    function blockHarvest() internal {
        harvestTime[_msgSender()] = block.timestamp + harvTime;
    }
    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        return a < b ? a : b;
    }
    function lastRewardTimeApplied() public view returns(uint256) {
        return min(block.timestamp, periodFinish);
    }
    function rewardPerToken() public view returns(uint256) {
        if(totalSupplyRewards == 0) {
            return rewardPerTokenStored;
        }
        return 
            rewardPerTokenStored.add(lastRewardTimeApplied()
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(stakingDecimalRate)
            .div(totalSupplyRewards));
    }
    function earned(address account) public view returns (uint256) {
        return         
            balanceUser[account]
            .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
            .div(stakingDecimalRate)
            .add(rewards[account]);
    }
    function harvestUser() public view returns(uint256) {
        uint256 currentTimes = block.timestamp;
        uint256 userHarv = harvestTime[_msgSender()];
        if(currentTimes >= userHarv) {
            return 0;
        }
        else {
            return userHarv - currentTimes;
        }
    }
    function getRewardForDuration() public view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }
    /*=== Administrativo ===*/
    function initRewards(uint256 rAmount, uint256 tDurantion) external onlyOwner updateReward(address(0)) {
        rewardRate = (rAmount * 10**18).div(tDurantion);
        periodFinish = block.timestamp + tDurantion;
        rewardsDuration = tDurantion;
        lastUpdateTime = block.timestamp;
    }
    function setHarvest(uint256 _harvTime) external onlyOwner {
        harvTime = _harvTime;
    }
}
