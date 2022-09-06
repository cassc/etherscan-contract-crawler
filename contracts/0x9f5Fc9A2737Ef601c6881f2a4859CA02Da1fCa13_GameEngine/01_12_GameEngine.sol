// SPDX-License-Identifier: UNLICENSED
/**
 * Author : Gordon
 */
pragma solidity ^0.8.0;

import "../base/IERC20.sol";
import "../base/INFTFactory.sol";
import "../base/Ownable.sol";
import "../base/IVRF.sol";
import "../base/ReentrancyGuard.sol";
import "../base/ISUPFactory.sol";
import "../base/IMetadata.sol";
import "./ProxyTarget.sol";
// import "hardhat/console.sol";

contract GameEngine is Ownable, ReentrancyGuard, ProxyTarget {

	bool public initialized;
    mapping (uint => uint) public firstStakeLockPeriod;
    mapping (uint => bool) public stakeConfirmation;
    mapping (uint => bool) public isStaked;
    mapping (uint => uint) public stakeTime;
    mapping (uint => uint) public lastClaim;
    mapping (uint8 => mapping(uint8 =>uint[])) public pool; //0 zombie 1 survivor (1-5) levels
    mapping (uint => uint) public levelOfToken;
    mapping (uint => uint) public tokenToArrayPosition;
    mapping (uint => uint) public tokenToRandomHourInStake;
    mapping (uint => bool) public wasUnstakedRecently;

    ISUP token;
    INFTFactory nftToken;
    IVRF public randomNumberGenerator;
    IMetadata metadataHandler;

    bool public frenzyStarted;

    uint internal _nonce;
    ////////////////// ---- data ends

    ////////////////// events ------
    event LevelUp(address indexed owner, uint tokenId, uint levelTo);
    event Steal(address indexed receiver, address indexed loser, uint tokenId);
    event Die(address indexed owner, uint tokenId);
    ////////////////// ------ events

    function initialize(address _randomEngineAddress, address _nftAddress, address _tokenAddress,address _metadata) external {
        require(msg.sender == _getAddress(ADMIN_SLOT), "not admin");
		require(!initialized);
		initialized = true;

        _owner = msg.sender;

        token = ISUP(_tokenAddress);
        nftToken = INFTFactory(_nftAddress);
        randomNumberGenerator = IVRF(_randomEngineAddress);
        metadataHandler = IMetadata(_metadata);
        // for(uint8 i=0;i<2;i++){
        //     for(uint8 j=1;j<6;j++){
        //         pool[i][j].push(0);
        //     }
        // }
    }

    function setRandomNumberGenerator(address _randomEngineAddress) external {
        require(msg.sender == _getAddress(ADMIN_SLOT), "not admin");
        randomNumberGenerator = IVRF(_randomEngineAddress);
    }

    // ERC721 receiver
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public pure returns (bytes4) {
        return 0x150b7a02;
    }

    function getPool(uint8 i, uint8 j) public view returns (uint[] memory) {
        return pool[i][j];
    }

    function alertStake(uint tokenId) external virtual {
        require (isStaked[tokenId] == false);
        require (nftToken.ownerOf(tokenId)==address(this));
        uint randomNo = 2 + randomNumberGenerator.getRandom("alertStake", _nonce++)%5;
        // uint randomNo = 2 + randomNumberGenerator.getRandom("alertStake", tokenId)%5;
        firstStakeLockPeriod[tokenId] = block.timestamp + randomNo*1 hours; //convert randomNo from hours to sec
        isStaked[tokenId] = true;
        stakeTime[tokenId] = block.timestamp;
        tokenToRandomHourInStake[tokenId]= randomNo*1 hours; //conversion required
        levelOfToken[tokenId] = 1;
        determineAndPush(tokenId);
    }

    function stake(uint[] memory tokenId) external virtual {
        for (uint i;i<tokenId.length;i++) {
        require (isStaked[tokenId[i]] == false);
        if ( stakeConfirmation[tokenId[i]] == true ){
            nftToken.safeTransferFrom(msg.sender, address(this), tokenId[i]);
            stakeTime[tokenId[i]] = block.timestamp;
            isStaked[tokenId[i]] = true;
            // nftToken.setTimeStamp(tokenId[i]);
            determineAndPush(tokenId[i]);
        } else   {
            require(firstStakeLockPeriod[tokenId[i]]==0,"AlreadyStaked");
            uint randomNo =  2 + randomNumberGenerator.getRandom("stake", _nonce++) % 5;
            // uint randomNo =  2 + randomNumberGenerator.getRandom("stake", tokenId[i]) % 5;
            firstStakeLockPeriod[tokenId[i]] = block.timestamp + randomNo*1 hours; //convert randomNo from hours to sec
            nftToken.safeTransferFrom(msg.sender, address (this), tokenId[i]);
            stakeTime[tokenId[i]] = block.timestamp;
            isStaked[tokenId[i]] = true;
            tokenToRandomHourInStake[tokenId[i]]= randomNo * 1 hours; //conversion required
            levelOfToken[tokenId[i]] = 1;
            determineAndPush(tokenId[i]);
          }
        }
    }

    function moveToLast(uint _tokenId) internal {
        (uint8 tokenType,) = metadataHandler.getToken(_tokenId);
        uint8 level = uint8(levelOfToken[_tokenId]);
        uint position = tokenToArrayPosition[_tokenId];
        uint[] storage currentPool = pool[tokenType][level];
        uint length = currentPool.length;
        uint lastToken = currentPool[length-1];
        currentPool[position] = lastToken;
        tokenToArrayPosition[lastToken] = position;
        currentPool[length-1] = _tokenId;
        currentPool.pop();
    }

    function determineAndPush(uint tokenId) internal {
        uint8 tokenLevel = uint8(levelOfToken[tokenId]);
        (uint8 tokenType,) = metadataHandler.getToken(tokenId);
        pool[tokenType][tokenLevel].push(tokenId);
        tokenToArrayPosition[tokenId] = pool[tokenType][tokenLevel].length-1;
    }

    function unstakeBurnCalculator(uint8 tokenLevel) internal returns(uint){
        if(isFrenzy()){
            return 50-5*tokenLevel;
        }
        else if(isAggression()){
            uint val = whichAggression();
            return (25+5*val)-(5*tokenLevel);
        }
        else{
            return 25-5*tokenLevel;
        }
    }

    function isFrenzy() public returns (bool){
        uint totalPoolStrength;
        for(uint8 i=0;i<2;i++){
            for(uint8 j=1;j<6;j++){
                totalPoolStrength += pool[i][j].length;
            }
        }
        if(totalPoolStrength<1000 && frenzyStarted == true){
            frenzyStarted = false;
            return false;
        }
        else if(totalPoolStrength >= 2000){
            frenzyStarted = true;
            return true;
        }
        else{
            return false;
        }
    }

    function isAggression() view public returns(bool){
        uint totalPoolStrength;
        for(uint8 i=0;i<2;i++){
            for(uint8 j=1;j<6;j++){
                totalPoolStrength += pool[i][j].length;
            }
        }
        if(totalPoolStrength >= 1200) return true;
        else return false;
    }

    function whichAggression() view internal returns(uint){
        uint totalPoolStrength;
        for(uint8 i=0;i<2;i++){
            for(uint8 j=1;j<6;j++){
                totalPoolStrength += pool[i][j].length;
            }
        }
        if(totalPoolStrength>=1200 && totalPoolStrength<1400) return 1;
        else if(totalPoolStrength<1600) return 2;
        else if(totalPoolStrength<1800) return 3;
        else if(totalPoolStrength<2000) return 4;
        else return 0;
    }

    function steal(uint8 tokenType, uint nonce) internal returns (uint) {
        uint randomNumber = randomNumberGenerator.getRandom("steal random", _nonce++);
        randomNumber = uint(keccak256(abi.encodePacked(randomNumber,nonce)));
        uint8 level = whichLevelToChoose(tokenType, randomNumber);

        if(level == 0) return 0; // should not steal because of no token to steal

        uint tokenToGet = randomNumber % pool[tokenType][level].length;
        return pool[tokenType][level][tokenToGet];
    }

    function whichLevelToChoose(uint8 tokenType, uint randomNumber) internal view returns(uint8) {
        uint16[5] memory x = [1000,875,750,625,500];
        uint denom;
        for(uint8 level=1;level<6;level++){
            denom += pool[tokenType][level].length*x[level-1];
        }
        if(denom == 0) return 0; // should not steal because of no token to steal

        uint[5] memory stealing;
        for(uint8 level=1;level<6;level++){
            stealing[level-1] = (pool[tokenType][level].length*x[level-1]*1000000)/denom;
        }
        uint8 levelToReturn;
        randomNumber = randomNumber %1000000;
        if (randomNumber < stealing[0]) {
            levelToReturn = 1;
        } else if (randomNumber < stealing[0]+stealing[1]) {
            levelToReturn = 2;
        } else if (randomNumber < stealing[0]+stealing[1]+stealing[2]) {
            levelToReturn = 3;
        } else if (randomNumber < stealing[0]+stealing[1]+stealing[2]+stealing[3]) {
            levelToReturn = 4;
        } else if (randomNumber < stealing[0]+stealing[1]+stealing[2]+stealing[3]+stealing[4]) {
            levelToReturn = 5;
        }
        return levelToReturn;
    }

    function howManyTokensCanSteal(uint8 tokenType) view internal returns (uint) {
        uint[2] memory totalStaked;

        for(uint8 i =0;i<2;i++){
            totalStaked[i] = totalStakedOfType(i);
        }
        for(uint i = 0;i<5;i++) {
            if((totalStaked[tokenType]*100)/(totalStaked[0]+totalStaked[1])<=10+10*i){
                if(totalStaked[1-tokenType] >= 5-i){
                    return 5-i;
                }
                return totalStaked[1-tokenType];
            }
        }
        if(totalStaked[1-tokenType] > 0) {
            return 1;
        }
        return 0;
    }

    function calculateSUP (uint tokenId) internal returns (uint) {
        uint calculatedDuration;
        uint stakedTime = stakeTime[tokenId];
        uint lastClaimTime = lastClaim[tokenId];
        if (lastClaimTime == 0) {
            calculatedDuration = (block.timestamp - (stakedTime+tokenToRandomHourInStake[tokenId]))/1 hours;
            if (calculatedDuration >= tokenToRandomHourInStake[tokenId]/1 hours) {
                return 250 ether;
            } else {
                return 0;
            }
        } else {
            if (wasUnstakedRecently[tokenId] == true) {
                calculatedDuration = (block.timestamp - stakedTime)/1 hours;
                wasUnstakedRecently[tokenId] = false;
            } else {
                calculatedDuration = (block.timestamp - lastClaimTime)/1 hours;
            }
            if (calculatedDuration >= 12) {
                calculatedDuration = calculatedDuration / 12;
                uint toReturn = calculateFinalAmountInDays (calculatedDuration);
                return toReturn;
            } else {
                return 0;
            }
        }
    }

    function calculateFinalAmountInDays (uint _calculatedHour)internal pure returns (uint) {
        return _calculatedHour * 250 ether;
    }

    function executeClaims (uint randomNumber, uint tokenId, uint firstHold, uint secondHold) internal virtual returns (bool) {
        if (randomNumber >=0 && randomNumber < firstHold) {
            bool query = onSuccess(tokenId);
            return query;
        }
        else if (randomNumber >= firstHold && randomNumber < secondHold) {
            bool query = onCriticalSuccess(tokenId);
            return query;
        }
        else {
            bool query = onCriticalFail(tokenId);
            return query;
        }
    }

    function onSuccess(uint tokenId) internal virtual returns (bool) {
        (uint8 nftType,) = metadataHandler.getToken(tokenId);
        require (lastClaim[tokenId] + 12 hours <= block.timestamp, "Claiming before 12 hours");
        uint calculatedValue = calculateSUP(tokenId);
        token.mintFromEngine(msg.sender, calculatedValue);
        lastClaim[tokenId] = block.timestamp;
        uint randomNumber = randomNumberGenerator.getRandom("onSuccess", _nonce++);
        // uint randomNumber = randomNumberGenerator.getRandom("onSuccess", tokenId);
        randomNumber = uint(keccak256(abi.encodePacked(randomNumber,"1")))%100;
        if(randomNumber<32 && levelOfToken[tokenId] < 5){
            moveToLast(tokenId);
            levelOfToken[tokenId]++;
            determineAndPush(tokenId);
            nftToken.restrictedChangeNft(tokenId, nftType, uint8(levelOfToken[tokenId]));
            emit LevelUp(msg.sender, tokenId, levelOfToken[tokenId]);
        }
        return false;
    }

    function onCriticalSuccess(uint tokenId) internal virtual returns (bool) {
        (uint8 nftType,) = metadataHandler.getToken(tokenId);
        require (lastClaim[tokenId] + 12 hours <= block.timestamp, "Claiming before 12 hours");
        token.mintFromEngine(msg.sender, calculateSUP(tokenId));
        lastClaim[tokenId] = block.timestamp;
        if (uint(keccak256(abi.encodePacked(randomNumberGenerator.getRandom("onCriticalSuccess", _nonce++),"1")))%100 < 40 
        // if (uint(keccak256(abi.encodePacked(randomNumberGenerator.getRandom("onCriticalSuccess", tokenId),"1")))%100 < 40 
        && levelOfToken[tokenId]<5) {
            moveToLast (tokenId);
            levelOfToken[tokenId]++;
            determineAndPush(tokenId);
            nftToken.restrictedChangeNft(tokenId, nftType, uint8(levelOfToken[tokenId]));
            emit LevelUp(msg.sender, tokenId, levelOfToken[tokenId]);
        }
        uint value = howManyTokensCanSteal(nftType);

        uint stolenTokenId;

        for (uint i=0;i < value;i++) {
            stolenTokenId = steal(1-nftType,i+1);
            if(stolenTokenId != 0) {
                moveToLast(stolenTokenId);
                nftToken.restrictedChangeNft(stolenTokenId, nftType, uint8(levelOfToken[stolenTokenId]));//s->1

                // pool[nftType][uint8(levelOfToken[stolenTokenId])].push(stolenTokenId);
                // tokenToArrayPosition[stolenTokenId] = pool[nftType][uint8(levelOfToken[stolenTokenId])].length-1;
                determineAndPush(stolenTokenId);

                emit Steal(msg.sender, nftToken.tokenOwnerCall(stolenTokenId), stolenTokenId);
                nftToken.tokenOwnerSetter(stolenTokenId, msg.sender);
            }
        }
        return false;
    }

    function onCriticalFail(uint tokenId) internal returns (bool) {
            emit Die(nftToken.tokenOwnerCall(tokenId), tokenId);
            nftToken.burnNFT(tokenId);
            isStaked[tokenId] = false;
            moveToLast(tokenId);
            return true;
     }


//VITAL INTERNAL FUNCITONS
    function claimStake(uint tokenId) internal returns (bool){
        uint randomNumber = randomNumberGenerator.getRandom("claimStake", _nonce++)%100;
        // uint randomNumber = randomNumberGenerator.getRandom("claimStake", tokenId)%100;
        (,uint8 level) =
        metadataHandler.getToken(tokenId);

        if (stakeConfirmation[tokenId] == false) {
            require (block.timestamp >= firstStakeLockPeriod[tokenId],"lock not over");
            stakeConfirmation[tokenId] = true;
            if(isFrenzy()) {
                bool query =  executeClaims(randomNumber, tokenId, 55, 63+2*(level));
                return query;
            }
            else if(isAggression()){
                uint aggKicker = whichAggression();
                bool query = executeClaims(randomNumber, tokenId, 80-3*aggKicker, 85+2*(level));
                return query;
            }
            else {
                bool query =  executeClaims(randomNumber, tokenId, 80, 88+2*(level));
                return query;
            }
        }
        else {
            if(isFrenzy()){
                bool query = executeClaims(randomNumber, tokenId, 55, 63+2*(level));
                return query;
            }
            else if(isAggression()){
                uint aggKicker = whichAggression();
                bool query = executeClaims(randomNumber, tokenId, 80-3*aggKicker, 85+2*(level));
                return query;
            }
            else{
                bool query = executeClaims(randomNumber, tokenId, 80, 88+2*(level));
                return query;
            }
        }
    }

    function unstakeNFT (uint tokenId) internal {
        uint randomNumber = randomNumberGenerator.getRandom("unstakeNFT", _nonce++);
        // uint randomNumber = randomNumberGenerator.getRandom("unstakeNFT", tokenId);
        if (stakeConfirmation[tokenId] == true) {
            uint level = levelOfToken[tokenId];
            uint burnPercent = unstakeBurnCalculator(uint8(level));
            if(randomNumber%100 <= burnPercent){
                emit Die(nftToken.tokenOwnerCall(tokenId), tokenId);
                nftToken.burnNFT(tokenId);
            }
            else {
                nftToken.safeTransferFrom(address(this), msg.sender, tokenId);
                wasUnstakedRecently[tokenId] = true;
            }
            moveToLast(tokenId);
        }
        else {
            uint burnPercent = unstakeBurnCalculator(1);
            if(randomNumber%100 <= burnPercent){
                emit Die(nftToken.tokenOwnerCall(tokenId), tokenId);
                nftToken.burnNFT(tokenId);
            }
            else{
                nftToken.safeTransferFrom(address(this), msg.sender, tokenId);
                wasUnstakedRecently[tokenId] = true;
            }
            moveToLast(tokenId);
        }
    }

    function claimAndUnstake (bool claim,uint[] memory tokenAmount) external nonReentrant{

        for (uint i=0;i<tokenAmount.length;i++) {
            require(nftToken.tokenOwnerCall(tokenAmount[i]) == msg.sender, "Caller not the owner");
            require(nftToken.ownerOf(tokenAmount[i]) == address(this),"Contract not the owner");
            require(isStaked[tokenAmount[i]] = true, "Not Staked");
            require (stakeTime[tokenAmount[i]]+ tokenToRandomHourInStake[tokenAmount[i]]<= block.timestamp,"Be Patient");
            if (claim == true) {
                claimStake(tokenAmount[i]);
            }
            else {
                bool isBurnt = claimStake(tokenAmount[i]);
                if (isBurnt == false)
                {
                    unstakeNFT(tokenAmount[i]);
                    isStaked[tokenAmount[i]] = false;
                }
            }
            // nftToken.setTimeStamp(tokenAmount[i]);
        }
    }

    function totalStakedOfType(uint8 tokenType) public view returns(uint){       
        uint totalStaked; 
        for(uint8 j=1;j<6;j++){
                totalStaked += pool[tokenType][j].length;
        }
        return totalStaked;
    }

    /**
     * Utility method to get token info
     *
     * returns (tokenType, level, isStaked, stakeTime, lastClaimTime, tokenToRandomHourInStake)
     */
    function getTokenMeta(uint256 tokenId) public view returns(uint8, uint8, bool, uint, uint, uint) {
        (uint8 tokenType_, uint8 level_) = metadataHandler.getToken(tokenId);
        return (
            tokenType_,
            level_,
            isStaked[tokenId],
            stakeTime[tokenId],
            lastClaim[tokenId],
            tokenToRandomHourInStake[tokenId]
        );
    }
}