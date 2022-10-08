// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;
import "@solidstate/contracts/access/ownable/Ownable.sol";
import "../libraries/LibKoboldStaking.sol";
///@author @0xSimon_

contract KoboldStakingFacet is Ownable {
    
    function getSigner() external view returns(address) {
        return LibKoboldStaking.getSigner();
    }
    function getKoboldAccumulatedReward(uint koboldTokenId) external view returns(uint){
        return LibKoboldStaking.getKoboldAccumulatedReward(koboldTokenId);
    }
     function nextRewardForKobold(uint koboldId) external view returns(uint) {
        return LibKoboldStaking.nextReward(koboldId);
    }
    function viewKoboldTotalReward(uint koboldId) external view returns(uint) {
        return LibKoboldStaking.viewTokenTotalReward(koboldId);
    }
    function getRewardPerSecond() external view returns(uint) {
        return LibKoboldStaking.getRewardPerSecond();
    }
    function getAcceptableTimelag() external view returns(uint) {
        return LibKoboldStaking.getAcceptableTimelag();
    }
    // function getRewardPerSecond() ex

    //Setters
    function setRewardPerSecond(uint newRewardPerSecond) external onlyOwner{
        LibKoboldStaking.setRewardPerSecond(newRewardPerSecond);
    }
    function setSigner(address _signer) external onlyOwner {
        LibKoboldStaking.setSigner(_signer);
    }
    function setAcceptableTimelag(uint newAcceptableTimelag) external onlyOwner{
        LibKoboldStaking.setAcceptableTimelag(newAcceptableTimelag);
    }
    
   //Staking Functions
    function startKoboldBatchStake(uint[] calldata tokenIds) external {
        LibKoboldStaking.startKoboldBatchStake(tokenIds);
    }
    function endKoboldBatchStake(uint[] calldata tokenIds) external {
        LibKoboldStaking.endKoboldBatchStake(tokenIds);
    }
    //Withdraw Function
    function withdrawReward(uint[] calldata tokenIds,
      uint[] calldata healthPoints,
    uint referenceTimestamp,
    bytes memory signature
    ) external {
        LibKoboldStaking.withdrawReward(tokenIds,
        healthPoints,referenceTimestamp,signature);
    }
    function withdrawRewardWithMultiplier(uint[] calldata tokenIds,
    uint koboldMultiplierId,
    uint[] calldata healthPoints,
    uint referenceTimestamp,
    bytes memory signature) external {
        LibKoboldStaking.withdrawRewardWithMultiplier(tokenIds,
        koboldMultiplierId,healthPoints,referenceTimestamp,signature);
    }


}