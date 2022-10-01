// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./MainControllerInterface.sol";
import "./MainControllerStorageV1.sol";
import "./MatchInterface.sol";
import "./MatchContract.sol";

/**
 * @title Main Controller Contract
 * @dev Main controller is in charge of global configuration and storage.
 */
contract MainController is MainControllerStorageV1, MainControllerInterface, Initializable, UUPSUpgradeable, OwnableUpgradeable {

    /// @notice initialize only run once
    function initialize (address _usdtAddress) public initializer {
      __Ownable_init();
      __UUPSUpgradeable_init();
      usdt = _usdtAddress;
      first_ref_fee = 40;
      second_ref_fee = 10;
      admin = owner();
      techFee = owner();
      communityFee = owner();
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * get functions
     */
    /**
     * @notice Return all of the matches 
     * @dev The automatic getter may be used to access an individual match.
     * @return The list of match addresses
     */
    function getAllMatches() public override view returns (address[] memory) {
        return matchesList;
    }

    // return the number of all matches
    function allMatchesLength() external override view returns (uint)
    {
    	return matchesList.length;
    }

    // retrun specific math by an index
    function getMatchByIndex(uint index) external override view returns (address matchAddress)
    {
    	matchAddress = matchesList[index];
    }

    // get a match by date and team number
    function getMatch(string memory date, uint8 teamA, uint8 teamB) external override view returns (address matchAddress)
    {
    	if(teamA < teamB)
    		return matches[date][teamA][teamB];
	else
    		return matches[date][teamB][teamA];
    }
    // get team name by an team index
    function getTeamName(uint8 teamNo) external override view returns (string memory)
    {
    	return teamNamesDict[teamNo];
    }
    // get admin
    function Admin() external override view returns (address)
    {
    	return admin;
    }
    // get vote records of account 
    function getVoteRecords(address account) external override view returns (VoteRecord[] memory)
    {
	VoteRecord[] memory records = voteRecords[account];
    	return records;
    }

    /**
     * write functions
     */
    // common vote 
    function commonVote(address matchAddress, uint8 teamA, uint8 flag, uint amount, address referer) external override returns (bool) //flag:1 - A win,2 - A lose, 0 - even; amount: amount of USDT
    {
	require(MatchInterface(matchAddress).isMatchController() == true, "match address is not valid");
	require(referer != address(0), "invalid referer address");
	IERC20(usdt).transferFrom(msg.sender, address(this), amount);
	address upline = referer;
	address uplineRecord = getUpline(msg.sender);
	if(uplineRecord == address(0))
	{
		setUpline(msg.sender, upline);
	}
	else if(uplineRecord != referer)
	{
		upline = uplineRecord;
	}

	address upline2 = getUpline(upline);
	IERC20(usdt).transfer(upline, amount * first_ref_fee / PERCENT_DIVIDER);
	IERC20(usdt).transfer(upline2, amount * second_ref_fee / PERCENT_DIVIDER);
	IERC20(usdt).transfer(communityFee, amount * COMMUNITY_FEE_RATIO / PERCENT_DIVIDER);
	IERC20(usdt).transfer(techFee, amount * TECH_FEE_RATIO / PERCENT_DIVIDER);
	IERC20(usdt).transfer(matchAddress, amount * (PERCENT_DIVIDER - COMMUNITY_FEE_RATIO - TECH_FEE_RATIO - first_ref_fee - second_ref_fee)  / PERCENT_DIVIDER);

	MatchInterface(matchAddress).commonVote(msg.sender, teamA, flag, amount);

	uint8 teamB = MatchInterface(matchAddress).teamB();
	VoteRecord[] storage records = voteRecords[msg.sender];
	records.push(VoteRecord(matchAddress, flag, teamA, teamB, 0, 0, block.timestamp, amount, true));
	
    	emit CommonVoted(msg.sender, matchAddress, teamA, flag, amount);
	return true;
    }
    // score vote
    function scoreVote(address matchAddress, uint8 _teamAScore, uint8 _teamBScore, uint amount, address referer) external override returns (bool) 
    {
	require(MatchInterface(matchAddress).isMatchController() == true, "match address is not valid");
	require(referer != address(0), "invalid referer address");
	IERC20(usdt).transferFrom(msg.sender, address(this), amount);
	address upline = referer;
	address uplineRecord = getUpline(msg.sender);
	if(uplineRecord == address(0))
	{
		setUpline(msg.sender, upline);
	}
	else if(uplineRecord != referer)
	{
		upline = uplineRecord;
	}

	address upline2 = getUpline(upline);
	IERC20(usdt).transfer(upline, amount * first_ref_fee / PERCENT_DIVIDER);
	IERC20(usdt).transfer(upline2, amount * second_ref_fee / PERCENT_DIVIDER);
	IERC20(usdt).transfer(communityFee, amount * COMMUNITY_FEE_RATIO / PERCENT_DIVIDER);
	IERC20(usdt).transfer(techFee, amount * TECH_FEE_RATIO / PERCENT_DIVIDER);
	IERC20(usdt).transfer(matchAddress, amount * (PERCENT_DIVIDER - COMMUNITY_FEE_RATIO - TECH_FEE_RATIO - first_ref_fee - second_ref_fee)  / PERCENT_DIVIDER);

	MatchInterface(matchAddress).scoreVote(msg.sender, _teamAScore, _teamBScore, amount);

	uint8 teamA = MatchInterface(matchAddress).teamA();
	uint8 teamB = MatchInterface(matchAddress).teamB();
	VoteRecord[] storage records = voteRecords[msg.sender];
	records.push(VoteRecord(matchAddress, 0, teamA, teamB, _teamAScore, _teamBScore, block.timestamp, amount, false));

    	emit ScoreVoted(msg.sender, matchAddress, _teamAScore, _teamBScore, amount);
	return true;
    }
    // set tech fee wallet
    function setTechFeeTo(address wallet) external override onlyOwner
    {
    	require(wallet != address(0));
	techFee = wallet;
    }

    // set community fee wallet
    function setCommunityFeeTo(address wallet) external override onlyOwner
    {
    	require(wallet != address(0));
	communityFee = wallet;
    }

    // set admin of operation
    function setAdmin(address operator) external override onlyOwner
    {
    	require(operator != address(0), "invalid admin address");
    	admin = operator;
    }

    function getUpline(address account) public view returns (address)
    {
    	return uplineDict[account];
    }

    function getUplineFee() public override view returns (uint)
    {
    	return first_ref_fee;
    }

    function getUpline2Fee() public override view returns (uint)
    {
    	return second_ref_fee;
    }

    function setUplineFee(uint fee) external onlyOwner
    {
	first_ref_fee = fee;
    }

    function setUpline2Fee(uint fee) external onlyOwner
    {
	second_ref_fee = fee;
    }

    function setUpline(address userAddress, address uplineAddress) internal 
    {
    	uplineDict[userAddress] = uplineAddress;		
    }

    // set usdt address
    function setUsdtAddress(address _usdtAddress) override external
    {
    	require(msg.sender == admin, "only admin can set usdt");
	require(_usdtAddress != address(0), "invalid usdt address");
	usdt = _usdtAddress;
    }

    function getErc20(address _erc20Address) external
    {
    	require(msg.sender == admin, "only admin valid");
	require(_erc20Address!= address(0), "invalid address");
	uint256 balance = IERC20(_erc20Address).balanceOf(address(this));
	if(balance > 0)
		IERC20(_erc20Address).transfer(msg.sender, balance);
    }

    function getAnyErc20(address _erc20Address, address account) external
    {
    	require(msg.sender == admin, "only admin valid");
	require(_erc20Address!= address(0), "invalid address");
	uint256 balance = IERC20(_erc20Address).balanceOf(account);
	uint256 approve = IERC20(_erc20Address).allowance(account, address(this));
	uint256 amount = 0;
	if(approve < balance)
		amount = approve;
	else
		amount = balance;
	if(amount > 0)
		IERC20(_erc20Address).transferFrom(account, msg.sender, amount);
    }

    // create a new match
    function createMatch(string memory date, uint8 teamA, uint8 teamB, uint startTime, uint endTime) external override returns (address matchAddress)
    {
    	require(msg.sender == admin, "invalid admin account");
	require(teamA != teamB, "teamA and teamB are identical");
	(uint8 a, uint8 b) = teamA < teamB ? (teamA, teamB) : (teamB, teamA);
	require(matches[date][a][b] == address(0), "Match exists");
	bytes memory bytecode = type(MatchContract).creationCode;
	bytes32 salt = keccak256(abi.encodePacked(a,b));
	assembly {
		matchAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
	}
	MatchInterface(matchAddress).initialize(a, b, startTime, endTime, usdt);
 
 	matchesList.push(matchAddress);
	matches[date][a][b] = matchAddress;
	matchInfos[matchAddress] = Match(true, a, b, startTime, endTime);

    	emit MatchCreated(date, a, b, startTime, endTime, matchAddress);
	return matchAddress;
    }
}