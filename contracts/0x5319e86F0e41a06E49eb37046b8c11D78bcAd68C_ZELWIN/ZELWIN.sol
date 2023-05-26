/**
 *Submitted for verification at Etherscan.io on 2019-11-06
*/

pragma solidity ^0.5.11;

// ----------------------------------------------------------------------------
// Standard    : ERC-20
// Symbol      : ZLW
// Name        : ZELWIN
// Total supply: 300 000 000
// Decimals    : 18
// (c) by Team @ ZELWIN 2019
// ----------------------------------------------------------------------------


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns(uint c) {
        c = a + b;
        require(c >= a, "SafeMath: addition overflow");
    }
    function sub(uint256 a, uint256 b) internal pure returns(uint c) {
        require(b <= a, "SafeMath: subtraction overflow");
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns(uint c) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
    }
    function div(uint256 a, uint256 b) internal pure returns(uint c) {
        require(b > 0, "SafeMath: division by zero");
        c = a / b;
    }
}


contract IERC20 {
    
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address to, uint256 amount) external returns(bool);
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}


contract Ownable {
    
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    
    function owner() public view returns(address) {
        return _owner;
    }

    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract Details {
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    constructor() public {
        _name = "ZELWIN";
        _symbol = "ZLW";
        _decimals = 18;
    }
    
    function name() public view returns(string memory) {
        return _name;
    }
    
    function symbol() public view returns(string memory) {
        return _symbol;
    }
    
    function decimals() public view returns(uint8) {
        return _decimals;
    }
}


contract ZELWIN is IERC20, Ownable, Details {
    using SafeMath for uint256;
    
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    constructor() public {
        _totalSupply = 300000000 * 10 ** uint256(decimals());
        _balances[owner()] = _totalSupply;
        
        emit Transfer(address(0), owner(), _totalSupply);
    }
    
    modifier isNotZeroAddress (address _address) {
        require(_address != address(0), "ERC20: Zero address");
        _;
    }
    
    modifier isNotZELWIN (address _address) {
        require(_address != address(this), "ERC20: ZELWIN Token address");
        _;
    }
    
    
    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns(uint256) {
        return _balances[account];
    }
    
    function allowance(address owner, address spender) public view returns(uint256) {
        return _allowances[owner][spender];
    }
    
    
    function transfer(address to, uint256 amount)
        public
        isNotZeroAddress(to)
        isNotZELWIN(to)
        returns(bool)
    {
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balances[to] = _balances[to].add(amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount)
        public
        isNotZeroAddress(spender)
        returns(bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue)
        public
        isNotZeroAddress(spender)
        returns (bool)
    {
        uint256 __newValue = _allowances[msg.sender][spender].add(addedValue);
        _allowances[msg.sender][spender] = __newValue;
        emit Approval(msg.sender, spender, __newValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) 
        public
        isNotZeroAddress(spender)
        returns (bool)
    {   
        uint256 __newValue = _allowances[msg.sender][spender].sub(subtractedValue);
        _allowances[msg.sender][spender] = __newValue;
        emit Approval(msg.sender, spender, __newValue);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount)
        public
        isNotZeroAddress(to)
        isNotZELWIN(to)
        returns(bool)
    {
        _balances[from] = _balances[from].sub(amount);
        _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(amount);
        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);
        return true;
    }
}