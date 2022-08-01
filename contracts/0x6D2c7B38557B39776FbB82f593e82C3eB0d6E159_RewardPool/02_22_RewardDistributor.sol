// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IRewardPool.sol";

contract RewardDistributor is Ownable {
    using Address for address payable;
    using SafeMath for uint256;

    IERC20 public rewardToken;
    IRewardPool public rewardPool;
    uint256 public totalRewardsDistributed;

    constructor(address _rewardToken) {
        rewardPool = IRewardPool(_msgSender());
        rewardToken = IERC20(_rewardToken);
    }

    modifier onlyOperator() {
        require(_msgSender() == address(rewardPool) ,"onlyOperator");
        _;
    }

    function setRewardPool(address _rewardPool) external onlyOwner {
        require(_rewardPool != address(0), "Can't be zero");
        rewardPool = IRewardPool(_rewardPool);
    } 

    function distributeReward(address account,uint256 amount) external onlyOperator returns (bool){
        rewardToken.transfer(account, amount);

        totalRewardsDistributed = totalRewardsDistributed.add(amount); 

        return true;     
    }
    
    function recoverLeftOverBNB(uint256 amount) external onlyOwner {
        payable(owner()).sendValue(amount);
    }

    function recoverLeftOverToken(address token,uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(),amount);
    }

    function rewardOf(address account) external view returns(uint256) {
        return rewardPool.rewardOf(address(rewardToken),account);
    }

    function withdrawnRewardOf(address account) external view returns(uint256) {
        return rewardPool.withdrawnRewardOf(address(rewardToken),account);
    }   
}