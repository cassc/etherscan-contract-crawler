// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MainControllerInterface.sol";
import "./MatchInterface.sol";

/**
 * @title Main Controller Contract
 * @dev Main controller is in charge of global configuration and storage.
 */
contract MatchContract is MatchInterface{ 

    address public mainController; //main controller's proxy address

    address public usdt; // vote token

    uint8 public override teamA;
    uint8 public override teamB;
    
    uint256 public startTime; //UNIX timestamp, in seconds
    uint256 public endTime;   //UNIX timestamp, in seconds

    uint256 public totalCommonRewardPoolAmount; // win, lose, even pool will be shared in total
    uint256 public totalScoreRewardPoolAmount;  // custom ratio pool will be shared in total

    // result score, defualt is 0
    uint8 public teamAScore;
    uint8 public teamBScore;
    uint8 public commonIndex; // 0-even, 1- teamA win, 2-teamA lose

    //min vote amount, defualt is 0
    uint public minVoteLimit;

    // result is set or not, default is false
    bool public resultSetted;

    // even-0, win-1, lose-2 => pool amount
    uint[3] public commonRewardPoolAmount;
    // even-0, win-1, lose-2 => user amount
    uint[3] public commonPoolUserAmount;
    // teamA:teamB ratio => pool amount
    mapping(uint8 => mapping(uint8 => uint)) public scoreRewardPoolAmount;
    // teamA:teamB ratio => user amount
    mapping(uint8 => mapping(uint8 => uint)) public scorePoolUserAmount;

    struct User{
    	uint[3] commonVoteAmount;
	mapping(uint8 => mapping(uint8 => uint)) scoreVoteAmount;
	uint amountPayout;
    }
    mapping (address => User) public users;

    struct MatchScore {
	uint8 scoreA;
	uint8 scoreB;
    }
    MatchScore[] public scorePools;

    struct MatchInfo{
	uint8 scoreA;
	uint8 scoreB;
	uint poolAmount;
	uint userAmount;
    }

    constructor() {
        mainController = msg.sender;
    }

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    /*** get functions ***/
    function teamNames() external override view returns (string memory teamAName, string memory teamBName)
    {
    	MainControllerInterface mainCtrl = MainControllerInterface(mainController);
	teamAName = mainCtrl.getTeamName(teamA);
	teamBName = mainCtrl.getTeamName(teamB);
    }

    // query the result score of a team
    function score(uint8 teamNo) external override view returns (uint8)
    {
    	if(teamNo == teamA)
		return teamAScore;
	if(teamNo == teamB)
		return teamBScore;
	return 0;
    }

    // bet minimum amount  
    function minVoteAmount() external override view returns (uint)
    {
    	return minVoteLimit;
    }

    // amount of win&lose&even reward pool
    function commonVotePool() external override view returns (uint winAmount, uint loseAmount, uint evenAmount, uint winUserAmount, uint loseUserAmount, uint evenUserAmount)
    {
    	winAmount = commonRewardPoolAmount[1];
	loseAmount = commonRewardPoolAmount[2];
	evenAmount = commonRewardPoolAmount[0];
    	winUserAmount = commonPoolUserAmount[1];
	loseUserAmount = commonPoolUserAmount[2];
	evenUserAmount = commonPoolUserAmount[0];
    }

    // amount of custm ratio pool
    function scoreVotePool(uint8 scoreA, uint8 scoreB) external override view returns (uint amount)
    {
    	return scoreRewardPoolAmount[scoreA][scoreB];
    }

    // get reward of a user can claim after the match
    function getAvailableReward(address account) public override view returns (uint)
    {
    	require(block.timestamp > endTime, "match is not end");
    	require(resultSetted == true, "match result is not revealed");
	// query beting records of msg.sender, and return the reward available 
	User storage user = users[account];
	uint commonRwardAmount = 0;
	if(commonRewardPoolAmount[commonIndex] > 0)
		commonRwardAmount = totalCommonRewardPoolAmount * user.commonVoteAmount[commonIndex] / commonRewardPoolAmount[commonIndex];
	uint scoreRewardAmount = 0;
	if(scoreRewardPoolAmount[teamAScore][teamBScore] > 0)
		scoreRewardAmount = totalScoreRewardPoolAmount * user.scoreVoteAmount[teamAScore][teamBScore] / scoreRewardPoolAmount[teamAScore][teamBScore];
	return commonRwardAmount + scoreRewardAmount - user.amountPayout;
    }
    // get score pools info
    function getMatchScorePoolsInfo() external view returns (MatchInfo[] memory)
    {
    	uint len = scorePools.length; 
	MatchInfo[] memory matchScorePool = new MatchInfo[](len);
	for(uint i = 0; i < len; i++)
	{
		matchScorePool[i].scoreA = scorePools[i].scoreA;
		matchScorePool[i].scoreB = scorePools[i].scoreB;
		matchScorePool[i].poolAmount = scoreRewardPoolAmount[scorePools[i].scoreA][scorePools[i].scoreB];
		matchScorePool[i].userAmount= scorePoolUserAmount[scorePools[i].scoreA][scorePools[i].scoreB];
	}
	return matchScorePool;
    }


    /*** write functions ***/
    function initialize(uint8 _teamA, uint8 _teamB, uint _startTime, uint _endTime, address _usdtAddress) override external {
    	require(msg.sender == mainController, "no privilege to create new match");
	teamA = _teamA;
	teamB = _teamB;
	startTime = _startTime;
	endTime = _endTime;
	usdt = _usdtAddress;
    }

    //teamNo: always pass in teamA;  flag:1- A win,2- A lose,0-even; amount: amount of USDT
    function commonVote(address account, uint8 teamNo, uint8 flag, uint amount) override external lock  returns (bool) 
    {
    	require(msg.sender == mainController, "only maincontroller has privilege to call this method");
	require(teamNo == teamA,  "invalid teamNo");
	User storage user = users[account];
	commonRewardPoolAmount[flag] += amount;
	user.commonVoteAmount[flag] += amount;
	commonPoolUserAmount[flag] += 1;

	uint uplineFee = MainControllerInterface(mainController).getUplineFee();
	uint upline2Fee = MainControllerInterface(mainController).getUpline2Fee();
	uint PERCENT_DIVIDER = MainControllerInterface(mainController).PERCENT_DIVIDER();
	uint COMMUNITY_FEE_RATIO = MainControllerInterface(mainController).COMMUNITY_FEE_RATIO();
	uint TECH_FEE_RATIO = MainControllerInterface(mainController).TECH_FEE_RATIO();
	totalCommonRewardPoolAmount += amount * (PERCENT_DIVIDER - COMMUNITY_FEE_RATIO - TECH_FEE_RATIO - uplineFee - upline2Fee) / PERCENT_DIVIDER;

    	return true;
    }

    // teamA < teamB
    function scoreVote(address account, uint8 _teamAScore, uint8 _teamBScore, uint amount) external override returns (bool) //amount: amount of USDT, create the pool of this ratio if pool not exists
    {
    	require(msg.sender == mainController, "only maincontroller has privilege to call this method");
	User storage user = users[account];
	user.scoreVoteAmount[_teamAScore][_teamBScore] += amount;
	scoreRewardPoolAmount[_teamAScore][_teamBScore] += amount;
	scorePoolUserAmount[_teamAScore][_teamBScore] += 1;

	uint uplineFee = MainControllerInterface(mainController).getUplineFee();
	uint upline2Fee = MainControllerInterface(mainController).getUpline2Fee();
	uint PERCENT_DIVIDER = MainControllerInterface(mainController).PERCENT_DIVIDER();
	uint COMMUNITY_FEE_RATIO = MainControllerInterface(mainController).COMMUNITY_FEE_RATIO();
	uint TECH_FEE_RATIO = MainControllerInterface(mainController).TECH_FEE_RATIO();
	totalScoreRewardPoolAmount += amount * (PERCENT_DIVIDER - COMMUNITY_FEE_RATIO - TECH_FEE_RATIO - uplineFee - upline2Fee) / PERCENT_DIVIDER;

    	return true;
    }

    function claimReward() override external lock returns (uint)
    {
    	require(block.timestamp > endTime, "match is not end");
    	require(resultSetted == true, "match result is not revealed");

	User storage user = users[msg.sender];
	uint amount = getAvailableReward(msg.sender);
	if(amount > 0)
	{
		user.amountPayout += amount;
		IERC20(usdt).transfer(msg.sender, amount);
	}
    	return amount;
    }

    // create ratio list for querying
    function createScorePool(uint8 _teamAScore, uint8 _teamBScore) override external lock returns (bool) 
    {
    	//create a new ratio pool to accept voting if not exists	
	for(uint i=0; i<scorePools.length; i++)
	{
		MatchScore memory m = scorePools[i];
		if(m.scoreA == _teamAScore && m.scoreB == _teamBScore)
			return false;
	}
	scorePools.push(MatchScore(_teamAScore, _teamBScore));
    	return true;
    }
    
    // admin set the result
    function _setMatchScore(uint8 _teamA, uint8 _teamAScore, uint8 _teamB, uint8 _teamBScore) override  external returns (bool) 
    {
    	require(msg.sender == MainControllerInterface(mainController).Admin(), "only maincontroller has privilege to set the match result");
	require((_teamA == teamA && _teamB == teamB) || (_teamA == teamB && _teamB == teamA), "wrong team number");

	uint8 winner = 0;
	if(_teamA == teamA)
	{
		teamAScore = _teamAScore;
		teamBScore = _teamBScore;
	}else if(_teamA == teamB)
	{
		teamAScore = _teamBScore;
		teamBScore = _teamAScore;
	}
	if(teamAScore == teamBScore)
		commonIndex = 0;
	else if(teamAScore > teamBScore)
	{
		commonIndex = 1;
		winner = teamA;
	}
	else if(teamAScore < teamBScore)
	{
		commonIndex = 2;
		winner = teamB;
	}
	resultSetted = true;
    	emit MatchScoreSet(teamA, teamB, address(this), winner, teamAScore, teamBScore); 
    	return true;
    }

    // admin update startTme and endTime
    function _setMatchTimeStamp(uint startTimeStamp, uint endTimeStamp) external override returns (bool) 
    {
    	require(msg.sender == MainControllerInterface(mainController).Admin(), "only maincontroller has privilege to set the match result");
	startTime = startTimeStamp;
	endTime = endTimeStamp;
	return true;
    }
}