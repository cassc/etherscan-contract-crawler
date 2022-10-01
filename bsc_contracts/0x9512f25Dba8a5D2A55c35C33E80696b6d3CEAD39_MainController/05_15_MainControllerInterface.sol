// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

abstract contract MainControllerInterface {
    /// @notice Indicator that this is a MainController contract (for inspection)
    bool public constant isMainController = true;
    uint public constant PERCENT_DIVIDER = 1000;
    uint public constant TECH_FEE_RATIO = 100;
    uint public constant COMMUNITY_FEE_RATIO = 100;

    struct VoteRecord{
	address matchAddress;
	uint8 flag; //0 - even, 1 - A win,2 - A lose
	uint8 teamA;
	uint8 teamB;
	uint8 scoreA;
	uint8 scoreB;
	uint256 voteTime;
	uint256 voteAmount;
        bool isCommonVote;
    }
    /*** get functions ***/
    function Admin() external virtual view returns (address);
    function getUplineFee() external virtual view returns (uint);
    function getUpline2Fee() external virtual view returns (uint);

    function getTeamName(uint8 teamNo) external virtual view returns (string memory);
    function getAllMatches() public virtual view returns (address[] memory);
    function getMatch(string memory date, uint8 teamA, uint8 teamB) external virtual view returns (address matchAddress);
    function getMatchByIndex(uint) external virtual view returns (address matchAddress);
    function allMatchesLength() external virtual view returns (uint);
    function getVoteRecords(address account) external virtual view returns (VoteRecord[] memory);

    /*** write functions ***/
    function createMatch(string memory date, uint8 teamA, uint8 teamB, uint startTime, uint endTime) virtual external returns (address matchAddress);

    function setTechFeeTo(address wallet) external virtual;
    function setCommunityFeeTo(address wallet) external virtual;
    function setAdmin(address operator) external virtual; 
    function setUsdtAddress(address _usdtAddress) virtual external;
    function commonVote(address matchAddress, uint8 team, uint8 flag, uint amount, address referer) external virtual returns (bool); //team: 0,1; flag:win,lose,even; amount: amount of USDT
    function scoreVote(address matchAddress, uint8 _teamAScore, uint8 _teamBScore, uint amount, address referer) external virtual returns (bool); //amount: amount of USDT, create the pool of this ratio if pool not exists

    /*** Events ***/
    event MatchCreated(string indexed date, uint8 indexed teamA, uint8 indexed teamB, uint startTime, uint endTime, address matchAddress);
    event CommonVoted(address indexed account, address indexed matchAddress, uint8 teamNo, uint8 flag, uint256 amount);
    event ScoreVoted(address indexed account, address indexed matchAddress, uint8 teamAScore, uint8 teamBScore, uint256 amount);
}