// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;
import "./LibAppStorage.sol";
import "../interfaces/IAppStorage.sol";
import "../../interfaces/IKobolds.sol";
import "../../interfaces/IIngotToken.sol";
import "./LibKoboldMultipliers.sol";
import "../interfaces/IKoboldMultiplier.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

///@author @0xSimon_
library LibKoboldStaking {
    using ECDSA for bytes32;
    //Storage
    bytes32 internal constant NAMESPACE = keccak256("titanforge.kobold.staking");
    struct KoboldStaker {
        uint256 accumulatedRewards;
        uint256 lastUpdateTimestamp;
    }
    struct Storage{
        uint256 acceptableTimelag;
        uint256 rewardPerSecond;
        address signer;
        mapping(uint256 => KoboldStaker) koboldStaker;
    }
    
    function getStorage() internal pure returns(Storage storage s)  {
        bytes32 position = NAMESPACE;
        assembly{
            s.slot := position
        }
    }
    function getSigner() internal view returns(address) {
        Storage storage s = getStorage();
        return s.signer;
    }
    
    function getKoboldAccumulatedReward(uint koboldTokenId) internal view returns(uint){
        Storage storage s = getStorage();
        return s.koboldStaker[koboldTokenId].accumulatedRewards;
    }

     function nextReward(uint tokenId) internal view returns(uint) {
        Storage storage s = getStorage();
        KoboldStaker memory staker =  s.koboldStaker[tokenId];
        if(staker.lastUpdateTimestamp == 0) return 0;
        uint timeDelta = block.timestamp - staker.lastUpdateTimestamp;
        uint reward = s.rewardPerSecond * timeDelta;
        return reward;
    }
    function viewTokenTotalReward(uint tokenId) internal view returns(uint) {
        Storage storage s = getStorage();
        return  s.koboldStaker[tokenId].accumulatedRewards + nextReward(tokenId);
    }
    function getRewardPerSecond() internal view returns(uint) {
        Storage storage s = getStorage();
        return s.rewardPerSecond;
    }

    function getAcceptableTimelag() internal view returns(uint) {
        Storage storage s = getStorage();
        return s.acceptableTimelag;
    }

        function setRewardPerSecond(uint newRewardPerSecond) internal {
        Storage storage s = getStorage();
        s.rewardPerSecond = newRewardPerSecond;
    }
    function setSigner(address _signer) internal {
        Storage storage s = getStorage();
        s.signer = _signer;
    }
    function setAcceptableTimelag(uint newAcceptableTimelag) internal {
        Storage storage s = getStorage();
        s.acceptableTimelag = newAcceptableTimelag;
    }
    function setKoboldAccumulatedReward(uint koboldTokenId,uint reward) internal {
         Storage storage s = getStorage();
         s.koboldStaker[koboldTokenId].accumulatedRewards = reward;

    }

    function updateReward(uint[] calldata tokenIds) internal {
        AppStorage storage appStorage = LibAppStorage.appStorage();
        Storage storage s = getStorage();
        bool[] memory stakedStatus = iKobolds(appStorage.koboldAddress).checkIfBatchIsStaked(tokenIds);
        for(uint i; i<tokenIds.length;) {
        uint tokenId = tokenIds[i];
            require(msg.sender == iKobolds(appStorage.koboldAddress).ownerOf(tokenId),"Not Owner");
            uint256 reward = nextReward(tokenId);
            KoboldStaker memory staker = s.koboldStaker[tokenId];
            staker.accumulatedRewards += reward;
            //If Token Is Staking Then Update the Timestamp
            if(stakedStatus[0]) {
                staker.lastUpdateTimestamp = block.timestamp;
            }
            //Else Set Timestamp To Zero
            //This works because we first call batchStake or batchUnstake and then we call updateReward
            else{
                staker.lastUpdateTimestamp = 0;
            }
            s.koboldStaker[tokenId] = staker;
            unchecked{++i;}
        }
    }

    function startKoboldBatchStake(uint[] calldata tokenIds) internal {
        AppStorage storage appStorage = LibAppStorage.appStorage();
        iKobolds(appStorage.koboldAddress).batchStake(tokenIds);
        updateReward(tokenIds);
    }
    function endKoboldBatchStake(uint[] calldata tokenIds) internal {
        AppStorage storage appStorage = LibAppStorage.appStorage();
        iKobolds(appStorage.koboldAddress).batchUnstake(tokenIds);
        updateReward(tokenIds);
    }
    function isValidTimestamp(uint referenceTimestamp,uint acceptableTimelag) internal view returns(bool) {
        return  referenceTimestamp + acceptableTimelag > block.timestamp;
    }

    function withdrawReward(uint[] calldata tokenIds,
    uint[] calldata healthPoints,
    uint referenceTimestamp,
    bytes memory signature) internal {

        Storage storage s = getStorage();
        updateReward(tokenIds);
        require(isValidTimestamp(referenceTimestamp,s.acceptableTimelag),"Signature Expired");
        bytes32 hash = keccak256(abi.encodePacked(referenceTimestamp,tokenIds,"KHPS",healthPoints));
        address _signer = s.signer;
        require(_signer != address(0),"Signer Not Init"); 
        if(hash.toEthSignedMessageHash().recover(signature) != _signer) revert ("Invalid Signer");
        uint totalReward;
        for(uint i; i<tokenIds.length;){
        uint tokenId = tokenIds[i];
        uint rewardFromToken = viewTokenTotalReward(tokenId);
        unchecked{
            totalReward = ((totalReward + rewardFromToken) * healthPoints[i]) / 100;
        }
        delete s.koboldStaker[tokenId].accumulatedRewards;
        unchecked{++i;}
        }
        AppStorage storage appStorage = LibAppStorage.appStorage();
        iIngotToken(appStorage.ingotTokenAddress).mint(msg.sender,totalReward);
    }

    function withdrawRewardWithMultiplier(uint[] calldata tokenIds, uint koboldMultiplierId,
    uint[] calldata healthPoints,
    uint referenceTimestamp,
    bytes memory signature) internal {
        Storage storage s = getStorage();
        AppStorage storage appStorage = LibAppStorage.appStorage();
        updateReward(tokenIds);
        KoboldStakingMultiplier memory stakingMultiplier = LibKoboldMultipliers.getKoboldMultiplier(koboldMultiplierId);
        LibKoboldMultipliers.spendMultiplier(msg.sender,koboldMultiplierId,1);
        require(isValidTimestamp(referenceTimestamp,s.acceptableTimelag),"Signature Expired");
        bytes32 hash = keccak256(abi.encodePacked(block.timestamp,tokenIds,"KHPS",healthPoints));
        address _signer = s.signer;
        require(_signer != address(0),"Signer Not Init"); 
        if(hash.toEthSignedMessageHash().recover(signature) != _signer) revert ("Invalid Signer");
        uint rewardIncreasePercent = stakingMultiplier.multiplier;
        uint totalReward;
        for(uint i; i<tokenIds.length;){
        uint tokenId = tokenIds[i];
        uint rewardFromToken = viewTokenTotalReward(tokenId);
        unchecked{
            //Can't Overflow Or Underflow
            totalReward = ((totalReward + rewardFromToken) * healthPoints[i]) / 100;
        }
        delete s.koboldStaker[tokenId].accumulatedRewards;
        unchecked{++i;}
        }
        totalReward = totalReward *  (100 + rewardIncreasePercent) / 100;
        iIngotToken(appStorage.ingotTokenAddress).mint(msg.sender,totalReward);
    }
    
}