/**
 *Submitted for verification at Etherscan.io on 2020-08-03
*/

pragma solidity ^0.4.26;
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
	return (c);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
	return (c);
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
	return (c);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
	return (c);
    }
}
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);   
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);      
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens); 
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);      //sets temporary but public variable to zero after migration complete
    }
}

contract GEEQToken is ERC20Interface, Owned {
    using SafeMath for uint;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 _totalSupply;
    uint256 _totalMinted;
    uint256 _maxMintable;
    bool public pauseOn;
    bool public migrationOn;
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) allowed;   //Hate But Keep ERC20 compliance

    event PauseEvent(string pauseevent);
    event ErrorEvent(address indexed addr, string errorstr);
    event BurnEvent(address indexed addr, uint256 tokens);

    constructor() public {
        symbol = "GEEQ";
        name = "Geeq";
        decimals = 18;
        _totalMinted = 0;       //Total that has been minted. Burned tokens can not be replaced
        _totalSupply = 0;       //Total in circulation, which is minted - burned
        _maxMintable = 100000000 * 10**uint(decimals);  //Capped at 100 mil tokens
        owner = msg.sender;
    }
    
    mapping(address => bytes32) public geeqaddress;
    event MigrateEvent(address indexed addr, bytes32 geeqaddress, uint256 balance);
    function migrateGEEQ(bytes32 registeraddress) public {
        if (migrationOn){
            geeqaddress[msg.sender] = registeraddress;  //store the GEEQ wallet address in the Ethereum blockchain
            emit MigrateEvent(msg.sender, registeraddress, balances[msg.sender]);    //Ideally log the tokens for easy indexing
            burn(balances[msg.sender]);
        } else {
            emit ErrorEvent (msg.sender, "Attempted to migrate before GEEQ Migration has begun.");
        }
    }
    
    //In case someone accidentally or airdrop sends a token, the owner can retreive it.
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }    
    
    
    function pauseEnable() onlyOwner public {
        pauseOn= true;
    }
    function pauseDisable() onlyOwner public {
        pauseOn= false;
    }
    function migrationEnable() onlyOwner public {
        migrationOn= true;
    }
    function migrationDisable() onlyOwner public {
        migrationOn= false;
    }

    
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }
    function totalMinted() public constant returns (uint) {
        return _totalMinted;
    }
    function burn(uint256 tokens) internal {      //works even if contract is paused
        if(balances[msg.sender]>= tokens) {
            _totalSupply=_totalSupply.sub(balances[msg.sender]);
            balances[msg.sender] = balances[msg.sender].sub(tokens);
            balances[address(0)] = balances[address(0)].add(tokens);
            emit BurnEvent(msg.sender, tokens);
        } else {
            revert();       //necessary explicit - sender attempted to burn more tokens than owned.
        }            
    }

    //Mint function, can not create more than totalSupply
    function mint(address receiver, uint256 token_amt) onlyOwner public {            
        if( _totalMinted.add(token_amt) > _maxMintable) { 
            revert();       //Can not mint more than _maxMintable
        }
        balances[receiver] = balances[receiver].add(token_amt);
        _totalMinted =_totalMinted.add(token_amt);
        _totalSupply =_totalSupply.add(token_amt);
        emit Transfer(address(0), receiver, token_amt);      //This way the correct number of tokens will appear on Etherscan. That is the entire purpose of this event.
    } 


    //Below is the ERC20 logic, with Pause disabling transfer.
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    function transfer(address to, uint tokens) public returns (bool success) {
        if(pauseOn){
            emit ErrorEvent(msg.sender, "Contract is paused. Please migrate to the native chain with migrateGEEQ.");
            revert();           //unnecessarily explicit
        } else {
            balances[msg.sender] = balances[msg.sender].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(msg.sender, to, tokens);
            return true;           //unnecessarily explicit
        }
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    } 
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        if(pauseOn){
            emit ErrorEvent(msg.sender, "Contract is paused. Please migrate to the native chain with migrateGEEQ.");
            revert();           //unnecessarily explicit
        } else {
            balances[from] = balances[from].sub(tokens);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(from, to, tokens);
            return true;           //unnecessarily explicit
        }
    }
    
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }  
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;           //unnecessarily explicit
    }  
    function() public { }
    

}