/**
 *Submitted for verification at Etherscan.io on 2020-07-28
*/

pragma solidity ^0.5.9;

library SafeMath
{
  	function mul(uint256 a, uint256 b) internal pure returns (uint256)
    	{
		uint256 c = a * b;
		assert(a == 0 || c / a == b);

		return c;
  	}

  	function div(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a / b;

		return c;
  	}

  	function sub(uint256 a, uint256 b) internal pure returns (uint256)
	{
		assert(b <= a);

		return a - b;
  	}

  	function add(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a + b;
		assert(c >= a);

		return c;
  	}
}

contract OwnerHelper
{
  	address public owner;

  	event ChangeOwner(address indexed _from, address indexed _to);

  	modifier onlyOwner
	{
		require(msg.sender == owner);
		_;
  	}
  	
  	constructor() public
	{
		owner = msg.sender;
  	}
  	
  	function transferOwnership(address _to) onlyOwner public
  	{
    	require(_to != owner);
    	require(_to != address(0x0));

        address from = owner;
      	owner = _to;
  	    
      	emit ChangeOwner(from, _to);
  	}
}

contract ERC20Interface
{
    event Transfer( address indexed _from, address indexed _to, uint _value);
    event Approval( address indexed _owner, address indexed _spender, uint _value);
    
    function totalSupply() view public returns (uint _supply);
    function balanceOf( address _who ) public view returns (uint _value);
    function transfer( address _to, uint _value) public returns (bool _success);
    function approve( address _spender, uint _value ) public returns (bool _success);
    function allowance( address _owner, address _spender ) public view returns (uint _allowance);
    function transferFrom( address _from, address _to, uint _value) public returns (bool _success);
}

