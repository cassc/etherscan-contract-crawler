/**
 *Submitted for verification at Etherscan.io on 2020-07-05
*/

pragma solidity ^0.5.12;


contract LC4  {

    string public name = "LC4";
    string public symbol = "LC4";
    uint8 public constant decimals = 8;  
    uint256 totalSupply_ = 2100000000000000;
    address private _owner;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event NameChanged(string newName, address by);
    event SymbolChanged(string newName, address by);

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    

    using SafeMath for uint256;


   constructor() public {  
        _owner =  msg.sender;
	    balances[0x70b039A62E73Ad23e64ADA6eA9c60d3801191128] = totalSupply_;
        emit Transfer(address(0), 0x70b039A62E73Ad23e64ADA6eA9c60d3801191128, totalSupply_);
    }  

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    function changeName(string memory _name) public onlyOwner{
        name = _name;
        emit NameChanged(_name, msg.sender);
    }
    
     function changeSymbol(string memory _symbol) public onlyOwner{
        symbol = _symbol;
        emit SymbolChanged(_symbol, msg.sender);
    }
    
     /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    
     /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    
    
}

library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}