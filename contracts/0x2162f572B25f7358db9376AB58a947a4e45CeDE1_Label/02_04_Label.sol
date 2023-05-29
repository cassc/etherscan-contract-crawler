pragma solidity ^0.5.9;

import "./ERC20Interface.sol";
import "./OwnerHelper.sol";
import "./SafeMath.sol";

contract Label is ERC20Interface, OwnerHelper
{
    using SafeMath for uint;
    
    string public name;
    uint public decimals;
    string public symbol;
    
    uint constant private E18 = 1000000000000000000;
    uint constant private month = 2592000;
    
    uint constant public maxTotalSupply     = 3000000000 * E18;
    uint constant public maxSaleSupply      = 600000000 * E18;
    uint constant public maxDevSupply       = 750000000 * E18;
    uint constant public maxMktSupply       = 750000000 * E18;
    uint constant public maxEcoSupply       = 450000000 * E18;
    uint constant public maxReserveSupply   = 210000000 * E18;
    uint constant public maxTeamSupply      = 150000000 * E18;
    uint constant public maxAdvisorSupply   = 90000000 * E18;
    
    uint constant public teamVestingSupply = 12500000 * E18;
    uint constant public teamVestingLockDate =  12 * month;
    uint constant public teamVestingTime = 12;

    uint constant public advisorVestingSupply = 22500000 * E18;
    uint constant public advisorVestingLockDate = 3 * month;
    uint constant public advisorVestingTime = 4;
    
    uint public totalTokenSupply;
    uint public tokenIssuedSale;
    uint public tokenIssuedDev;
    uint public tokenIssuedMkt;
    uint public tokenIssuedEco;
    uint public tokenIssuedRsv;
    uint public tokenIssuedTeam;
    uint public tokenIssuedAdv;
    
    uint public burnTokenSupply;
    
    mapping (address => uint) public balances;
    mapping (address => mapping ( address => uint )) public approvals;

    mapping (address => uint) public lockWallet;
    
    mapping (uint => uint) public tmVestingTimer;
    mapping (uint => uint) public tmVestingBalances;
    mapping (uint => uint) public advVestingTimer;
    mapping (uint => uint) public advVestingBalances;
        
    bool public tokenLock = true;
    bool public saleTime = true;
    uint public endSaleTime = 0;

    event SaleIssue(address indexed _to, uint _tokens);
    event DevIssue(address indexed _to, uint _tokens);
    event MktIssue(address indexed _to, uint _tokens);
    event EcoIssue(address indexed _to, uint _tokens);
    event RsvIssue(address indexed _to, uint _tokens);
    event TeamIssue(address indexed _to, uint _tokens);
    event AdvIssue(address indexed _to, uint _tokens);

    event Burn(address indexed _from, uint _tokens);
    
    event TokenUnLock(address indexed _to, uint _tokens);
    event EndSale(uint _date);
    
    constructor() public
    {
        name        = "LABEL";
        decimals    = 18;
        symbol      = "LBL";
        
        totalTokenSupply = 3000000000 * E18;
        balances[owner] = totalTokenSupply;

        tokenIssuedSale     = 0;
        tokenIssuedDev      = 0;
        tokenIssuedMkt      = 0;
        tokenIssuedEco      = 0;
        tokenIssuedRsv      = 0;
        tokenIssuedTeam     = 0;
        tokenIssuedAdv      = 0;     

        burnTokenSupply     = 0;
        
        require(maxTotalSupply == maxSaleSupply + maxDevSupply + maxMktSupply + maxEcoSupply + maxReserveSupply + maxTeamSupply + maxAdvisorSupply);
    }

    function totalSupply() view public returns (uint) 
    {
        return totalTokenSupply;
    }
    
    function balanceOf(address _who) view public returns (uint) 
    {
        uint balance = balances[_who];
        
        balance = balance.add(lockWallet[_who]);
        
        return balance;
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
    
    function setTokenUnlock() onlyManager public
    {
        require(tokenLock == true);
        require(saleTime == false);
        
        tokenLock = false;
    }
    
    function setTokenLock() onlyManager public
    {
        require(tokenLock == false);
        
        tokenLock = true;
    }
    
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
    
    function saleIssue(address _to) onlyOwner public
    {   
        require(tokenIssuedSale == 0);    
        uint tokens = maxSaleSupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[_to] = balances[_to].add(tokens);
        tokenIssuedSale = tokenIssuedSale.add(tokens);
        
        emit SaleIssue(_to, tokens);
    }
    
    function devIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedDev == 0);
        
        uint tokens = maxDevSupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[_to] = balances[_to].add(tokens);
        tokenIssuedDev = tokenIssuedDev.add(tokens);
        
        emit DevIssue(_to, tokens);
    }

    function mktIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedMkt == 0);
        
        uint tokens = maxMktSupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[_to] = balances[_to].add(tokens);
        tokenIssuedMkt = tokenIssuedMkt.add(tokens);
        
        emit MktIssue(_to, tokens);
    }
    
    function ecoIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedEco == 0);
        
        uint tokens = maxEcoSupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[_to] = balances[_to].add(tokens);
        tokenIssuedEco = tokenIssuedEco.add(tokens);
        
        emit EcoIssue(_to, tokens);
    }

    function rsvIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedRsv == 0);
        
        uint tokens = maxReserveSupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[_to] = balances[_to].add(tokens);
        tokenIssuedRsv = tokenIssuedRsv.add(tokens);
        
        emit RsvIssue(_to, tokens);
    }

    function teamIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedTeam == 0);
        
        uint tokens = maxTeamSupply;

        balances[msg.sender] = balances[msg.sender].sub(tokens);

        lockWallet[_to]    = lockWallet[_to].add(maxTeamSupply);
        
        tokenIssuedTeam = tokenIssuedTeam.add(tokens);
                
        emit TeamIssue(_to, tokens);
    }

    function advisorIssue(address _to) onlyOwner public
    {
        require(saleTime == false);
        require(tokenIssuedAdv == 0);
        
        uint tokens = maxAdvisorSupply;

        balances[msg.sender] = balances[msg.sender].sub(tokens);

        lockWallet[_to]    = lockWallet[_to].add(maxAdvisorSupply);

        tokenIssuedAdv = tokenIssuedAdv.add(tokens);
        
        emit AdvIssue(_to, tokens);
    }   
    
    function endSale() onlyOwner public
    {
        require(saleTime == true);
        require(maxSaleSupply == tokenIssuedSale);
        
        saleTime = false;
        
        uint nowTime = now;
        endSaleTime = nowTime;
        
        for(uint i = 0; i < teamVestingTime; i++)
        {
            tmVestingTimer[i] = endSaleTime + teamVestingLockDate + (i * month);
            tmVestingBalances[i] = teamVestingSupply;
        }
        
        for(uint i = 0; i < advisorVestingTime; i++)
        {
            advVestingTimer[i] = endSaleTime + advisorVestingLockDate + (i * advisorVestingLockDate);
            advVestingBalances[i] = advisorVestingSupply;
        }
        
        emit EndSale(endSaleTime);
    }
    
    function teamUnlock(address _to, uint _time) onlyManager public
    {
        require(saleTime == false);
        require( _time < teamVestingTime);
        
        uint nowTime = now;
        require( nowTime > tmVestingTimer[_time] );
        
        uint tokens = teamVestingSupply;

        require(tokens == tmVestingBalances[_time]);
        require(lockWallet[_to] > 0);
        
        balances[_to] = balances[_to].add(tokens);
        tmVestingBalances[_time] = 0;
        lockWallet[_to] = lockWallet[_to].sub(tokens);
        
        emit TokenUnLock(_to, tokens);
    }

    function advisorUnlock(address _to, uint _time) onlyManager public
    {
        require(saleTime == false);
        require( _time < advisorVestingTime);
        
        uint nowTime = now;
        require( nowTime > advVestingTimer[_time] );
        
        uint tokens = advisorVestingSupply;

        require(tokens == advVestingBalances[_time]);
        require(lockWallet[_to] > 0);
        
        balances[_to] = balances[_to].add(tokens);
        advVestingBalances[_time] = 0;
        lockWallet[_to] = lockWallet[_to].sub(tokens);
        
        emit TokenUnLock(_to, tokens);
    }


    function transferAnyERC20Token(address tokenAddress, uint tokens) onlyOwner public returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(manager, tokens);
    }
    
    function burnToken(uint _value) onlyManager public
    {
        uint tokens = _value * E18;
        
        require(balances[msg.sender] >= tokens);
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        burnTokenSupply = burnTokenSupply.add(tokens);
        totalTokenSupply = totalTokenSupply.sub(tokens);
        
        emit Burn(msg.sender, tokens);
    }
    
    function close() onlyOwner public
    {
        selfdestruct(msg.sender);
    }
    
}