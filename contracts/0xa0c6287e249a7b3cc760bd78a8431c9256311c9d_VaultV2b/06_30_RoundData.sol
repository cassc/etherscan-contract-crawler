pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "./../BaseContract.sol";

contract RoundData is BaseContract
{
    using SafeMathUpgradeable for uint;
    
    function endRound(
        address vaultAddress, 
        address[] memory tokens, 
        uint[] memory tokenAmounts, 
        bool[] memory ignoreUnstakes,        
        uint totalSupplyForBlockRange, 
        uint totalUnstakings,
        uint commissionValue) 
        external 
    {
        require( _Rounds[vaultAddress][_CurrentRoundNumbers[vaultAddress]].startBlock < block.number);       
        uint32 roundNumber = _CurrentRoundNumbers[vaultAddress];
        uint rewardAmount;
        uint commissionAmount;
        uint tokensPerBlock; //Amoun

        for (uint i=0; i < tokens.length; i++) {    
              
            rewardAmount = tokenAmounts[i].sub(tokenAmounts[i].mul(commissionValue).div(10000));
            commissionAmount = tokenAmounts[i].mul(commissionValue).div(10000);
            tokensPerBlock = VaultLib.divider(rewardAmount, _getAdjustedTotalSupply(totalSupplyForBlockRange, totalUnstakings, ignoreUnstakes[i]), 18);
            VaultLib.RewardTokenRoundData memory tokenData = VaultLib.RewardTokenRoundData(
                {
                    tokenAddress: tokens[i],
                    amount: rewardAmount,
                    commissionAmount: commissionAmount,
                    tokenPerBlock: tokensPerBlock,//.div(1e18),
                    totalSupply: _getAdjustedTotalSupply(totalSupplyForBlockRange, totalUnstakings, ignoreUnstakes[i]),  
                    ignoreUnstakes: ignoreUnstakes[i]
                }
            );

            _Rounds[vaultAddress][roundNumber].roundData[tokens[i]] = tokenData;            
           
            if(_RewardTokens[vaultAddress][tokens[i]] != TRUE){
                _RewardStartingRounds[vaultAddress][tokens[i]] = roundNumber;
                totalRewardTokenAddresses[vaultAddress].push(tokens[i]);
                _RewardTokens[vaultAddress][tokens[i]] = TRUE;
            }
        }

        //do this last
        _Rounds[vaultAddress][_CurrentRoundNumbers[vaultAddress]].endBlock = block.number;
        _CurrentRoundNumbers[vaultAddress]++;
        _Rounds[vaultAddress][_CurrentRoundNumbers[vaultAddress]].startBlock = block.number;
        
    }

    function _getAdjustedTotalSupply(uint totalSupply, uint totalUnstaking, bool ignoreUnstaking) internal pure returns(uint) {
        if(ignoreUnstaking) {
            return totalSupply;
        }
        return (totalUnstaking > totalSupply ? 0 : totalSupply.sub(totalUnstaking));
    }

}