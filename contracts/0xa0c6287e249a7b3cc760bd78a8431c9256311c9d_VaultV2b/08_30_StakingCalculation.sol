pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./../iTrustVaultFactory.sol";
import "./BaseContract.sol";
import "./StakingDataController/StakeData.sol";

import { ITrustVaultLib as VaultLib } from "./../libraries/ItrustVaultLib.sol"; 

contract StakingCalculation
{
    using SafeMath for uint;

    // function getRoundDataForAccount(
    //     VaultLib.Staking[] memory stakes,
    //     VaultLib.UnStaking[] memory unstakes,
    //     uint startBlock, 
    //     uint endBlock) external pure 
    //     returns (uint totalHoldings, uint[] memory stakeBlocks, uint[] memory stakeAmounts, uint[] memory unstakeStartBlocks, uint[] memory unstakeEndBlocks, uint[] memory unstakeAmounts)
    // {
        
    //     totalHoldings = VaultLib.getHoldingsForBlockRange(stakes, startBlock, endBlock);

    //     (stakeBlocks, stakeAmounts) = VaultLib.getRoundDataStakesForAccount(stakes, startBlock, endBlock);

    //     (unstakeStartBlocks, unstakeEndBlocks, unstakeAmounts) = VaultLib.getRoundDataUnstakesForAccount(unstakes, startBlock, endBlock);

    //     return (totalHoldings, stakeBlocks, stakeAmounts, unstakeStartBlocks, unstakeEndBlocks, unstakeAmounts);
    // }

    function getUnstakingsForBlockRange(
        VaultLib.UnStaking[] memory unStakes, 
        uint startBlock, 
        uint endBlock) external pure returns (uint){
        return VaultLib.getUnstakingsForBlockRange(
                        unStakes, 
                        startBlock, 
                        endBlock
                    );
    }

    function getHoldingsForBlockRange(
        VaultLib.Staking[] memory stakes,
        uint startBlock, 
        uint endBlock) external pure returns (uint){
        
        return VaultLib.getHoldingsForBlockRange(
                    stakes, 
                    startBlock, 
                    endBlock);
    }

}