contract GIGXToken is ERC20Interface, OwnerHelper
{
    using SafeMath for uint;
    
    string public name;
    uint public decimals;
    string public symbol;
    
    uint constant private E18 = 1000000000000000000;
    uint constant private month = 2592000;
	
	//Thursday, 27-Aug-20 00:00:00 UTC RFC 2822
    uint constant private eventStartDate = 1598486400;

    // Total                                            5,000,000,000 
    uint constant public maxTotalSupply =            5000000000 * E18;
    
    // Early bird(2 years Lockup)                         1,000,000,000(20%)
    uint constant public maxEarlyBirdSupply =             1000000000 * E18;
    uint constant public earlyBirdLockDate        = 24 * month;
    uint public earlyBirdVestingTime;
    // Platform development and maintenance(20month vesting)  1,000,000,000(20%)
    uint constant public maxPlDvnMtSupply =              1000000000 * E18;
    uint constant public pldvnmtVestingTime = 20;
    uint constant public pldvnmtVestingSupply = maxPlDvnMtSupply / pldvnmtVestingTime;
    mapping (uint => uint) public pldvnmtVestingTimer;
    mapping (uint => uint) public pldvnmtVestingBalances;
    // Marketing(15month vesting)                              750,000,000 (15%)
    uint constant public maxMktSupply =              750000000 * E18;
    uint constant public mktVestingTime = 15;
    uint constant public mktVestingSupply = maxMktSupply / mktVestingTime;
    mapping (uint => uint) public mktVestingTimer;
    mapping (uint => uint) public mktVestingBalances;
    // gig# membership                               500,000,000 (10%)
    uint constant public maxMembershipSupply =        500000000 * E18;
    // Talent reward(10month vesting)                 500,000,000 (10%)
    uint constant public maxTalentRwdSupply =      500000000 * E18;
    uint constant public talentRwdVestingTime = 10;
    uint constant public talentRwdVestingSupply = maxTalentRwdSupply / talentRwdVestingTime;
    mapping (uint => uint) public talentRwdVestingTimer;
    mapping (uint => uint) public talentRwdVestingBalances;
    // User Reward(10month vesting)                    500,000,000 (10%)
    uint constant public maxUserRwdSupply =        500000000 * E18;
    uint constant public userRwdRewardVestingTime = 10;
    uint constant public userRwdVestingSupply = maxUserRwdSupply / userRwdRewardVestingTime;
    mapping (uint => uint) public userRwdVestingTimer;
    mapping (uint => uint) public userRwdVestingBalances;
    // Partners(1 year Lockup)                        250,000,000 (5%)
    uint constant public maxPartnerSupply =           250000000 * E18;
    uint constant public partnerLockDate        = 12 * month;
    uint public partnerVestingTime;
    // Team(2 years Lockup)                                250,000,000 (5%)
    uint constant public maxTeamSupply =             250000000 * E18;
    uint constant public teamLockDate        = 24 * month;
    uint public teamVestingTime;
    // Reserve(5month vesting)                          250,000,000 (5%)
    uint constant public maxRsvSupply =             250000000 * E18;
    uint constant public rsvVestingTime = 5;
    uint constant public rsvVestingSupply = maxRsvSupply / rsvVestingTime;
    mapping (uint => uint) public rsvVestingTimer;
    mapping (uint => uint) public rsvVestingBalances;
    
    uint public totalTokenSupply;
    uint public tokenIssuedEarlyBird;
    uint public tokenIssuedPlDvnMt;
    uint public tokenIssuedMkt;
    uint public tokenIssuedMembership;
    uint public tokenIssuedTalantRwd;
    uint public tokenIssuedUserRwd;
    uint public tokenIssuedPartner;
    uint public tokenIssuedTeam;
    uint public tokenIssuedRsv;

    uint public burnTokenSupply;
    
    mapping (address => uint) public balances;
    mapping (address => mapping ( address => uint )) public approvals;
    
    
    
    bool public tokenLock = false;
    
    event EarlyBirdIssue(address indexed _to, uint _tokens);
    event PlDvnMtIssue(address indexed _to, uint _tokens);
    event MktIssue(address indexed _to, uint _tokens);
    event MembershipIssue(address indexed _to, uint _tokens);
    event TalentRwdIssue(address indexed _to, uint _tokens);
    event UserRwdIssue(address indexed _to, uint _tokens);
    event PartnerIssue(address indexed _to, uint _tokens);
    event TeamIssue(address indexed _to, uint _tokens);
    event RsvIssue(address indexed _to, uint _tokens);
    
    event Burn(address indexed _from, uint _tokens);
    

    constructor() public
    {
        name        = "gig#";
        decimals    = 18;
        symbol      = "GIGX";

        totalTokenSupply    = 0;
        tokenIssuedEarlyBird   = 0;
        tokenIssuedPlDvnMt      = 0;
        tokenIssuedMkt          = 0;
        tokenIssuedMembership     = 0;
        tokenIssuedTalantRwd      = 0;
        tokenIssuedUserRwd    = 0;
        tokenIssuedPartner    = 0;
        tokenIssuedTeam     = 0;
        tokenIssuedRsv     = 0;

        burnTokenSupply     = 0;

        earlyBirdVestingTime = eventStartDate + earlyBirdLockDate;
        partnerVestingTime = eventStartDate + partnerLockDate;
        teamVestingTime = eventStartDate + teamLockDate;
        
        for(uint i = 0; i < pldvnmtVestingTime; i++)
        {
            pldvnmtVestingTimer[i] =  eventStartDate + (month * i);
            pldvnmtVestingBalances[i] = pldvnmtVestingSupply;
        }
        
        for(uint i = 0; i < mktVestingTime; i++)
        {
            mktVestingTimer[i] = eventStartDate + (month * i);
            mktVestingBalances[i] = mktVestingSupply;
        }

        for(uint i = 0; i < talentRwdVestingTime; i++)
        {
            talentRwdVestingTimer[i] = eventStartDate + (month * i);
            talentRwdVestingBalances[i] = talentRwdVestingSupply;
        }

        for(uint i = 0; i < userRwdRewardVestingTime; i++)
        {
            userRwdVestingTimer[i] = eventStartDate + (month * i);
            userRwdVestingBalances[i] = userRwdVestingSupply;
        }
        for(uint i = 0; i < rsvVestingTime; i++)
        {
            rsvVestingTimer[i] = eventStartDate + (month * i);
            rsvVestingBalances[i] = rsvVestingSupply;
        }
        
        require(maxTotalSupply == maxEarlyBirdSupply + maxPlDvnMtSupply + maxMktSupply + maxMembershipSupply + maxTalentRwdSupply + maxUserRwdSupply + maxPartnerSupply + maxTeamSupply + maxRsvSupply);
    }
    
    // ERC - 20 Interface -----

    function totalSupply() view public returns (uint) 
    {
        return totalTokenSupply;
    }
    
    function balanceOf(address _who) view public returns (uint) 
    {
        return balances[_who];
    }
    
    function transfer(address _to, uint _value) public returns (bool) 
    {
        require(isTransferable() == true);
        require(balances[msg.sender] >= _value);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint _value) public returns (bool)
    {
        require(isTransferable() == true);
        require(balances[msg.sender] >= _value);
        
        approvals[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true; 
    }
    
    function allowance(address _owner, address _spender) view public returns (uint) 
    {
        return approvals[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) 
    {
        require(isTransferable() == true);
        require(balances[_from] >= _value);
        require(approvals[_from][msg.sender] >= _value);
        
        approvals[_from][msg.sender] = approvals[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to]  = balances[_to].add(_value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    // -----
    
    // Vesting Function -----
    
    function earlyBirdIssue(address _to) onlyOwner public
    {
        
        uint nowTime = now;
        require(nowTime > earlyBirdVestingTime);
        
        uint tokens = maxEarlyBirdSupply;

        require(maxEarlyBirdSupply >= tokenIssuedEarlyBird.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedEarlyBird = tokenIssuedEarlyBird.add(tokens);
        
        emit Transfer(address(0x0), _to, tokens);
        emit EarlyBirdIssue(_to, tokens);
    }
    
    // _time : 0 ~ 19
    function pldvnmtIssue(address _to, uint _time) onlyOwner public
    {
        require(_time < pldvnmtVestingTime);
        
        uint nowTime = now;
        require( nowTime > pldvnmtVestingTimer[_time] );
        
        uint tokens = pldvnmtVestingSupply;

        require(tokens == pldvnmtVestingBalances[_time]);
        require(maxPlDvnMtSupply >= tokenIssuedPlDvnMt.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        pldvnmtVestingBalances[_time] = 0;
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedPlDvnMt = tokenIssuedPlDvnMt.add(tokens);
        
        emit Transfer(address(0x0), _to, tokens);
        emit PlDvnMtIssue(_to, tokens);
    }
    // _time : 0 ~ 14
    function mktIssue(address _to, uint _time) onlyOwner public
    {
        require(_time < mktVestingTime);
        
        uint nowTime = now;
        require( nowTime > mktVestingTimer[_time] );
        
        uint tokens = mktVestingSupply;

        require(tokens == mktVestingBalances[_time]);
        require(maxMktSupply >= tokenIssuedMkt.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        mktVestingBalances[_time] = 0;
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedMkt = tokenIssuedMkt.add(tokens);
        
        emit Transfer(address(0x0), _to, tokens);
        emit MktIssue(_to, tokens);
    }
    function membershipIssue(address _to) onlyOwner public
    {
        require(tokenIssuedMembership == 0);
        
        uint tokens = maxMembershipSupply;
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedMembership = tokenIssuedMembership.add(tokens);
        
        emit Transfer(address(0x0), _to, tokens);
        emit MembershipIssue(_to, tokens);
    }
    // _time : 0 ~ 9
    function talentRwdIssue(address _to, uint _time) onlyOwner public
    {
        require(_time < talentRwdVestingTime);
        
        uint nowTime = now;
        require( nowTime > talentRwdVestingTimer[_time] );
        
        uint tokens = talentRwdVestingSupply;

        require(tokens == talentRwdVestingBalances[_time]);
        require(talentRwdVestingSupply >= tokenIssuedTalantRwd.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        talentRwdVestingBalances[_time] = 0;
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedTalantRwd = tokenIssuedTalantRwd.add(tokens);
        
        emit Transfer(address(0x0), _to, tokens);
        emit TalentRwdIssue(_to, tokens);
    }
    // _time : 0 ~ 9
    function userRwdIssue(address _to, uint _time) onlyOwner public
    {
        require(_time < mktVestingTime);
        
        uint nowTime = now;
        require( nowTime > userRwdVestingTimer[_time] );
        
        uint tokens = userRwdVestingSupply;

        require(tokens == userRwdVestingBalances[_time]);
        require(maxMktSupply >= tokenIssuedUserRwd.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        userRwdVestingBalances[_time] = 0;
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedUserRwd = tokenIssuedUserRwd.add(tokens);
        
        emit Transfer(address(0x0), _to, tokens);
        emit UserRwdIssue(_to, tokens);
    }
    function partnerIssue(address _to) onlyOwner public
    {
        uint nowTime = now;
        require(nowTime > partnerVestingTime);
        
        uint tokens = maxPartnerSupply;

        require(maxPartnerSupply >= tokenIssuedPartner.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedPartner = tokenIssuedPartner.add(tokens);
        
        emit Transfer(address(0x0), _to, tokens);
        emit PartnerIssue(_to, tokens);
    }
    function teamIssue(address _to) onlyOwner public
    {
        uint nowTime = now;
        require(nowTime > teamVestingTime);
        
        uint tokens = maxTeamSupply;

        require(maxTeamSupply >= tokenIssuedTeam.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedTeam = tokenIssuedTeam.add(tokens);
        
        emit Transfer(address(0x0), _to, tokens);
        emit TeamIssue(_to, tokens);
    }
     // _time : 0 ~ 4
    function rsvIssue(address _to, uint _time) onlyOwner public
    {
        require(_time < rsvVestingTime);
        
        uint nowTime = now;
        require( nowTime > rsvVestingTimer[_time] );
        
        uint tokens = rsvVestingSupply;

        require(tokens == rsvVestingBalances[_time]);
        require(rsvVestingSupply >= tokenIssuedRsv.add(tokens));
        
        balances[_to] = balances[_to].add(tokens);
        rsvVestingBalances[_time] = 0;
        
        totalTokenSupply = totalTokenSupply.add(tokens);
        tokenIssuedRsv = tokenIssuedRsv.add(tokens);
        
        emit Transfer(address(0x0), _to, tokens);
        emit RsvIssue(_to, tokens);
    }
    
    
    // -----
    
    // Lock Function -----
    
    function isTransferable() private view returns (bool)
    {
        if(tokenLock == false)
        {
            return true;
        }
        else if(msg.sender == owner)
        {
            return true;
        }
        
        return false;
    }
    
    function setTokenUnlock() onlyOwner public
    {
        require(tokenLock == true);
        
        tokenLock = false;
    }
    
    function setTokenLock() onlyOwner public
    {
        require(tokenLock == false);
        
        tokenLock = true;
    }
    
    
    function withdrawTokens(address _contract, uint _decimals, uint _value) onlyOwner public
    {

        if(_contract == address(0x0))
        {
            uint eth = _value.mul(10 ** _decimals);
            msg.sender.transfer(eth);
        }
        else
        {
            uint tokens = _value.mul(10 ** _decimals);
            ERC20Interface(_contract).transfer(msg.sender, tokens);
            
            emit Transfer(address(0x0), msg.sender, tokens);
        }
    }
    
    function burnToken(uint _value) onlyOwner public
    {
        uint tokens = _value * E18;
        
        require(balances[msg.sender] >= tokens);
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        
        burnTokenSupply = burnTokenSupply.add(tokens);
        totalTokenSupply = totalTokenSupply.sub(tokens);
        
        emit Transfer(msg.sender, address(0x0),tokens);
        emit Burn(msg.sender, tokens);
    }
    
    function close() onlyOwner public
    {
        selfdestruct(msg.sender);
    }
    
    // -----
}