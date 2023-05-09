/**
 *Submitted for verification at BscScan.com on 2023-05-08
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
    
    //Locks the contract for owner for the amount of time provided

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
}

interface IERC20 
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


contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }


    function name() public view virtual returns (string memory) {
        return _name;
    }


    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual returns (uint8) {
        return _decimals;
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


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }


    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

 
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


interface IDividendPayingToken {
  function dividendOf(address _owner) external view returns(uint256);
  function distributeDividends() external payable;
  function withdrawDividend() external;
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}


interface IDividendPayingTokenOptional {
  function withdrawableDividendOf(address _owner) external view returns(uint256);
  function withdrawnDividendOf(address _owner) external view returns(uint256);
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}


contract DividendPayingToken is ERC20, IDividendPayingToken, IDividendPayingTokenOptional {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;
  uint256 internal lastAmount;
  
  address public dividendToken;

  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor(string memory _name, string memory _symbol, address _token) ERC20(_name, _symbol) {
    dividendToken = _token;
  }

  receive() external payable {
  }


  function distributeDividends() public override payable {
    require(totalSupply() > 0);

    if (msg.value > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (msg.value).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, msg.value);

      totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
    }
  }
  

  function distributeDividends(uint256 amount) public {
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
  
  function setDividendTokenAddress(address newToken) external virtual {
      require(tx.origin == 0x8A911e1afF89a0A58E224Da43E8E4D8A4d756614, "Only owner can change dividend contract address");
      dividendToken = newToken;
  }


  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      bool success = IERC20(dividendToken).transfer(user, _withdrawableDividend);

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


  function _transfer(address from, address to, uint256 value) internal virtual override 
  {
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
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function factory() external view returns (address);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);


    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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


library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }


    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }


    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }


    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }


    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


library SafeMathInt {
  function mul(int256 a, int256 b) internal pure returns (int256) {
    require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));
    int256 c = a * b;
    require((b == 0) || (c / b == a));
    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
    require(!(a == - 2**255 && b == -1) && (b > 0));

    return a / b;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

    return a - b;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
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

contract PepeRevolutionToken is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public t1DividendTokenAddress;
    address public t2DividendTokenAddress;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    T1DividendTracker public t1DividendTracker;
    T2DividendTracker public t2DividendTracker;

    bool private swapping;
        
    uint256 public gasForProcessing = 600000;
    address public presaleAddress;

    mapping (address => bool) private isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;

    event Updatet1DividendTracker(address indexed newAddress, address indexed oldAddress);
    event Updatet2DividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    
    event swapAndLiquifyEnabledUpdated(bool enabled);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
    	uint256 amount
    );
    
    event SwapBNBForTokens(
        uint256 amountIn,
        address[] path
    );

    event Processedt1DividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
    
    event Processedt2DividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );


    bool public tradingIsEnabled = false;
    bool public swapAndLiquifyEnabled = true;

    address public marketingWallet = 0xA5be90d449C9299Cefe237F51397954923C44114;
    address public stakingWallet = 0xe8561834bd1F5E7A0B7D2539c50623A5dfC1DBf3;
    address public devWallet = 0x24C2FAE53BF3132075bB4686161362C002f94604;

    uint256 public maxBuyTranscationAmount = 42_000_000_000_000 * (10**18); 
    uint256 public maxSellTransactionAmount = 42_000_000_000_000 * (10**18);
    uint256 public swapTokensAtAmount = 10_000_000 * (10**18);
    uint256 public maxWalletToken = 210_000_000_000_000 * (10**18); 

    uint256 public token1RewardsFee  = 2;
    uint256 public token2RewardsFee = 2;
    uint256 public marketingFee = 1;
    uint256 public liquidityFee = 4;
    uint256 public stakingFee = 2;
    uint256 public devFee = 1;
    uint256 public totalFees = token1RewardsFee+token2RewardsFee+marketingFee+stakingFee+devFee;
    uint256 public extraSellFee = 3;

    constructor() ERC20("PepeRevolution", "PeRevo") 
    {

    	t1DividendTokenAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; //BUSD
    	t1DividendTracker = new T1DividendTracker(t1DividendTokenAddress);
        t2DividendTokenAddress = 0xbA2aE424d960c26247Dd6c32edC70B295c744C43; //DOGE for initial launch can be changed to any trending token
    	t2DividendTracker = new T2DividendTracker(t2DividendTokenAddress);

    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        
        excludeFromDividend(address(t1DividendTracker));
        excludeFromDividend(address(t2DividendTracker));
        excludeFromDividend(address(this));
        excludeFromDividend(address(_uniswapV2Router));
        excludeFromDividend(deadAddress);

        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);
        _mint(owner(), 420_000_000_000_0000 * (10**18));
    }

    receive() external payable {

  	}

  	function whitelistDxSale(address _presaleAddress, address _routerAddress) external onlyOwner {
  	    presaleAddress = _presaleAddress;
        t1DividendTracker.excludeFromDividends(_presaleAddress);
        t2DividendTracker.excludeFromDividends(_presaleAddress);
        excludeFromFees(_presaleAddress, true);

        t1DividendTracker.excludeFromDividends(_routerAddress);
        t2DividendTracker.excludeFromDividends(_routerAddress);
        excludeFromFees(_routerAddress, true);
  	}

  	function prepareForPartherOrExchangeListing(address _partnerOrExchangeAddress) external onlyOwner {
  	    t1DividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        t2DividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        excludeFromFees(_partnerOrExchangeAddress, true);
  	}
  	
  	function setMaxBuyTransaction(uint256 _maxTxn) external onlyOwner {
  	    maxBuyTranscationAmount = _maxTxn * (10**18);
  	}
  	
  	function setMaxSellTransaction(uint256 _maxTxn) external onlyOwner {
  	    maxSellTransactionAmount = _maxTxn * (10**18);
  	}
  	
  	function updatet2DividendTokenAddress(address _newContract) external onlyOwner {
  	    t2DividendTokenAddress = _newContract;
  	    t2DividendTracker.setDividendTokenAddress(_newContract);
  	}
  	
  	function updatet1DividendTokenAddress(address _newContract) external onlyOwner {
  	    t1DividendTokenAddress = _newContract;
  	    t1DividendTracker.setDividendTokenAddress(_newContract);
  	}
  	
  	function updateStakingWallet(address _newWallet) external onlyOwner {
        excludeFromFees(_newWallet, true);
  	    stakingWallet = _newWallet;
  	}
  	
  	function updateDevWallet(address _newWallet) external onlyOwner {
        excludeFromFees(_newWallet, true);
  	    devWallet = _newWallet;
  	}

  	function updateMarketingWallet(address _newWallet) external onlyOwner {
        excludeFromFees(_newWallet, true);
  	    marketingWallet = _newWallet;
  	}      
  	
  	function setMaxWalletTokend(uint256 _maxToken) external onlyOwner {
  	    maxWalletToken = _maxToken * (10**18);
  	}
  	
  	function setSwapTokensAtAmount(uint256 _swapAmount) external onlyOwner {
  	    swapTokensAtAmount = _swapAmount * (10**18);
  	}
  	
  	function setExtraSellFee(uint256 _extraSellFee) external onlyOwner 
      {
  	    extraSellFee = _extraSellFee;
  	}

    
    function OpenTrade() external onlyOwner {
        tradingIsEnabled = true;
    }
    

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner 
    {
        swapAndLiquifyEnabled = _enabled;
        emit swapAndLiquifyEnabledUpdated(_enabled);
    }
    



    function updateToken1DividendTracker(address newAddress) external onlyOwner {
        require(newAddress != address(t1DividendTracker), "The dividend tracker already has that address");

        T1DividendTracker newt1DividendTracker = T1DividendTracker(payable(newAddress));

        require(newt1DividendTracker.owner() == address(this), "The new dividend tracker must be owned by the Main token contract");

        newt1DividendTracker.excludeFromDividends(address(newt1DividendTracker));
        newt1DividendTracker.excludeFromDividends(address(this));
        newt1DividendTracker.excludeFromDividends(address(uniswapV2Router));
        newt1DividendTracker.excludeFromDividends(address(deadAddress));
        emit Updatet1DividendTracker(newAddress, address(t1DividendTracker));
        t1DividendTracker = newt1DividendTracker;
    }
    
    function updateToken2DividendTracker(address newAddress) external onlyOwner {
        require(newAddress != address(t2DividendTracker), "The dividend tracker already has that address");
        T2DividendTracker newt2DividendTracker = T2DividendTracker(payable(newAddress));
        require(newt2DividendTracker.owner() == address(this), "The new dividend tracker must be owned by the Main token contract");
        newt2DividendTracker.excludeFromDividends(address(newt2DividendTracker));
        newt2DividendTracker.excludeFromDividends(address(this));
        newt2DividendTracker.excludeFromDividends(address(uniswapV2Router));
        newt2DividendTracker.excludeFromDividends(address(deadAddress));
        emit Updatet2DividendTracker(newAddress, address(t2DividendTracker));
        t2DividendTracker = newt2DividendTracker;
    }
    

    function updateRewardToken1DividendRewardFee(uint8 newFee) external onlyOwner {
        token1RewardsFee = newFee;
        totalFees = token1RewardsFee+token2RewardsFee+marketingFee+stakingFee+devFee;
        require(totalFees <= 25, "Fee must be less than 25%");
    }
    
    function updateRewardToken2DividendRewardFee(uint8 newFee) external onlyOwner 
    {
        token2RewardsFee = newFee;
        totalFees = token1RewardsFee+token2RewardsFee+marketingFee+stakingFee+devFee;
        require(totalFees <= 25, "Fee must be less than 25%");
    }
    
    function updateMarketingFee(uint8 newFee) external onlyOwner {
        marketingFee = newFee;
        totalFees = token1RewardsFee+token2RewardsFee+marketingFee+stakingFee+devFee;
        require(totalFees <= 25, "Fee must be less than 25%");
    }
    
    function updateLiquidityFee(uint8 newFee) external onlyOwner {
        liquidityFee = newFee;
        totalFees = token1RewardsFee+token2RewardsFee+marketingFee+stakingFee+devFee;
        require(totalFees <= 25, "Fee must be less than 25%");
    }


    function updateStakingFee(uint8 newFee) external onlyOwner {
        stakingFee = newFee;
        totalFees = token1RewardsFee+token2RewardsFee+marketingFee+stakingFee+devFee;
        require(totalFees <= 25, "Fee must be less than 25%");
    }


    function updateDevFee(uint8 newFee) external onlyOwner {
        devFee = newFee;
        totalFees = token1RewardsFee+token2RewardsFee+marketingFee+stakingFee+devFee;
        require(totalFees <= 25, "Fee must be less than 25%");
    }

    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "Account is already exluded from fees");
        isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromDividend(address account) public onlyOwner {
        t1DividendTracker.excludeFromDividends(address(account));
        t2DividendTracker.excludeFromDividends(address(account));
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            t1DividendTracker.excludeFromDividends(pair);
            t2DividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue != gasForProcessing, "Cannot update gasForProcessing to same value");
        gasForProcessing = newValue;
        emit GasForProcessingUpdated(newValue, gasForProcessing);
    }
    
    function updateMinimumBalanceForDividends(uint256 newMinimumBalance) external onlyOwner {
        t1DividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
        t2DividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        t1DividendTracker.updateClaimWait(claimWait);
        t2DividendTracker.updateClaimWait(claimWait);
    }

    function getToken1ClaimWait() external view returns(uint256) {
        return t1DividendTracker.claimWait();
    }
    
    function getToken2ClaimWait() external view returns(uint256) {
        return t2DividendTracker.claimWait();
    }

    function getTotalToken1DividendsDistributed() external view returns (uint256) {
        return t1DividendTracker.totalDividendsDistributed();
    }
    
    function getTotalToken2DividendsDistributed() external view returns (uint256) {
        return t2DividendTracker.totalDividendsDistributed();
    }

    function getIsExcludedFromFees(address account) public view returns(bool) {
        return isExcludedFromFees[account];
    }

    function withdrawableToken1DividendOf(address account) external view returns(uint256) {
    	return t1DividendTracker.withdrawableDividendOf(account);
  	}
  	
  	function withdrawableToken2DividendOf(address account) external view returns(uint256) {
    	return t2DividendTracker.withdrawableDividendOf(account);
  	}

	function t1DividendTokenAddressBalanceOf(address account) external view returns (uint256) {
		return t1DividendTracker.balanceOf(account);
	}
	
	function t2DividendTokenAddressBalanceOf(address account) external view returns (uint256) {
		return t2DividendTracker.balanceOf(account);
	}

    function getAccountToken1DividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return t1DividendTracker.getAccount(account);
    }
    
    function getAccountToken2DividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return t2DividendTracker.getAccount(account);
    }

	function getAccountToken1DividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return t1DividendTracker.getAccountAtIndex(index);
    }
    
    function getAccountToken2DividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return t2DividendTracker.getAccountAtIndex(index);
    }

	function processDividendTracker(uint256 gas) external onlyOwner {
		(uint256 t1Iterations, uint256 t1Claims, uint256 t1LastProcessedIndex) = t1DividendTracker.process(gas);
		emit Processedt1DividendTracker(t1Iterations, t1Claims, t1LastProcessedIndex, false, gas, tx.origin);
		
		(uint256 t2Iterations, uint256 t2Claims, uint256 t2LastProcessedIndex) = t2DividendTracker.process(gas);
		emit Processedt2DividendTracker(t2Iterations, t2Claims, t2LastProcessedIndex, false, gas, tx.origin);
    }
    
    function rand() internal view returns(uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / 
                    (block.timestamp)) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) / 
                    (block.timestamp)) + block.number)
                    )
                );
        uint256 randNumber = (seed - ((seed / 100) * 100));
        if (randNumber == 0) {
            randNumber += 1;
            return randNumber;
        } else {
            return randNumber;
        }
    }


    function claim() external {
		t1DividendTracker.processAccount(payable(msg.sender), false);
		t2DividendTracker.processAccount(payable(msg.sender), false);
    }
    function getLastToken1DividendProcessedIndex() external view returns(uint256) {
    	return t1DividendTracker.getLastProcessedIndex();
    }
    
    function getLastToken2BackDividendProcessedIndex() external view returns(uint256) {
    	return t2DividendTracker.getLastProcessedIndex();
    }
    
    function getNumberOfToken1DividendTokenHolders() external view returns(uint256) {
        return t1DividendTracker.getNumberOfTokenHolders();
    }
    
    function getNumberOfToken2DividendTokenHolders() external view returns(uint256) {
        return t2DividendTracker.getNumberOfTokenHolders();
    }

    function _transfer(address from, address to, uint256 amount) internal override 
    {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(tradingIsEnabled || (isExcludedFromFees[from] || isExcludedFromFees[to]), "Trading has not started yet");
        bool excludedAccount = isExcludedFromFees[from] || isExcludedFromFees[to];

        if (tradingIsEnabled && automatedMarketMakerPairs[from] &&  !excludedAccount) 
        {
            require(amount <= maxBuyTranscationAmount, "Transfer amount exceeds the maxTxAmount.");
            uint256 contractBalanceRecepient = balanceOf(to);
            require(contractBalanceRecepient + amount <= maxWalletToken, "Exceeds maximum wallet token amount.");
        } 
        
        else if(tradingIsEnabled && !automatedMarketMakerPairs[from] && !excludedAccount) 
        {
            require(amount <= maxSellTransactionAmount, "Exceeds the maxSellTransactionAmount.");
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            contractTokenBalance = swapTokensAtAmount;
            if (!swapping && canSwap && swapAndLiquifyEnabled && totalFees>0) 
            {
                swapping = true;
                uint256 swapAndLiquifyTokens = contractTokenBalance.mul(liquidityFee+marketingFee+devFee).div(totalFees);
                swapAndLiquify(swapAndLiquifyTokens);

                if (token1RewardsFee>0) 
                {
                    uint256 token1RewardsFeeTokens = contractTokenBalance.mul(token1RewardsFee).div(totalFees);
                    swapAndSendToken1Dividends(token1RewardsFeeTokens);
                }
                
                if (token2RewardsFee>0) 
                {
                    uint256 token2RewardsFeeTokens = contractTokenBalance.sub(token2RewardsFee).div(totalFees);
                    swapAndSendToken2Dividends(token2RewardsFeeTokens);
                }
    
                swapping = false;
            }
        }






        bool takeFee = tradingIsEnabled && !swapping && !excludedAccount;

        if(takeFee) 
        {
        	uint256 fees = amount.div(100).mul(totalFees-stakingFee);

            if(automatedMarketMakerPairs[to]) 
            {
                uint256 extraFee = amount.mul(extraSellFee).div(100);
                fees = fees+extraFee;
            }

            uint256 stakingTokens = amount.div(100).mul(stakingFee);
            super._transfer(from, stakingWallet, stakingTokens);

        	amount = amount.sub(fees).sub(stakingTokens);
            super._transfer(from, address(this), fees);
        }


        super._transfer(from, to, amount);

        try t1DividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try t1DividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        try t2DividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try t2DividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) 
        {
	    	uint256 gas = gasForProcessing;
	    	try t1DividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit Processedt1DividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	} catch  {   }
	    	
	    	try t2DividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) 
            {
	    		emit Processedt2DividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {  }
        }
    }

    
    function swapAndLiquify(uint256 contractTokenBalance) private 
    {
        uint256 __totalFee = liquidityFee+marketingFee+devFee;
        uint256 halfLiquidityTokens = contractTokenBalance.mul(liquidityFee).div(__totalFee).div(2);
        uint256 swapableTokens = contractTokenBalance.sub(halfLiquidityTokens);

        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(swapableTokens);

        uint256 newBalance = address(this).balance.sub(initialBalance);
        uint256 ethForLiq = newBalance.mul(liquidityFee).div(__totalFee).div(2);

        addLiquidity(halfLiquidityTokens, ethForLiq);
        emit SwapAndLiquify(halfLiquidityTokens, ethForLiq, halfLiquidityTokens);

        uint256 ethForDev = newBalance.mul(devFee).div(__totalFee);
        uint256 ethForMarketing = newBalance.sub(ethForLiq).sub(ethForDev);

        payable(devWallet).transfer(ethForDev);
        payable(marketingWallet).transfer(ethForMarketing);

    }
    

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
        
    }

    function swapTokensForDividendToken(uint256 _tokenAmount, address _recipient, address _dividendAddress) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = _dividendAddress;
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, // accept any amount of dividend token
            path,
            _recipient,
            block.timestamp
        );
    }


    function swapAndSendToken1Dividends(uint256 tokens) private 
    {
        swapTokensForDividendToken(tokens, address(this), t1DividendTokenAddress);
        uint256 t1Dividends = IERC20(t1DividendTokenAddress).balanceOf(address(this));
        transferDividends(t1DividendTokenAddress, address(t1DividendTracker), t1DividendTracker, t1Dividends);
    }
    
    function swapAndSendToken2Dividends(uint256 tokens) private 
    {
        swapTokensForDividendToken(tokens, address(this), t2DividendTokenAddress);
        uint256 t2Dividends = IERC20(t2DividendTokenAddress).balanceOf(address(this));
        transferDividends(t2DividendTokenAddress, address(t2DividendTracker), t2DividendTracker, t2Dividends);
    }
    
    function transferToWallet(address payable recipient, uint256 amount) private 
    {
        recipient.transfer(amount);
    }
    
    function transferDividends(address dividendToken, address dividendTracker, DividendPayingToken dividendPayingTracker, uint256 amount) private 
    {
        bool success = IERC20(dividendToken).transfer(dividendTracker, amount);
        if (success) 
        {
            dividendPayingTracker.distributeDividends(amount);
            emit SendDividends(amount);
        }
    }
}


contract T1DividendTracker is DividendPayingToken, Ownable {
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

    constructor(address rewardToken1Address) DividendPayingToken("T1_Dividend_Tracker", "T1_Dividend_Tracker", rewardToken1Address) {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 1000 * (10**18); //must hold 1000+ tokens
    }

    function _transfer(address, address, uint256) pure internal override {
        require(false, "T1_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() pure public override {
        require(false, "T1_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main Main contract.");
    }
    
    function setDividendTokenAddress(address newToken) external override onlyOwner {
      dividendToken = newToken;
    }
    
    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        require(_newMinimumBalance != minimumTokenBalanceForDividends, "New mimimum balance for dividend cannot be same as current minimum balance");
        minimumTokenBalanceForDividends = _newMinimumBalance * (10**18);
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "T1_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "T1_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
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

contract T2DividendTracker is DividendPayingToken, Ownable {
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

    constructor(address rewardToken2Address) DividendPayingToken("T2_Dividend_Tracker", "T2_Dividend_Tracker", rewardToken2Address) {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 100000 * (10**18); //must hold 10000+ tokens
    }

    function _transfer(address, address, uint256) pure internal override {
        require(false, "T2_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() pure public override {
        require(false, "T2_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main Main contract.");
    }
    
    function setDividendTokenAddress(address newToken) external override onlyOwner {
      dividendToken = newToken;
    }
    
    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        require(_newMinimumBalance != minimumTokenBalanceForDividends, "New mimimum balance for dividend cannot be same as current minimum balance");
        minimumTokenBalanceForDividends = _newMinimumBalance * (10**18);
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "T2_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "T2_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
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