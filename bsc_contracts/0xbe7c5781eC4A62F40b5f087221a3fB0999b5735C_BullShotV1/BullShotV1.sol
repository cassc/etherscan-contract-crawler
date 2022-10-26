/**
 *Submitted for verification at BscScan.com on 2022-10-25
*/

pragma solidity ^0.8.17;


/*

BULLSHOTV1                                                                  
                                                                      
-> https://bullshot.io <-

- Predict On Assets, Make Money.
- Fully Decentralized, No Oracle!

*/



interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}


// REENTRANCY GUARD
abstract contract ReentrancyGuard 
{
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}



//CONTRACT
contract BullShotV1 is ReentrancyGuard {

    address operator = 0x7650F39bA8D036b1f7C7b974a6b02aAd4B7F71F7;

    receive() external payable {}

    bool emergencyShutdown=false;

    function shutdown() public {
        require(msg.sender==operator);
        emergencyShutdown=true;
    }

    function reverseShutdown() public {        
        require(msg.sender==operator);
        emergencyShutdown=false;
    }

    function allowTime(uint256 timePeriod) public {
        require(!emergencyShutdown,"Contract is frozen");
        require(msg.sender==operator);
        timeAllowed[timePeriod]=true;
    }

    function disallowTime(uint256 timePeriod) public {
        require(!emergencyShutdown,"Contract is frozen");
        require(msg.sender==operator);
        timeAllowed[timePeriod]=false;
    }

    function addAsset(address oracle,uint256 assetId) public{
        require(!emergencyShutdown,"Contract is frozen");
        require(msg.sender==operator);
        oracleForAsset[assetId]=oracle;
        allowedAssets[assetId]=true;
    }

    function removeAsset(uint256 assetId) public {
        require(!emergencyShutdown,"Contract is frozen");
        require(msg.sender==operator);
        allowedAssets[assetId]=false;
        delete oracleForAsset[assetId];
    }

    function withdrawTreasury(uint256 amount) public {
        require(msg.sender==operator);
        payable(msg.sender).transfer(amount);
    }

    function modifyMinBet(uint256 minBet) public {
        require(!emergencyShutdown,"Contract is frozen");
        require(msg.sender==operator);
        minBetAmount=minBet;
    }

    function modifyPayout(uint256 newPayout) public {
        require(!emergencyShutdown,"Contract is frozen");
        require(msg.sender==operator);
        payout=newPayout;
    }

    uint256 payout=195;

    mapping (uint256 => bool) allowedAssets;
    mapping (uint256 => address) oracleForAsset;
    mapping (uint256 => bool) timeAllowed;

    uint256 minBetAmount=0.01 ether;

    mapping(address=>uint256) myCurrentGame;

    mapping(address=>uint256[]) myGames;

    uint256 gameCounter=1;

    mapping(uint256=>game) games;

    struct game {
        address user;
        uint256 assetId;
        uint256 gameCreatedAt;
        bool bull;
        bool claimed;
        uint256 amount;
        uint256 gameExpiresAt;
        int256 lockPrice;
    }

    
    function claim() public nonReentrant {
        require(!emergencyShutdown,"Contract is frozen");
        require(myCurrentGame[msg.sender]!=0,"No bets made");
        

        require(!games[myCurrentGame[msg.sender]].claimed,"Already claimed");
        AggregatorInterface assetOracle=AggregatorInterface(oracleForAsset[games[myCurrentGame[msg.sender]].assetId]);

        require(games[myCurrentGame[msg.sender]].gameExpiresAt<=assetOracle.latestRound(),"Current bet not expired");

        int256 oraclesAnswer=assetOracle.getAnswer(games[myCurrentGame[msg.sender]].gameExpiresAt);

        if(games[myCurrentGame[msg.sender]].lockPrice<oraclesAnswer){
            if(games[myCurrentGame[msg.sender]].bull){
                payable(games[myCurrentGame[msg.sender]].user).transfer((games[myCurrentGame[msg.sender]].amount/100)*payout);
            }
        }

        if(games[myCurrentGame[msg.sender]].lockPrice>oraclesAnswer){
            if(!games[myCurrentGame[msg.sender]].bull){
                payable(games[myCurrentGame[msg.sender]].user).transfer((games[myCurrentGame[msg.sender]].amount/100)*payout);
            }
        }

        games[myCurrentGame[msg.sender]].claimed=true;

    
    }

    function averageRoundLength(uint256 roundPeriod,uint256 assetId,uint256 baseAverageOn) public view returns(uint256){
        require(!emergencyShutdown,"Contract is frozen");
        require(timeAllowed[roundPeriod],"Time period not allowed");
        require(allowedAssets[assetId],"Asset not allowed");
        AggregatorInterface assetOracle=AggregatorInterface(oracleForAsset[assetId]);

        uint256 sumOfDifference=0;
        uint256 latestRoundId=assetOracle.latestRound();
        for(uint256 i=0;i<baseAverageOn;i++){
            uint256 difference=assetOracle.getTimestamp(latestRoundId-(i))-assetOracle.getTimestamp(latestRoundId-(i+1));
            sumOfDifference+=difference;
        }

        uint256 averageTime=sumOfDifference/baseAverageOn;
        return averageTime;
    }

    function hasWon(uint256 gameId) public view returns(bool){
        require(!emergencyShutdown,"Contract is frozen");
        require(games[gameId].amount>=0,"Invalid game");
        require(!games[gameId].claimed,"Already claimed");
        AggregatorInterface assetOracle=AggregatorInterface(oracleForAsset[games[gameId].assetId]);

        require(games[gameId].gameExpiresAt<=assetOracle.latestRound(),"Current bet not expired");

        int256 oraclesAnswer=assetOracle.getAnswer(games[gameId].gameExpiresAt);

        if(games[gameId].lockPrice<oraclesAnswer){
            if(games[gameId].bull){
                return true;
            } else {
                return false;
            }
        }

        if(games[gameId].lockPrice>oraclesAnswer){
            if(!games[gameId].bull){
                return true;
            } else {
                return false;
            }
        }

    }
    function latestRoundFromOracle(uint256 assetId) public view returns(uint256){
        require(!emergencyShutdown,"Contract is frozen");
        require(allowedAssets[assetId],"Asset not allowed");
        AggregatorInterface assetOracle=AggregatorInterface(oracleForAsset[assetId]);
        return assetOracle.latestRound();
    }

    function readAnswerFromOracle(uint256 assetId,uint256 roundId) public view returns(int256){
        require(!emergencyShutdown,"Contract is frozen");
        require(allowedAssets[assetId],"Asset not allowed");
        AggregatorInterface assetOracle=AggregatorInterface(oracleForAsset[assetId]);
        return assetOracle.getAnswer(roundId);
    }


    function latestAnswerFromOracle(uint256 assetId) public view returns(int256){
        require(!emergencyShutdown,"Contract is frozen");
        require(allowedAssets[assetId],"Asset not allowed");
        AggregatorInterface assetOracle=AggregatorInterface(oracleForAsset[assetId]);
        return assetOracle.latestAnswer();
    }

    function getAllUserGames(address user) public view returns(uint256[] memory){
        require(!emergencyShutdown,"Contract is frozen");
        return myGames[user];
    }

    function readGame(uint256 gameId) public view returns(game memory){
        require(!emergencyShutdown,"Contract is frozen");
        return games[gameId];
    }

    function readData(address user) public view returns (game memory){
        require(!emergencyShutdown,"Contract is frozen");
        return games[myCurrentGame[user]];
    }



    function goBear(uint256 roundPeriod,uint256 assetId) public payable nonReentrant{
        require(!emergencyShutdown,"Contract is frozen");
        require(timeAllowed[roundPeriod],"Time period not allowed");
        require(msg.value>=minBetAmount,"Bet too small");
        require(allowedAssets[assetId],"Asset not allowed");

        AggregatorInterface assetOracle=AggregatorInterface(oracleForAsset[assetId]);

        require(games[myCurrentGame[msg.sender]].gameExpiresAt<=assetOracle.latestRound(),"Current bet not expired");

        game memory newGame;

        newGame.user=msg.sender;
        newGame.assetId=assetId;
        newGame.gameCreatedAt=assetOracle.latestRound();
        newGame.bull=false;
        newGame.amount=msg.value;
        newGame.gameExpiresAt=assetOracle.latestRound()+roundPeriod;
        newGame.lockPrice=assetOracle.latestAnswer();

        myGames[msg.sender].push(gameCounter);
        games[gameCounter]=newGame;
        myCurrentGame[msg.sender]=gameCounter;
        gameCounter++;

    }

    function goBull(uint256 roundPeriod,uint256 assetId) public payable nonReentrant {
        require(!emergencyShutdown,"Contract is frozen");
        require(timeAllowed[roundPeriod],"Time period not allowed");
        require(msg.value>=minBetAmount,"Bet too small");
        require(allowedAssets[assetId],"Asset not allowed");

        AggregatorInterface assetOracle=AggregatorInterface(oracleForAsset[assetId]);

        require(games[myCurrentGame[msg.sender]].gameExpiresAt<=assetOracle.latestRound(),"Current bet not expired");

        game memory newGame;

        newGame.user=msg.sender;
        newGame.assetId=assetId;
        newGame.gameCreatedAt=assetOracle.latestRound();
        newGame.bull=true;
        newGame.amount=msg.value;
        newGame.gameExpiresAt=assetOracle.latestRound()+roundPeriod;
        newGame.lockPrice=assetOracle.latestAnswer();

        myGames[msg.sender].push(gameCounter);
        myCurrentGame[msg.sender]=gameCounter;

        games[gameCounter]=newGame;
        gameCounter++;

    }

}