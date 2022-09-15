pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IGeneralNFTReward.sol";

/**
 * A contract to update reward for NFT pool every 7 days
 */
contract InsuranceFundV1 is Ownable {
    IGeneralNFTReward public generalNFTReward;
    IERC20 public spyn;

    constructor(
        IERC20 _spyn,
        address _generalNFTReward
    ) {
        spyn = _spyn;
        generalNFTReward = IGeneralNFTReward(_generalNFTReward);
    }

    function approveNFTReward() public {
        spyn.approve(address(generalNFTReward), type(uint256).max);
    }

    // set new rewards distributing in 7 days for GeneralNFTRewards
    function notifyReward(uint256 amount) external onlyOwner {
        require(block.timestamp >= generalNFTReward._periodFinish(), "Not time to reset");
        require(spyn.balanceOf(address(this)) >= amount, "Not enough balance");
        generalNFTReward.notifyReward(amount);
    }

    // change GeneralNFTRewards
    function changeGeneralNFTGovernance(address governance) external onlyOwner {
        generalNFTReward.setGovernance(governance);
    }
    function setDepositFeeRate( uint256 depositFeeRate ) public onlyOwner {
        generalNFTReward.setDepositFeeRate(depositFeeRate);
    }
    function setBurnFeeRate( uint256 burnFeeRate ) public onlyOwner {
        generalNFTReward.setBurnFeeRate(burnFeeRate);
    }
    function setSpynFeeRate( uint256 spynFeeRate ) public onlyOwner {
        generalNFTReward.setSpynFeeRate(spynFeeRate);
    }
    function setHarvestFeeRate( uint256 harvestFeeRate ) external onlyOwner {
        generalNFTReward.setHarvestFeeRate(harvestFeeRate);
    }
    function setHarvestInterval( uint256  harvestInterval ) external onlyOwner {
        generalNFTReward.setHarvestInterval(harvestInterval);
    }
    function setExtraHarvestInterval( uint256  extraHarvestInterval ) external onlyOwner{
        generalNFTReward.setExtraHarvestInterval(extraHarvestInterval);
    }
    function setRewardPool( address  rewardPool ) external onlyOwner {
        generalNFTReward.setRewardPool(rewardPool);
    }
    function setMaxStakedDego(uint256 amount) external onlyOwner {
        generalNFTReward.setMaxStakedDego(amount);
    }

    function setMigrateToContract(address migrateToContract) external onlyOwner {
        generalNFTReward.setMigrateToContract(migrateToContract);
    }
    function setMigrateFromContract(address migrateFromContract) external onlyOwner {
        generalNFTReward.setMigrateFromContract(migrateFromContract);
    }
}