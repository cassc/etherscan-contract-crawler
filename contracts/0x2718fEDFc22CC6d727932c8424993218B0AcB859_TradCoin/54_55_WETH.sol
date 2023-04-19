pragma solidity ^0.8.10;

import "./EIP20Interface.sol";

contract WETH is EIP20Interface {
    string private _name;
    string private _symbol;
    uint8  private _decimals = 18;
    mapping (address => uint)                       public  _balanceOf;
    mapping (address => mapping (address => uint))  public  _allowance;


    constructor(string memory name_, string memory symbol_) {
	    _name = name_;
	    _symbol = symbol_;
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        _balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    
    function withdraw(uint wamount) public {
        require(_balanceOf[msg.sender] >= wamount, "sender balance insufficient for withdrawal");
        _balanceOf[msg.sender] -= wamount;
        payable(msg.sender).transfer(wamount); // rentrant attack must be less than 2300 gas
        emit Withdrawal(msg.sender, wamount);
    }

    
    function name() external view returns (string memory) {
	    return _name;
    }
    function symbol() external view returns (string memory) {
	    return _symbol;
    }
    function decimals() external view returns (uint8) {
	    return _decimals;
    }
    
    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function balanceOf(address owner) external view returns(uint256) {
	    return _balanceOf[owner];
    }
    
    
    function approve(address spender, uint amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(_balanceOf[src] >= wad, "WETH::transfeFrom: balance insufficient");

        if (src != msg.sender && _allowance[src][msg.sender] != type(uint).max) {
            require(_allowance[src][msg.sender] >= wad, "WETH::transferFrom:allowance insufficient");
            _allowance[src][msg.sender] -= wad;
        }

        _balanceOf[src] -= wad;
        _balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal   {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
	    return _allowance[owner][spender];
    }
    
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);
}