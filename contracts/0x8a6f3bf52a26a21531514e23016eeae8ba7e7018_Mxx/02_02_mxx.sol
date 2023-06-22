pragma solidity >=0.4.22 <0.6.0;

import "./erc20.sol";

// ----------------------------------------------------------------------------
// 'MXX' token contract
// Symbol      : MXX
// Name        : Multiplier
// Total supply: 9,000,000,000.00000000
// Decimals    : 8
// ----------------------------------------------------------------------------

contract Mxx is ERC20Token {

    uint public _currentSupply;
    address public mintAddress;
    
    event Mint(address indexed to, uint tokens);
    event Burn(address indexed from, uint tokens);


    modifier onlyMint {
        require(msg.sender == owner || msg.sender == mintAddress);
        _;
    }

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function Mxx() public {
        symbol = "MXX";
        name = "Multiplier";
        decimals = 8;
        _totalSupply = 9000000000 * 10**uint(decimals);
    }

    // ------------------------------------------------------------------------
    // Owner can mint ERC20 tokens to recipient address
    // _currentSupply increase
    // balances[recipient] increase
    // ------------------------------------------------------------------------       
    function mint(address recipient, uint256 amount)
        onlyMint 
        public
    {
        require(amount > 0);
        require(_currentSupply + amount <= _totalSupply);
        
        _currentSupply = _currentSupply.add(amount);
        balances[recipient] = balances[recipient].add(amount);
        
        emit Mint(recipient, amount);
        emit Transfer(address(0), recipient, amount);
    }
  
    // ------------------------------------------------------------------------
    // Owner can burn ERC20 tokens to addres(0)
    // _totalSupply decrease
    // _currentSupply decrease
    // balanceOf msg.sender decrease
    // balanceOf addres(0) increase
    // ------------------------------------------------------------------------    
    function burn(uint256 amount) 
        onlyOwner
        public 
    {
        require(amount > 0);
        require(balances[msg.sender] >= amount);
        
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[address(0)] = balances[address(0)].add(amount);
        _totalSupply = _totalSupply.sub(amount);
        _currentSupply = _currentSupply.sub(amount);
        
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }    
    
    // Owner can change mint role
    function changeMintRole(address addr)  
        onlyOwner
        public
    {
        require(addr != address(0x0));
        require(addr != address(this));
        
        mintAddress = addr;
    }
}
