pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "./../BaseContract.sol";
import "./../GovernanceDistribution.sol";

contract StakeDataV2 is BaseContract
{    
    using SafeMathUpgradeable for uint;

    function startUnstakeForAddress(address vaultAddress, address account, uint256 value) external  {
        require( 
            ( _AccountStakes[vaultAddress][account].total.sub(_AccountUnstakingTotals[vaultAddress][account]) ) 
            >= value);

        _AccountUnstakingTotals[vaultAddress][account] =_AccountUnstakingTotals[vaultAddress][account].add(value);
        VaultLib.UnStaking memory unstaking = VaultLib.UnStaking(account, value, block.timestamp, block.number, 0 );
        _AccountUnstakings[vaultAddress][account].push(unstaking);
        _UnstakingRequests[vaultAddress].push(unstaking);
        _UnstakingAddresses[vaultAddress].push(account);
        _TotalUnstakingKeys[vaultAddress].push(block.number);
        _TotalUnstakingHistory[vaultAddress][block.number]  = unstaking;
    }

    function authoriseUnstake(address vaultAddress, address account, uint timestamp, uint amount) external {
        uint requestedAmount = 0;
        for(uint i = 0; i < _AccountUnstakings[vaultAddress][account].length; i++){
            if(_AccountUnstakings[vaultAddress][account][i].startDateTime == timestamp) {
                requestedAmount = _AccountUnstakings[vaultAddress][account][i].amount;
                _AccountUnstakings[vaultAddress][account][i].amount = amount;
                _AccountUnstakedTotals[vaultAddress][account] = _AccountUnstakedTotals[vaultAddress][account] + amount;
                _AccountUnstakings[vaultAddress][account][i].endBlock = block.number;
                _AccountUnstakingTotals[vaultAddress][account] = _AccountUnstakingTotals[vaultAddress][account] - requestedAmount;
                _TotalUnstakedWnxm[vaultAddress] = _TotalUnstakedWnxm[vaultAddress].add(amount);
                break;
            }
        }

        for(uint i = 0; i < _UnstakingRequests[vaultAddress].length; i++){
            if(_UnstakingRequests[vaultAddress][i].startDateTime == timestamp &&
                _UnstakingRequests[vaultAddress][i].amount == requestedAmount &&
                _UnstakingRequests[vaultAddress][i].endBlock == 0 &&
                _UnstakingAddresses[vaultAddress][i] == account) 
            {
                    delete _UnstakingAddresses[vaultAddress][i];
                    _UnstakingRequests[vaultAddress][i].amount = amount;
                    _UnstakingRequests[vaultAddress][i].endBlock = block.number;
                    _TotalUnstakingHistory[vaultAddress]
                        [_UnstakingRequests[vaultAddress][i].startBlock].endBlock = block.number;
            }
        }
        
        _AccountStakes[vaultAddress][account].total = _AccountStakes[vaultAddress][account].total.sub(amount);
        _AccountStakes[vaultAddress][account].stakes.push(VaultLib.Staking(block.timestamp, block.number, amount, _AccountStakes[vaultAddress][account].total));
        _governanceDistributionContract().removeStake(account, amount);
        
    }

    function createStake(address vaultAddress, uint amount, address account) external {

        if( _AccountStakes[vaultAddress][account].startRound == 0) {
            _AccountStakes[vaultAddress][account].startRound = _CurrentRoundNumbers[vaultAddress];
            _AccountStakesAddresses[vaultAddress].push(account);
        }

        _AccountStakes[vaultAddress][account].total = _AccountStakes[vaultAddress][account].total.add(amount);
        // block number is being used to record the block at which staking started for governance token distribution
        _AccountStakes[vaultAddress][account].stakes.push(
            VaultLib.Staking(block.timestamp, block.number, amount, _AccountStakes[vaultAddress][account].total)
        );
        _governanceDistributionContract().addStake(account, amount);
    }

    function removeStake(address vaultAddress, uint amount, address account) external {

        if( _AccountStakes[vaultAddress][account].startRound == 0) {
            _AccountStakes[vaultAddress][account].startRound = _CurrentRoundNumbers[vaultAddress];
             _AccountStakesAddresses[vaultAddress].push(account);
        }

        require(_AccountStakes[vaultAddress][account].total >= amount);

        _AccountStakes[vaultAddress][account].total = _AccountStakes[vaultAddress][account].total.sub(amount);
        // block number is being used to record the block at which staking started for governance token distribution
        _AccountStakes[vaultAddress][account].stakes.push(
            VaultLib.Staking(block.timestamp, block.number, amount, _AccountStakes[vaultAddress][account].total)
        );
        _governanceDistributionContract().removeStake(account, amount);
    }

    function _governanceDistributionAddress() internal view returns(address) {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        return vaultFactory.getGovernanceDistributionAddress();
    }

    function _governanceDistributionContract() internal view returns(GovernanceDistribution) {
        return GovernanceDistribution(_governanceDistributionAddress());
    }

    function getTotalUnstakingsForBlockRange(address vaultAddress, uint endBlock, uint startBlock) external view returns(uint) {
         // If we have bad data, no supply data or it starts after the block we are looking for then we can return zero
        if(endBlock < startBlock 
            || _TotalUnstakingKeys[vaultAddress].length == 0 
            || _TotalUnstakingKeys[vaultAddress][0] > endBlock){
            return 0;
        }

        uint lastIndex = _TotalUnstakingKeys[vaultAddress].length - 1;
        uint total;
        uint diff;
        uint stakeEnd;
        uint stakeStart;
        if(_TotalUnstakingHistory[vaultAddress][_TotalUnstakingKeys[vaultAddress][lastIndex]].endBlock < startBlock
            && lastIndex == 0) {
            return 0;
        }
        
        //last index should now be in our range so loop through until all block numbers are covered
        while( lastIndex >= 0 ) {

            if( _TotalUnstakingHistory[vaultAddress][_TotalUnstakingKeys[vaultAddress][lastIndex]].endBlock < startBlock &&
                _TotalUnstakingHistory[vaultAddress][_TotalUnstakingKeys[vaultAddress][lastIndex]].endBlock != 0 )
            {
                if (lastIndex == 0) {
                    break;
                }
                lastIndex = lastIndex.sub(1);
                continue;
            }

            stakeEnd = _TotalUnstakingHistory[vaultAddress][_TotalUnstakingKeys[vaultAddress][lastIndex]].endBlock == 0 
                ? endBlock : _TotalUnstakingHistory[vaultAddress][_TotalUnstakingKeys[vaultAddress][lastIndex]].endBlock;

            stakeEnd = (stakeEnd >= endBlock ? endBlock : stakeEnd);

            stakeStart = _TotalUnstakingHistory[vaultAddress][_TotalUnstakingKeys[vaultAddress][lastIndex]].startBlock < startBlock 
                ? startBlock : _TotalUnstakingHistory[vaultAddress][_TotalUnstakingKeys[vaultAddress][lastIndex]].startBlock;
            
            diff = (stakeEnd == stakeStart ? 1 : stakeEnd.sub(stakeStart));
           
            total = total.add(_TotalUnstakingHistory[vaultAddress][_TotalUnstakingKeys[vaultAddress][lastIndex]].amount.mul(diff));
           

            if(lastIndex == 0){
                break;
            } 

            lastIndex = lastIndex.sub(1); 
        }

        return total;
    }

    function getTotalSupplyForBlockRange(address vaultAddress, uint endBlock, uint startBlock) external view returns(uint) {

        // If we have bad data, no supply data or it starts after the block we are looking for then we can return zero
        if(endBlock < startBlock 
            || _TotalSupplyKeys[vaultAddress].length == 0 
            || _TotalSupplyKeys[vaultAddress][0] > endBlock){
            return 0;
        }
        uint lastIndex = _TotalSupplyKeys[vaultAddress].length - 1;
        
        // If the last total supply is before the start we are looking for we can take the last value
        if(_TotalSupplyKeys[vaultAddress][lastIndex] <= startBlock){
            return _TotalSupplyHistory[vaultAddress][_TotalSupplyKeys[vaultAddress][lastIndex]].mul(endBlock.sub(startBlock));
        }

        // working our way back we need to get the first index that falls into our range
        // This could be large so need to think of a better way to get here
        while(lastIndex > 0 && _TotalSupplyKeys[vaultAddress][lastIndex] > endBlock){
            if(lastIndex == 0){
                break;
            } 
            lastIndex = lastIndex.sub(1);
        }

        uint total;
        uint diff;
        //last index should now be in our range so loop through until all block numbers are covered
       
        while(_TotalSupplyKeys[vaultAddress][lastIndex] >= startBlock) {  
            diff = 0;
            if(_TotalSupplyKeys[vaultAddress][lastIndex] <= startBlock){
                diff = endBlock.sub(startBlock) == 0 ? 1 : endBlock.sub(startBlock);
                total = total.add(_TotalSupplyHistory[vaultAddress][_TotalSupplyKeys[vaultAddress][lastIndex]].mul(diff));
                break;
            }
            
            diff = endBlock.sub(_TotalSupplyKeys[vaultAddress][lastIndex]) == 0 ? 1 : endBlock.sub(_TotalSupplyKeys[vaultAddress][lastIndex]);
            total = total.add(_TotalSupplyHistory[vaultAddress][_TotalSupplyKeys[vaultAddress][lastIndex]].mul(diff));
            endBlock = _TotalSupplyKeys[vaultAddress][lastIndex];

            if(lastIndex == 0){
                break;
            } 

            lastIndex = lastIndex.sub(1); 
        }

        // If the last total supply is before the start we are looking for we can take the last value
        if(_TotalSupplyKeys[vaultAddress][lastIndex] <= startBlock && startBlock < endBlock){
            total = total.add(_TotalSupplyHistory[vaultAddress][_TotalSupplyKeys[vaultAddress][lastIndex]].mul(endBlock.sub(startBlock)));
        }
 
        return total;
    }

}