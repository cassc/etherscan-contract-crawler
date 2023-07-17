pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "./../iTrustVaultFactory.sol";
import "./BaseContract.sol";
import "./StakingDataController/StakeData.sol";
import "./StakingCalculation.sol";
import "./StakingDataController/RoundData.sol";

contract StakingData is BaseContract
{
    using SafeMathUpgradeable for uint;

    function initialize(
        address iTrustFactoryAddress
    ) 
        initializer 
        external 
    {
        _iTrustFactoryAddress = iTrustFactoryAddress;
        _locked = FALSE;
    }

    /**
     * Public functions
     */

     function _getTotalSupplyForBlockRange(address vaultAddress, uint endBlock, uint startBlock) internal returns(uint) {

        (bool success, bytes memory result) = 
            _stakeDataImplementationAddress()
                .delegatecall(
                    abi.encodeWithSelector(
                        StakeData.getTotalSupplyForBlockRange.selector,                       
                        vaultAddress, 
                        endBlock,
                        startBlock
                    )
                );
        require(success);
        return abi.decode(result, (uint256));
    }

    function _getTotalUnstakingsForBlockRange(address vaultAddress, uint endBlock, uint startBlock) internal returns(uint) {

        (bool success, bytes memory result) = 
            _stakeDataImplementationAddress()
                .delegatecall(
                    abi.encodeWithSelector(
                         StakeData.getTotalUnstakingsForBlockRange.selector,
                        vaultAddress, 
                        endBlock,
                        startBlock
                    )
                );
        require(success);
        return abi.decode(result, (uint256));
    }

    

     function addVault(address vaultAddress) external  {
        _validateFactory();
        _CurrentRoundNumbers[vaultAddress] = 1;
        _Rounds[vaultAddress][_CurrentRoundNumbers[vaultAddress]].startBlock = block.number;
        _updateTotalSupplyForBlock(0);
    }

    function endRound(address[] calldata tokens, uint[] calldata tokenAmounts,  bool[] calldata ignoreUnstakes, uint commission) external returns(bool) {
        _validateVault();

        address vaultAddress = _vaultAddress();
 
        uint startBlock = _Rounds[vaultAddress][_CurrentRoundNumbers[vaultAddress]].startBlock;
        (bool result, ) = _roundDataImplementationAddress()
            .delegatecall(
                abi.encodeWithSelector(
                RoundData.endRound.selector,
                vaultAddress, 
                tokens, 
                tokenAmounts, 
                ignoreUnstakes, 
                _getTotalSupplyForBlockRange(
                    vaultAddress, 
                    block.number, 
                    startBlock
                ),
                _getTotalUnstakingsForBlockRange(
                        vaultAddress, 
                        block.number, 
                        startBlock
                    ), 
                commission)
            );
      
        require(result);
        return true;
    }

    function getCurrentRoundData() external view returns(uint, uint, uint) {
        _validateVault();
        return _getRoundDataForAddress(_vaultAddress(), _CurrentRoundNumbers[_vaultAddress()]);
    }

    function getRoundData(uint roundNumberIn) external view returns(uint, uint, uint) {
        _validateVault();
        return _getRoundDataForAddress(_vaultAddress(), roundNumberIn);
    }

    function getRoundRewards(uint roundNumber) external  view 
    returns(
        address[] memory rewardTokens,
        uint[] memory rewardAmounts,
        uint[] memory commisionAmounts,
        uint[] memory tokenPerBlock, 
        uint[] memory totalSupply
    ) {
        _validateVault();
        return _getRoundRewardsForAddress(_vaultAddress(), roundNumber);
    }

    function startUnstake(address account, uint256 value) external returns(bool) {
        _validateVault();
        (bool result, ) = _stakeDataImplementationAddress()
            .delegatecall(abi.encodeWithSelector(StakeData.startUnstakeForAddress.selector, _vaultAddress(), account, value));
        return result;
    }

    function getAccountStakes(address account) external view 
    returns(
        uint stakingTotal,
        uint unStakingTotal,
        uint[] memory unStakingAmounts,
        uint[] memory unStakingStarts            
    ) {
        _validateVault();
        return _getAccountStakesForAddress(_vaultAddress(), account);
    }

    function getAccountStakingTotal(address account) external view returns (uint) {
        _validateVault();
        return _AccountStakes[_vaultAddress()][account].total.sub(_AccountUnstakingTotals[_vaultAddress()][account]);
    }

    function getAllAcountUnstakes() external view returns (address[] memory accounts, uint[] memory startTimes, uint[] memory values) {
        _validateVault();
        return _getAllAcountUnstakesForAddress(_vaultAddress());
    }

    function getAccountUnstakedTotal(address account) external view  returns (uint) {
        _validateVault();
        return _AccountUnstakedTotals[_vaultAddress()][account];
    }

    function authoriseUnstakes(address[] memory account, uint[] memory timestamp) external returns(bool) {
        _validateVault();
        require(account.length <= 10);        
        for(uint8 i = 0; i < account.length; i++) {
            _authoriseUnstake(_vaultAddress(), account[i], timestamp[i]);
        }        
        return true;
    }

    function withdrawUnstakedToken(address account, uint amount) external returns(bool)  {
        _validateVault();
        _nonReentrant();
        _locked = TRUE;

        address vaultAddress = _vaultAddress();
        require(_AccountUnstakedTotals[vaultAddress][account] > 0);
        require(amount <= _AccountUnstakedTotals[vaultAddress][account]);
        _AccountUnstakedTotals[vaultAddress][account] = _AccountUnstakedTotals[vaultAddress][account].sub(amount);
        _TotalUnstakedWnxm[vaultAddress] = _TotalUnstakedWnxm[vaultAddress].sub(amount);

        _locked = FALSE;
        return true;
    }

    function createStake(uint amount, address account) external returns(bool) {
        _validateVault();
        (bool result, ) = _stakeDataImplementationAddress()
            .delegatecall(abi.encodeWithSelector(StakeData.createStake.selector,_vaultAddress(),amount,account));
        return result;
    }

    function removeStake(uint amount, address account) external returns(bool) {
        _validateVault();
        (bool result, ) = _stakeDataImplementationAddress()
            .delegatecall(abi.encodeWithSelector(StakeData.removeStake.selector, _vaultAddress(), amount, account));
        return result;
    }

    function calculateRewards(address account) external view returns (address[] memory rewardTokens, uint[] memory rewards) {
        _validateVault();
        return _calculateRewards(account);
    }

    function withdrawRewards(address account, address[] memory rewardTokens, uint[] memory rewards) external returns(bool) {
        _validateVault();
        _nonReentrant();
        _locked = TRUE;
        _withdrawRewards(_vaultAddress(), rewardTokens, rewards, account);
        _locked = FALSE;
        return true;
    }

    function updateTotalSupplyForDayAndBlock(uint totalSupply) external returns(bool) {
        _validateVault();
        _updateTotalSupplyForBlock(totalSupply);
        return true;
    }

    function getTotalSupplyForAccountBlock(address vaultAddress, uint date) external view returns(uint) {
        _validateBurnContract();
        return _getTotalSupplyForAccountBlock(vaultAddress, date);
    }

    function getHoldingsForIndexAndBlockForVault(address vaultAddress, uint index, uint blockNumber) external view returns(address indexAddress, uint addressHoldings) {
        _validateBurnContract();
        return _getHoldingsForIndexAndBlock(vaultAddress, index, blockNumber);
    }

    function getNumberOfStakingAddressesForVault(address vaultAddress) external view returns(uint) {
        _validateBurnContract();
        return _AccountStakesAddresses[vaultAddress].length;
    }

    /**
     * Internal functions
     */

     function _getHoldingsForIndexAndBlock(address vaultAddress, uint index, uint blockNumber) internal view returns(address indexAddress, uint addressHoldings) {
        require(_AccountStakesAddresses[vaultAddress].length - 1 >= index);
        indexAddress = _AccountStakesAddresses[vaultAddress][index];
        bytes memory data = abi.encodeWithSelector(StakingCalculation.getHoldingsForBlockRange.selector, _AccountStakes[vaultAddress][indexAddress].stakes, blockNumber, blockNumber);        
        (, bytes memory resultData) = _stakingCalculationsAddress().staticcall(data);
        addressHoldings = abi.decode(resultData, (uint256));
        return(indexAddress, addressHoldings);
    }

     function _getTotalSupplyForAccountBlock(address vaultAddress, uint blockNumber) internal view returns(uint) {
        uint index =  _getIndexForBlock(vaultAddress, blockNumber, 0);
        return _TotalSupplyHistory[vaultAddress][_TotalSupplyKeys[vaultAddress][index]];
    }

     function _authoriseUnstake(address vaultAddress, address account, uint timestamp) internal {
        (bool result, ) = _stakeDataImplementationAddress()
            .delegatecall(abi.encodeWithSelector(StakeData.authoriseUnstake.selector, vaultAddress, account, timestamp));            
        require(result);
    }

    function _updateTotalSupplyForBlock(uint totalSupply) public returns(bool) {
        if(_TotalSupplyHistory[_vaultAddress()][block.number] == 0){  // Assumes there will never be 0, could use the array itself to check will look at this again
            _TotalSupplyKeys[_vaultAddress()].push(block.number);
        }

        _TotalSupplyHistory[_vaultAddress()][block.number] = totalSupply;
        return true;
    }


    function _getRoundDataForAddress(address vaultAddress, uint roundNumberIn) internal view returns(uint roundNumber, uint startBlock, uint endBlock) {
        roundNumber = roundNumberIn;
        startBlock = _Rounds[vaultAddress][roundNumber].startBlock;
        endBlock = _Rounds[vaultAddress][roundNumber].endBlock;
        return( 
            roundNumber,
            startBlock,
            endBlock
        );
    }

    function _getRoundRewardsForAddress(address vaultAddress, uint roundNumber) internal view 
    returns(
        address[] memory rewardTokens,
        uint[] memory rewardAmounts,
        uint[] memory commissionAmounts,
        uint[] memory tokenPerBlock,        
        uint[] memory totalSupply
    ) {
        rewardTokens = new address[](totalRewardTokenAddresses[vaultAddress].length);
        rewardAmounts = new uint[](totalRewardTokenAddresses[vaultAddress].length);
        commissionAmounts = new uint[](totalRewardTokenAddresses[vaultAddress].length);
        tokenPerBlock = new uint[](totalRewardTokenAddresses[vaultAddress].length);
        totalSupply  = new uint[](totalRewardTokenAddresses[vaultAddress].length);
        for(uint i = 0; i < totalRewardTokenAddresses[vaultAddress].length; i++){
            rewardTokens[i] = totalRewardTokenAddresses[vaultAddress][i];
            rewardAmounts[i] = _Rounds[vaultAddress][roundNumber].roundData[totalRewardTokenAddresses[vaultAddress][i]].amount;
            commissionAmounts[i] = _Rounds[vaultAddress][roundNumber].roundData[totalRewardTokenAddresses[vaultAddress][i]].commissionAmount;
            tokenPerBlock[i] = _Rounds[vaultAddress][roundNumber].roundData[totalRewardTokenAddresses[vaultAddress][i]].tokenPerBlock;
            totalSupply[i] = _Rounds[vaultAddress][roundNumber].roundData[totalRewardTokenAddresses[vaultAddress][i]].totalSupply;
        }
        return( 
            rewardTokens,
            rewardAmounts,
            commissionAmounts,
            tokenPerBlock,
            totalSupply
        );
    }

    function _getIndexForBlock(address vaultAddress, uint startBlock, uint startIndex) internal view returns(uint) {
        uint i = startIndex == 0 ? _TotalSupplyKeys[vaultAddress].length.sub(1) : startIndex;
        uint blockForIndex = _TotalSupplyKeys[vaultAddress][i];
        
        if(_TotalSupplyKeys[vaultAddress][0] > startBlock){
            return 0;
        }

        if(blockForIndex < startBlock){
            return i;
        }

        while(blockForIndex > startBlock){
            i = i.sub(1);
            blockForIndex = _TotalSupplyKeys[vaultAddress][i];
        }

        return i;
    }

    function _getAccountStakesForAddress(address vaultAddress, address account) internal view 
    returns(
        uint stakingTotal,
        uint unStakingTotal,
        uint[] memory unStakingAmounts,
        uint[] memory unStakingStarts            
    ) {
        unStakingAmounts = new uint[](_AccountUnstakings[vaultAddress][account].length);
        unStakingStarts = new uint[](_AccountUnstakings[vaultAddress][account].length);
        for(uint i = 0; i < _AccountUnstakings[vaultAddress][account].length; i++){
            if(_AccountUnstakings[vaultAddress][account][i].endBlock == 0){
                unStakingAmounts[i] = _AccountUnstakings[vaultAddress][account][i].amount;
                unStakingStarts[i] = _AccountUnstakings[vaultAddress][account][i].startDateTime;
            }
        }
        return( 
            _AccountStakes[vaultAddress][account].total.sub(_AccountUnstakingTotals[vaultAddress][account]),
            _AccountUnstakingTotals[vaultAddress][account],
            unStakingAmounts,
            unStakingStarts
        );
    }

    function _getAllAcountUnstakesForAddress(address vaultAddress) internal view returns (address[] memory accounts, uint[] memory startTimes, uint[] memory values) {
        accounts = new address[](_UnstakingRequests[vaultAddress].length);
        startTimes = new uint[](_UnstakingRequests[vaultAddress].length);
        values = new uint[](_UnstakingRequests[vaultAddress].length);
        for(uint i = 0; i < _UnstakingRequests[vaultAddress].length; i++) {
            if(_UnstakingRequests[vaultAddress][i].endBlock == 0 ) {
                accounts[i] = _UnstakingRequests[vaultAddress][i].account;
                startTimes[i] = _UnstakingRequests[vaultAddress][i].startDateTime;
                values[i] = _UnstakingRequests[vaultAddress][i].amount;
            }
        }        
        return(accounts, startTimes, values);
    }

    function getUnstakedWxnmTotal() external view returns(uint total) {
        _validateVault();
        total = _TotalUnstakedWnxm[_vaultAddress()];
    }

    function _calculateRewards(address account) internal view  returns (address[] memory rewardTokens, uint[] memory rewards) {
        rewardTokens = totalRewardTokenAddresses[_vaultAddress()];
        rewards = new uint[](rewardTokens.length);

        for(uint x = 0; x < totalRewardTokenAddresses[_vaultAddress()].length; x++){            
            (rewards[x]) = _calculateReward(_vaultAddress(), account, rewardTokens[x]);            
            rewards[x] = rewards[x].div(1 ether);
        }

        return (rewardTokens, rewards);
    }

     function _calculateReward(address vaultAddress, address account, address rewardTokenAddress) internal view returns (uint reward){
        VaultLib.ClaimedReward memory claimedReward = _AccountRewards[vaultAddress][account][rewardTokenAddress];

        if(_RewardStartingRounds[vaultAddress][rewardTokenAddress] == 0){            
            return(0);
        }

        uint futureRoundNumber = _CurrentRoundNumbers[vaultAddress] - 1;// one off as the current hasnt closed
        address calcContract = _stakingCalculationsAddress();
        while(claimedReward.lastClaimedRound < futureRoundNumber 
                && _RewardStartingRounds[vaultAddress][rewardTokenAddress] <= futureRoundNumber
                && futureRoundNumber != 0 )
        {

            if(_Rounds[vaultAddress][futureRoundNumber].roundData[rewardTokenAddress].amount == 0){
                futureRoundNumber--;
                continue;
            }

            (, bytes memory resultData) = calcContract.staticcall(abi.encodeWithSignature(
                "getHoldingsForBlockRange((uint256,uint256,uint256,uint256)[],uint256,uint256)", 
                _AccountStakes[vaultAddress][account].stakes, 
                _Rounds[vaultAddress][futureRoundNumber].startBlock, 
                _Rounds[vaultAddress][futureRoundNumber].endBlock
            ));
            uint holdingsForRound = abi.decode(resultData, (uint256));

            if (!(_Rounds[vaultAddress][futureRoundNumber].roundData[rewardTokenAddress].ignoreUnstakes)) {
                (, bytes memory unstakedResultData) = calcContract.staticcall(abi.encodeWithSignature(
                    "getUnstakingsForBlockRange((address,uint256,uint256,uint256,uint256)[],uint256,uint256)", 
                    _AccountUnstakings[vaultAddress][account], 
                    _Rounds[vaultAddress][futureRoundNumber].startBlock, 
                    _Rounds[vaultAddress][futureRoundNumber].endBlock
                ));
                holdingsForRound = holdingsForRound.sub(abi.decode(unstakedResultData, (uint256)));
            }
           
            holdingsForRound = VaultLib.divider(
                     holdingsForRound, 
                     _Rounds[vaultAddress][futureRoundNumber].roundData[rewardTokenAddress].totalSupply, 
                     18)
                     .mul(_Rounds[vaultAddress][futureRoundNumber].roundData[rewardTokenAddress].amount);
            reward = reward.add(holdingsForRound);
            futureRoundNumber--;
        }

        return (reward);
    }

    function _withdrawRewards(address vaultAddress, address[] memory rewardTokens, uint[] memory rewards, address account) internal {
          
        for (uint x = 0; x < rewardTokens.length; x++){
            _AccountRewards[vaultAddress][account][rewardTokens[x]].amount = _AccountRewards[vaultAddress][account][rewardTokens[x]].amount + rewards[x];
            _AccountRewards[vaultAddress][account][rewardTokens[x]].lastClaimedRound = _CurrentRoundNumbers[vaultAddress] - 1;
        }

    }

    function _vaultAddress() internal view returns(address) {
        return _msgSender();
    }

    function _roundDataImplementationAddress() internal view returns(address) {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        return vaultFactory.getRoundDataImplementationAddress();
    }

    function _stakeDataImplementationAddress() internal view returns(address) {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        return vaultFactory.getStakeDataImplementationAddress();
    }

    function _stakingCalculationsAddress() internal view returns(address) {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        return address(vaultFactory.getStakingCalculationsAddress());
    }

    /**
     * Validate functions
     */

    function _validateVault() internal view {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        require(vaultFactory.isActiveVault(_vaultAddress()));
    }

    function _validateBurnContract() internal view {
        ITrustVaultFactory vaultFactory = ITrustVaultFactory(_iTrustFactoryAddress);
        require(vaultFactory.isBurnAddress(_msgSender()));
    }

    function _validateFactory() internal view {
        require(_msgSender() == _iTrustFactoryAddress);
    }

}