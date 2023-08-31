/**
 *Submitted for verification at Etherscan.io on 2023-08-30
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface DividendPayingContractOptionalInterface {
  function withdrawableDividendOf(address _owner) external view returns(uint256);
  function withdrawnDividendOf(address _owner) external view returns(uint256);
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

interface DividendPayingContractInterface {
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

contract DividendPayingContract is DividendPayingContractInterface, DividendPayingContractOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;
                                                                         
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;
  
  mapping (address => uint256) public holderBalance;
  uint256 public totalBalance;

  uint256 public totalDividendsDistributed;

  receive() external payable {
    distributeDividends();
  }

  function distributeDividends() public override payable {
    if(totalBalance > 0 && msg.value > 0){
        magnifiedDividendPerShare = magnifiedDividendPerShare.add(
            (msg.value).mul(magnitude) / totalBalance
        );
        emit DividendsDistributed(msg.sender, msg.value);

        totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
    }
  }

  function withdrawDividend() external virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);

      emit DividendWithdrawn(user, _withdrawableDividend);
      (bool success,) = user.call{value: _withdrawableDividend}("");

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }

  function dividendOf(address _owner) external view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  function withdrawnDividendOf(address _owner) external view override returns(uint256) {
    return withdrawnDividends[_owner];
  }

  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(holderBalance[_owner]).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  function _increase(address account, uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _reduce(address account, uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = holderBalance[account];
    holderBalance[account] = newBalance;
    if(newBalance > currentBalance) {
      uint256 increaseAmount = newBalance.sub(currentBalance);
      _increase(account, increaseAmount);
      totalBalance += increaseAmount;
    } else if(newBalance < currentBalance) {
      uint256 reduceAmount = currentBalance.sub(newBalance);
      _reduce(account, reduceAmount);
      totalBalance -= reduceAmount;
    }
  }
}


contract DividendTracker is DividendPayingContract {

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() {}

    function getAccount(address _account)
        public view returns (
            address account,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 balance) {
        account = _account;

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        balance = holderBalance[account];
    }
    function setBalance(address payable account, uint256 newBalance) internal {

        _setBalance(account, newBalance);

    	processAccount(account, true);
    }
    
    function processAccount(address payable account, bool automatic) internal returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

    	if(amount > 0) {
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return totalDividendsDistributed;
    }

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return holderBalance[account];
	}

    function getNumberOfDividends() external view returns(uint256) {
        return totalBalance;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract BazedRevenueStaking is ReentrancyGuard, DividendTracker {

    IERC20 public immutable bazedToken;
    IDexRouter public immutable dexRouter;

    mapping (address => uint256) public holderUnlockTime;
    uint256 public lockDuration;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _bazedToken, uint256 _lockTimeInDays) {
        require(_bazedToken != address(0), "cannot be 0 address");
        bazedToken = IERC20(_bazedToken);
        
        lockDuration = _lockTimeInDays * 1 days;

        address _v2Router;

        // @dev assumes WETH pair
        if(block.chainid == 1){
            _v2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        } else if(block.chainid == 5){
            _v2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        } else {
            revert("Chain not configured");
        }

        dexRouter = IDexRouter(_v2Router);
    }

    // Stake primary tokens
    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Zero Amount");

        if(holderUnlockTime[msg.sender] == 0){
            holderUnlockTime[msg.sender] = block.timestamp + lockDuration;
        }
        uint256 userAmount = holderBalance[msg.sender];

        uint256 amountTransferred = 0;

        uint256 initialBalance = bazedToken.balanceOf(address(this));
        bazedToken.transferFrom(address(msg.sender), address(this), _amount);
        amountTransferred = bazedToken.balanceOf(address(this)) - initialBalance;
    
        setBalance(payable(msg.sender), userAmount + amountTransferred);

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw primary tokens

    function withdraw(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Zero Amount");
        uint256 userAmount = holderBalance[msg.sender];
        require(_amount <= userAmount, "Not enough tokens");
        require(holderUnlockTime[msg.sender] <= block.timestamp, "May not withdraw early");

        bazedToken.transfer(address(msg.sender), _amount);

        setBalance(payable(msg.sender), userAmount - _amount);

        if(userAmount > 0){
            holderUnlockTime[msg.sender] = block.timestamp + lockDuration;
        } else {
            holderUnlockTime[msg.sender] = 0;
        }

        emit Withdraw(msg.sender, _amount);
    }

    function withdrawAll() public nonReentrant {
        uint256 userAmount = holderBalance[msg.sender];
        require(userAmount > 0, "Not a holder");
        require(holderUnlockTime[msg.sender] <= block.timestamp, "May not withdraw early");
        
        bazedToken.transfer(address(msg.sender), userAmount);

        setBalance(payable(msg.sender), 0);
        holderUnlockTime[msg.sender] = 0;

        emit Withdraw(msg.sender, userAmount);
    }

    function claim() external nonReentrant {
        processAccount(payable(msg.sender), false);
    }

    function compound(uint256 minOutput) external nonReentrant {
        uint256 userAmount = holderBalance[msg.sender];
        uint256 amountEthForCompound = _withdrawDividendOfUserForCompound(payable(msg.sender));
        if(amountEthForCompound > 0){
            uint256 initialBalance = bazedToken.balanceOf(address(this));
            buyBackTokens(amountEthForCompound, minOutput);
            uint256 amountTransferred = bazedToken.balanceOf(address(this)) - initialBalance;
            setBalance(payable(msg.sender), userAmount + amountTransferred);
        } else {
            revert("No rewards");
        }
    }

    function _withdrawDividendOfUserForCompound(address payable user) internal returns (uint256 _withdrawableDividend) {
        _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user] + _withdrawableDividend;
            emit DividendWithdrawn(user, _withdrawableDividend);
        }
    }

    function buyBackTokens(uint256 ethAmountInWei, uint256 minOut) internal {
        // generate the uniswap pair path of weth -> eth
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(bazedToken);

        // make the swap
        dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmountInWei}(
            minOut,
            path,
            address(this),
            block.timestamp
        );
    }

    // helper views

    function getExpectedCompoundOutputByEthAmount(uint256 rewardAmount) external view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(bazedToken);
        uint256[] memory amounts = dexRouter.getAmountsOut(rewardAmount, path);
        return amounts[1];
    }

    function getExpectedCompoundOutputByWallet(address wallet) external view returns(uint256) {
        uint256 rewardAmount = withdrawableDividendOf(wallet);
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(bazedToken);
        uint256[] memory amounts = dexRouter.getAmountsOut(rewardAmount, path);
        return amounts[1];
    }
 }