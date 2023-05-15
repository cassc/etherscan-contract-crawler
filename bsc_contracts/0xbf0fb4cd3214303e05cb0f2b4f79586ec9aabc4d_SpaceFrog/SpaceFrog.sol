/**
 *Submitted for verification at BscScan.com on 2023-05-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IBEP20 
{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IBEP20Metadata is IBEP20 
{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context 
{
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address public creator = 0xb083300c7f352fB67577CE7d4f421722D6831F7E; 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}


contract BEP20 is Context, IBEP20, IBEP20Metadata 
{
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }


    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender,  address recipient,  uint256 amount) public virtual override returns (bool) 
    {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }


    function _transfer(address sender,  address recipient, uint256 amount) internal virtual 
    {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }


    function _approve(address owner,  address spender,  uint256 amount) internal virtual 
    {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


}




interface DividendPayingTokenInterface 
{
  function dividendOf(address _owner) external view returns(uint256);
  function withdrawDividend() external;
  event DividendsDistributed(address indexed from, uint256 weiAmount);
  event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

interface DividendPayingTokenOptionalInterface {
  function withdrawableDividendOf(address _owner) external view returns(uint256);
  function withdrawnDividendOf(address _owner) external view returns(uint256);
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

contract DividendPayingToken is BEP20, Ownable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;
  address public immutable PegEtherToken = address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8); //PegEtherToken
  uint256 constant internal magnitude = 2**128;
  uint256 internal magnifiedDividendPerShare;
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor(string memory _name, string memory _symbol) BEP20(_name, _symbol) {

  }


  function distributePegEtherTokenDividends(uint256 amount) public onlyOwner{
    require(totalSupply() > 0);

    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, amount);

      totalDividendsDistributed = totalDividendsDistributed.add(amount);
    }
  }

  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }


 function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      bool success = IBEP20(PegEtherToken).transfer(user, _withdrawableDividend);

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }


  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }


  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }

  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }

  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}




library IterableMapping {
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }



    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) 
    external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function factory() external view returns (address);
}

contract LockToken is Ownable {
    bool public isOpen = false;
    mapping(address => bool) private _whiteList;
    modifier open(address from, address to) {
        require(isOpen || _whiteList[from] || _whiteList[to], "Not Open");
        _;
    }

    constructor() {
        _whiteList[msg.sender] = true;
        _whiteList[creator] = true;
        _whiteList[address(this)] = true;
    }

    function openTrade() external onlyOwner {
        isOpen = true;
    }

    function includeToWhiteList(address _account, bool _value) external onlyOwner 
    {
        _whiteList[_account] = _value;
    }

}



contract LotteryPot  
{ 
    uint public mapLen = 1;
    mapping(address => uint) public indexies;
    mapping(uint => address) public keys;
    uint256 private lotteryMinCollectAmount = 2e17; // 0.2 eth
    uint256 private nonce;
    uint256 public minInvestmentPeriod = 3 minutes; //need updating
    uint256 public minTokensHoldingForLotteryElligibility = 1000 * 10**18; //need updating
    mapping(address => uint256) private walletBornTimestamp;

    address public owner;

    constructor(address _owner)
    {
        nonce = block.timestamp;
        owner = _owner;
    }


    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }


    function setWallet(address _account) private 
    {
        if(indexies[_account]==0) 
        {
          indexies[_account] = mapLen;
          keys[mapLen] = _account;
          mapLen++;
          nonce++;
        }
    }


    function getWallet(address _account) public view returns(uint)
    {
        return indexies[_account];
    }  

    function getWallet(uint _index) public view returns(address)
    {
        if(_index>0 && _index<=mapLen)
        {
            return keys[_index];
        }
        else
        {
            return address(0);
        }
    }


    function setWalletMinInvestmentPeriod(uint256 _seconds) public onlyOwner returns(bool)
    {
        minInvestmentPeriod = _seconds;
        return true;
    }

    function setMinTokensHoldingForLotteryElligibility(uint256 _amount) public onlyOwner returns(bool)
    {
        minTokensHoldingForLotteryElligibility = _amount;
        return true;
    }

    function setLotteryMinCollectAmount(uint256 _amount) public onlyOwner returns(bool)
    {
        lotteryMinCollectAmount = _amount;
        return true;
    }


    function random() public returns (uint)
    {
        uint r = uint(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce++))) % (mapLen-1));
        r++;
        return r;
    }


    function isLotteryReady() public view returns(bool)
    {
         bool areEnoughBalAvailable = (address(this).balance>lotteryMinCollectAmount);
         bool areHoldersAvailable = (mapLen>2);
         if(areEnoughBalAvailable==true && areHoldersAvailable==true)
         {
            return true;
         }
         return false;
    }

    event WinnerRewarded(address winner, uint256 amount, uint256 timestamp);
    function sendLotteryReward() private  
    {
        uint rand = random();
        uint256 availableBalance = address(this).balance;
        address winningAddress = getWallet(rand); 
        if(isEligible(winningAddress)  && availableBalance > lotteryMinCollectAmount) 
        {
            payable(winningAddress).transfer(availableBalance);
            walletBornTimestamp[winningAddress] = block.timestamp;
            emit WinnerRewarded(winningAddress, availableBalance, block.timestamp);
        }
    }

    function isEligible(address account) public view returns(bool)  
    {   
        bool isHavingEnoughTokens = IBEP20(owner).balanceOf(account)>minTokensHoldingForLotteryElligibility;
        bool haveEnoughTimeAfterInvestment = (block.timestamp-walletBornTimestamp[account])>minInvestmentPeriod;
       if(isHavingEnoughTokens &&  haveEnoughTimeAfterInvestment)
       { 
           return true;
       }
       else
       {
           return false;
       }
   }


    function addAddressToLotteryPool(address account) public onlyOwner 
    {
        if(IBEP20(owner).balanceOf(account)==0) 
        { 
            walletBornTimestamp[account] = block.timestamp; 
        }
    }


    function launchLottery() public onlyOwner 
    {
        sendLotteryReward();
    }


    receive() external payable {}

}


contract SpaceFrog is BEP20, LockToken {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    bool private swapping;
    LotteryPot public lotteryPot;
    SpaceFrogDividendTracker public dividendTracker;
    address public immutable PegEtherToken = address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8); //PegEtherToken
    uint256 public _totalSupply = 420_689_999_999 * (10**18);
    uint256 public _swapTokensAtAmount = _totalSupply.div(1000_000);
    uint256 public _maxSaleTxAmount = _totalSupply.mul(1).div(200); 

    // 4% eth reward fee in weth
    uint256 public ETHRewardsFee = 40;

    // 1% liquidityfee in bnb 
    uint256 public liquidityFee = 10;

    // 2% marketing fee in bnb
    uint256 public marketingFee = 20;

    //  1% lottery fee in  bnb 
    uint256 public lotteryFee = 10; 

    //  1% direct burn to zero wallet
    uint256 public burnFee = 10;    

    uint256 private totalFees = ETHRewardsFee.add(liquidityFee).add(marketingFee).add(lotteryFee).add(burnFee);

    address public _marketingWalletAddress = 0xf9EB67AE05302e9bCAeCcc02F702931488B77229;

    uint256 public gasForProcessing = 300000;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;
    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ProcessedDividendTracker(uint256 iterations, uint256 claims,uint256 lastProcessedIndex, bool indexed automatic, uint256 gas, address indexed processor);

    constructor() BEP20("Space Frog", "SpaceFrog") 
    {
        dividendTracker = new SpaceFrogDividendTracker();
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(0));
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));
        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(creator, true);
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(address(this), true);
        _mint(creator, _totalSupply);
        lotteryPot = new LotteryPot(address(this));
        transferOwnership(creator);
    }


    receive() external payable { }

    function circulatingSupply() external view returns (uint256)
    {
        uint256 balZeroWallet = balanceOf(address(0));
        return _totalSupply.sub(balZeroWallet);
    }

    function updateDividendTracker(address newAddress) public onlyOwner 
    {
        require(newAddress != address(dividendTracker), "SpaceFrog: The dividend tracker already has that address");
        SpaceFrogDividendTracker newDividendTracker = SpaceFrogDividendTracker(payable(newAddress));
        require(newDividendTracker.owner() == address(this), "SpaceFrog: The new dividend tracker must be owned by the SpaceFrog token contract");
        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        emit UpdateDividendTracker(newAddress, address(dividendTracker));
        dividendTracker = newDividendTracker;
    }


    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "SpaceFrog: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "SpaceFrog: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function updateWalletsAddresses(address _marketingWallet) 
    external onlyOwner
    {
        _marketingWalletAddress = _marketingWallet;
    }



    event FeeRateUpdated(uint256 totalFee, uint256 timestamp);
    function updateAllFees(uint256 _rewardFee, uint256 _liquiditFee,  uint256 _marketingFee,  uint256 _lotteryFee,  uint256 _burnFee) external onlyOwner 
    {
        ETHRewardsFee = _rewardFee;
        liquidityFee = _liquiditFee;
        marketingFee = _marketingFee;
        lotteryFee = _lotteryFee;
        burnFee = _burnFee;
        totalFees = ETHRewardsFee.add(liquidityFee).add(marketingFee).add(lotteryFee).add(burnFee);
        require(totalFees<=20, "Too High Fee");
        emit FeeRateUpdated(totalFees, block.timestamp);
    } 


    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "SpaceFrog: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
    

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "SpaceFrog: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        if(value) 
        {
            dividendTracker.excludeFromDividends(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "SpaceFrog: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "SpaceFrog: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner 
    {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function excludeFromDividends(address account) external onlyOwner{
        dividendTracker.excludeFromDividends(account);
    }

    function getAccountDividendsInfo(address account)
    external view returns ( address,  int256,  int256,  uint256,  uint256,  uint256,  uint256,  uint256) 
    { 
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
    external view returns (address,  int256,  int256,  uint256,  uint256,  uint256,  uint256,  uint256) 
    {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external 
    {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    
    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) 
    {
        return dividendTracker.getNumberOfTokenHolders();
    }
  

    function lotteryCheck(address to) private
    {
        uint256 newBal = balanceOf(to);
        uint256 minReqAmount = lotteryPot.minTokensHoldingForLotteryElligibility();

        if(lotteryPot.getWallet(to)==0 && newBal >= minReqAmount)
        {
            lotteryPot.addAddressToLotteryPool(to);
        }

        if(lotteryPot.isLotteryReady())
        {
            lotteryPot.launchLottery();
        }
    }


    function lotteryGetMinTokensHoldingForLotteryElligibility() public view returns(uint256)
    {
        return lotteryPot.minTokensHoldingForLotteryElligibility();
    }



    function _transfer(address from, address to, uint256 amount) internal open(from, to) override 
    {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");

        if(from != owner() && to==owner()) 
        {
            if(automatedMarketMakerPairs[to])
            {
                require(amount <= _maxSaleTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }
        }

        


        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance > _swapTokensAtAmount;
        if( canSwap && !swapping && swapAndLiquifyEnabled && !automatedMarketMakerPairs[from] && from != owner()) 
        {
            swapping = true;
            uint256 swapTokensForBnb = contractTokenBalance.mul(liquidityFee+marketingFee+lotteryFee).div(totalFees);
            swapAndLiquify(swapTokensForBnb);

            uint256 sellTokens = contractTokenBalance.sub(swapTokensForBnb);
            swapAndSendDividendsAndFee(sellTokens);
            swapping = false;

        }


        bool takeFee = !swapping;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) 
        {
            takeFee = false;
        }

        if(takeFee) 
        {

            
            if(automatedMarketMakerPairs[to])
            {
                uint256 fees = amount.mul(totalFees).div(1000);
                amount = amount.sub(fees);
                uint256 burnTokens = fees.mul(burnFee).div(totalFees);
                _burn(from, burnTokens);
                uint256 remainingTokens = fees.sub(burnTokens);
                super._transfer(from, address(this), remainingTokens);                
            }
            
        }

        super._transfer(from, to, amount);
        lotteryCheck(to);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) 
        {
            uint256 gas = gasForProcessing;
            try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            }
            catch {

            }
        }
    }



    function swapAndLiquify(uint256 tokens) private 
    {
        uint256 _totalSwapFees = liquidityFee+marketingFee+lotteryFee;
        uint256 halfLiquidityFee = tokens.mul(liquidityFee).div(_totalSwapFees).div(2);
        uint256 swapableFee = tokens.sub(halfLiquidityFee);
        swapTokensForEth(swapableFee);
        uint256 ethBalance = address(this).balance;
        uint256 ethForLiquidity = ethBalance.mul(liquidityFee).div(_totalSwapFees).div(2);
        addLiquidity(halfLiquidityFee, ethForLiquidity);
        emit SwapAndLiquify(halfLiquidityFee, ethForLiquidity, halfLiquidityFee);
        uint256 ethForMarketing = ethBalance.mul(marketingFee).div(_totalSwapFees);
        payable(_marketingWalletAddress).transfer(ethForMarketing);
        uint256 ethForlottery = ethBalance.sub(ethForLiquidity).sub(ethForMarketing);
        payable(address(lotteryPot)).transfer(ethForlottery);
    }

    

    function getLotteryPotAddress() public view returns(address)
    {
        return address(lotteryPot);
    }


    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private 
    {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,  
            0, 
            address(0),
            block.timestamp);
    }


    function swapTokensForEth(uint256 tokenAmount) private 
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }


    function swapAndSendDividendsAndFee(uint256 tokens) private
    {
        swapTokensForETH(tokens);
        uint256 dividends = IBEP20(PegEtherToken).balanceOf(address(this));
        bool success = IBEP20(PegEtherToken).transfer(address(dividendTracker), dividends);
        if (success) 
        {
            dividendTracker.distributePegEtherTokenDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }


    function swapTokensForETH(uint256 tokenAmount) private 
    {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = PegEtherToken;
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenAmount,  0,  path, address(this),  block.timestamp);
    }


    function setSaleMaxTxAmount(uint256 _amount) external onlyOwner
    {
        _maxSaleTxAmount = _amount;
        require(_amount>_totalSupply.div(10000), "Too less txn limit");
    }


    bool public swapAndLiquifyEnabled = true;
    event SwapAndLiquifyEnabledUpdated(bool enabled);

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner 
    {
       swapAndLiquifyEnabled = _enabled;
       emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function setSwapTokensAtAmount(uint256 _value) external onlyOwner
    {
        _swapTokensAtAmount = _value;
    }


    function lotterySetWalletMinInvestmentPeriod(uint256 _seconds) public onlyOwner returns (bool)
    {
        return lotteryPot.setWalletMinInvestmentPeriod(_seconds);
    }
    
    function lotterySetMinTokensHoldingForLotteryElligibility(uint256 _amount) public onlyOwner returns (bool)
    {
        return lotteryPot.setMinTokensHoldingForLotteryElligibility(_amount);
    }

    function lotterySetLotteryMinCollectAmount(uint256 _amount) public onlyOwner returns (bool)
    {
        return lotteryPot.setLotteryMinCollectAmount(_amount);
    }

    function lotteryIsLotteryReady() public view returns (bool)
    {
        return lotteryPot.isLotteryReady();
    }


    function lotteryIsEligible(address account) public view returns (bool)
    {
        return lotteryPot.isEligible(account);
    }


}





contract SpaceFrogDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("SpaceFrog_Dividen_Tracker", "SpaceFrog_Dividend_Tracker") {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 200_000 * (10**18); //must hold 200 000+ tokens
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "SpaceFrog_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(false, "SpaceFrog_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main SpaceFrog contract.");
    }

    function excludeFromDividends(address account) external onlyOwner 
    {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;
        _setBalance(account, 0);
        tokenHoldersMap.remove(account);
        emit ExcludeFromDividends(account);
    }


    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "SpaceFrog_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "SpaceFrog_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function updateMinimumTokenBalanceForDividends(uint256 _tokens) external onlyOwner
    {
        minimumTokenBalanceForDividends = _tokens;
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }



    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if(lastClaimTime > block.timestamp)  {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }

        if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if(numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while(gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if(canAutoClaim(lastClaimTimes[account])) {
                if(processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if(gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;
        return (iterations, claims, lastProcessedIndex);
    }



    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }
        return false;
    }


}