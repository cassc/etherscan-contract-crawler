// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

abstract contract MatchInterface {
    /// @notice Indicator that this is a MainController contract (for inspection)
    bool public constant isMatchController = true;

    /*** get functions ***/
    function teamA() external virtual view returns (uint8);
    function teamB() external virtual view returns (uint8);
    function teamNames() external virtual view returns (string memory teamAName, string memory teamBName);
    function score(uint8 teamNo) external virtual view returns (uint8);
    function minVoteAmount() external virtual view returns (uint);
    function commonVotePool() external virtual view returns (uint winAmount, uint loseAmount, uint evenAmount, uint winUserAmount, uint loseUserAmount, uint evenUserAmount);
    function scoreVotePool(uint8 scoreA, uint8 scoreB) external virtual view returns (uint amount);
    function getAvailableReward(address account) public virtual view returns (uint);

    /*** write functions ***/
    function initialize(uint8 _teamA, uint8 _teamB, uint _startTime, uint _endTime, address _usdtAddress) virtual external; 
    function commonVote(address account, uint8 teamA, uint8 flag, uint amount) external virtual returns (bool); //flag:1 A win, 2 A lose, 0 even; amount: amount of USDT
    function scoreVote(address account, uint8 _teamAScore, uint8 _teamBScore, uint amount) external virtual returns (bool); //amount: amount of USDT, create the pool of this ratio if pool not exists
    function claimReward() external virtual returns (uint); 
    function createScorePool(uint8 _teamAScore, uint8 _teamBScore) external virtual returns (bool); //create sustomized pool, fail if pool exists
    function _setMatchScore(uint8 _teamA, uint8 _teamAScore, uint8 _teamB, uint8 _teamBScore) external virtual returns (bool); //only adminController can set 
    function _setMatchTimeStamp(uint startTimeStamp, uint endTimeStamp) external virtual returns (bool); //only adminController can set 

    /*** Events ***/
    // winner is one of teamA or teamB, 0 refers to even
    event MatchScoreSet(uint8 indexed teamA, uint8 indexed teamB, address indexed matchAddress, uint8 winner, uint8 scoreA, uint8 scoreB); 
    // Win, lose or even bet occurs
    event CommonVoted(address indexed player, address indexed matchAddress, uint8 winner);
    // customized bet occurs
    event ScoreVoted(address indexed player, address indexed matchAddress, uint8 scoreA, uint8 scoreB);
}