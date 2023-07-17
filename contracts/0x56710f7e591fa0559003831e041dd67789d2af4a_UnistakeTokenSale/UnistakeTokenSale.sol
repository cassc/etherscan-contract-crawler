/**
 *Submitted for verification at Etherscan.io on 2020-10-05
*/

pragma solidity 0.6.6;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}


interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  /**
   * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
   * a default value of 18.
   *
   * To select a different value for {decimals}, use {_setupDecimals}.
   *
   * All three of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(string memory name, string memory symbol) public {
    _name = name;
    _symbol = symbol;
    _decimals = 18;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
   * called.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) public override view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
  {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender)
    public
    override
    view
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
  {
    _approve(msg.sender, spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      msg.sender,
      _allowances[sender][msg.sender].sub(
        amount,
        'ERC20: transfer amount exceeds allowance'
      )
    );
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue)
    public
    returns (bool)
  {
    _approve(
      msg.sender,
      spender,
      _allowances[msg.sender][spender].add(addedValue)
    );
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      msg.sender,
      spender,
      _allowances[msg.sender][spender].sub(
        subtractedValue,
        'ERC20: decreased allowance below zero'
      )
    );
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');
    _balances[sender] = _balances[sender].sub(
      amount,
      'ERC20: transfer amount exceeds balance'
    );
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: mint to the zero address');
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: burn from the zero address');
    _balances[account] = _balances[account].sub(
      amount,
      'ERC20: burn amount exceeds balance'
    );
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}


/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is ERC20 {
  /**
   * @dev Destroys `amount` tokens from the caller.
   *
   * See {ERC20-_burn}.
   */
  function burn(uint256 amount) public virtual {
    _burn(msg.sender, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, deducting from the caller's
   * allowance.
   *
   * See {ERC20-_burn} and {ERC20-allowance}.
   *
   * Requirements:
   *
   * - the caller must have allowance for ``accounts``'s tokens of at least
   * `amount`.
   */
  function burnFrom(address account, uint256 amount) public virtual {
    uint256 decreasedAllowance = allowance(account, msg.sender).sub(
      amount,
      'ERC20: burn amount exceeds allowance'
    );
    _approve(account, msg.sender, decreasedAllowance);
    _burn(account, amount);
  }
}


/* 
 * @dev Implementation of a token compliant with the ERC20 Token protocol;
 * The token has additional burn functionality. 
 */
contract Token is ERC20Burnable {
  using SafeMath for uint256;

  /* 
 * @dev Initialization of the token, 
 * following arguments are provided via the constructor: name, symbol, recipient, totalSupply.
 * The total supply of tokens is minted to the specified recipient.
 */
  constructor(
    string memory name,
    string memory symbol,
    address recipient,
    uint256 totalSupply
  ) public ERC20(name, symbol) {
    _mint(recipient, totalSupply);
  }
}


/* 
 * @dev Implementation of the Initial Stake Offering (ISO). 
 * The ISO is a decentralized token offering with trustless liquidity provisioning, 
 * dividend accumulation and bonus rewards from staking.
 */
contract UnistakeTokenSale {
  using SafeMath for uint256;

  struct Contributor {
        uint256 phase;
        uint256 remainder;
        uint256 fromTotalDivs;
    }
  
  address payable public immutable wallet;

  uint256 public immutable totalSupplyR1;
  uint256 public immutable totalSupplyR2;
  uint256 public immutable totalSupplyR3;

  uint256 public immutable totalSupplyUniswap;

  uint256 public immutable rateR1;
  uint256 public immutable rateR2;
  uint256 public immutable rateR3;

  uint256 public immutable periodDurationR3;

  uint256 public immutable timeDelayR1;
  uint256 public immutable timeDelayR2;

  uint256 public immutable stakingPeriodR1;
  uint256 public immutable stakingPeriodR2;
  uint256 public immutable stakingPeriodR3;

  Token public immutable token;
  IUniswapV2Router02 public immutable uniswapRouter;

  uint256 public immutable decreasingPctToken;
  uint256 public immutable decreasingPctETH;
  uint256 public immutable decreasingPctRate;
  uint256 public immutable decreasingPctBonus;
  
  uint256 public immutable listingRate;
  address public immutable platformStakingContract;

  mapping(address => bool)        private _contributor;
  mapping(address => Contributor) private _contributors;
  mapping(address => uint256)[3]  private _contributions;
  
  bool[3]    private _hasEnded;
  uint256[3] private _actualSupply;

  uint256 private _startTimeR2 = 2**256 - 1;
  uint256 private _startTimeR3 = 2**256 - 1;
  uint256 private _endTimeR3   = 2**256 - 1;

  mapping(address => bool)[3] private _hasWithdrawn;

  bool    private _bonusOfferingActive;
  uint256 private _bonusOfferingActivated;
  uint256 private _bonusTotal;
  
  uint256 private _contributionsTotal;

  uint256 private _contributorsTotal;
  uint256 private _contributedFundsTotal;
 
  uint256 private _bonusReductionFactor;
  uint256 private _fundsWithdrawn;
  
  uint256 private _endedDayR3;
  
  uint256 private _latestStakingPlatformPayment;
  
  uint256 private _totalDividends;
  uint256 private _scaledRemainder;
  uint256 private _scaling = uint256(10) ** 12;
  uint256 private _phase = 1;
  uint256 private _totalRestakedDividends;
  
  mapping(address => uint256) private _restkedDividends;
  mapping(uint256 => uint256) private _payouts;         

  
  event Staked(
      address indexed account, 
      uint256 amount);
      
  event Claimed(
      address indexed account, 
      uint256 amount);
      
  event Reclaimed(
      address indexed account, 
      uint256 amount);
      
  event Withdrawn(
      address indexed account, 
      uint256 amount); 
      
  event Penalized(
      address indexed account, 
      uint256 amount);
      
  event Ended(
      address indexed account, 
      uint256 amount, 
      uint256 time);
      
  event Splitted(
      address indexed account, 
      uint256 amount1, 
      uint256 amount2);  
  
  event Bought(
      uint8 indexed round, 
      address indexed account,
      uint256 amount);
      
  event Activated(
      bool status, 
      uint256 time);


  /* 
 * @dev Initialization of the ISO,
 * following arguments are provided via the constructor: 
 * ----------------------------------------------------
 * tokenArg                    - token offered in the ISO.
 * totalSupplyArg              - total amount of tokens allocated for each round.
 * totalSupplyUniswapArg       - amount of tokens that will be sent to uniswap.
 * ratesArg                    - contribution ratio ETH:Token for each round.
 * periodDurationR3            - duration of a day during round 3.
 * timeDelayR1Arg              - time delay between round 1 and round 2.
 * timeDelayR2Arg              - time delay between round 2 and round 3.
 * stakingPeriodArg            - staking duration required to get bonus tokens for each round.
 * uniswapRouterArg            - contract address of the uniswap router object.
 * decreasingPctArg            - decreasing percentages associated with: token, ETH, rate, and bonus.
 * listingRateArg              - initial listing rate of the offered token.
 * platformStakingContractArg  - contract address of the timed distribution contract.
 * walletArg                   - account address of the team wallet.
 * 
 */
  constructor(
    address tokenArg,
    uint256[3] memory totalSupplyArg,
    uint256 totalSupplyUniswapArg,
    uint256[3] memory ratesArg,
    uint256 periodDurationR3Arg,
    uint256 timeDelayR1Arg,
    uint256 timeDelayR2Arg,
    uint256[3] memory stakingPeriodArg,
    address uniswapRouterArg,
    uint256[4] memory decreasingPctArg,
    uint256 listingRateArg,
    address platformStakingContractArg,
    address payable walletArg
    ) public {
    for (uint256 j = 0; j < 3; j++) {
        require(totalSupplyArg[j] > 0, 
        "The 'totalSupplyArg' argument must be larger than zero");
        require(ratesArg[j] > 0, 
        "The 'ratesArg' argument must be larger than zero");
        require(stakingPeriodArg[j] > 0, 
        "The 'stakingPeriodArg' argument must be larger than zero");
    }
    for (uint256 j = 0; j < 4; j++) {
        require(decreasingPctArg[j] < 10000, 
        "The 'decreasingPctArg' arguments must be less than 100 percent");
    }
    require(totalSupplyUniswapArg > 0, 
    "The 'totalSupplyUniswapArg' argument must be larger than zero");
    require(periodDurationR3Arg > 0, 
    "The 'slotDurationR3Arg' argument must be larger than zero");
    require(tokenArg != address(0), 
    "The 'tokenArg' argument cannot be the zero address");
    require(uniswapRouterArg != address(0), 
    "The 'uniswapRouterArg' argument cannot be the zero addresss");
    require(listingRateArg > 0,
    "The 'listingRateArg' argument must be larger than zero");
    require(platformStakingContractArg != address(0), 
    "The 'vestingContractArg' argument cannot be the zero address");
    require(walletArg != address(0), 
    "The 'walletArg' argument cannot be the zero address");
    
    token = Token(tokenArg);
    
    totalSupplyR1 = totalSupplyArg[0];
    totalSupplyR2 = totalSupplyArg[1];
    totalSupplyR3 = totalSupplyArg[2];
    
    totalSupplyUniswap = totalSupplyUniswapArg;
    
    periodDurationR3 = periodDurationR3Arg;
    
    timeDelayR1 = timeDelayR1Arg;
    timeDelayR2 = timeDelayR2Arg;
    
    rateR1 = ratesArg[0];
    rateR2 = ratesArg[1];
    rateR3 = ratesArg[2];
    
    stakingPeriodR1 = stakingPeriodArg[0];
    stakingPeriodR2 = stakingPeriodArg[1];
    stakingPeriodR3 = stakingPeriodArg[2];
    
    uniswapRouter = IUniswapV2Router02(uniswapRouterArg);
    
    decreasingPctToken = decreasingPctArg[0];
    decreasingPctETH = decreasingPctArg[1];
    decreasingPctRate = decreasingPctArg[2];
    decreasingPctBonus = decreasingPctArg[3];
    
    listingRate = listingRateArg;
    
    platformStakingContract = platformStakingContractArg;
    wallet = walletArg;
  }
  
  /**
   * @dev The fallback function is used for all contributions
   * during the ISO. The function monitors the current 
   * round and manages token contributions accordingly.
   */
  receive() external payable {
      if (token.balanceOf(address(this)) > 0) {
          uint8 currentRound = _calculateCurrentRound();
          
          if (currentRound == 0) {
              _buyTokenR1();
          } else if (currentRound == 1) {
              _buyTokenR2();
          } else if (currentRound == 2) {
              _buyTokenR3();
          } else {
              revert("The stake offering rounds are not active");
          }
    } else {
        revert("The stake offering must be active");
    }
  }
  
  /**
   * @dev Wrapper around the round 3 closing function.
   */     
  function closeR3() external {
      uint256 period = _calculatePeriod(block.timestamp);
      _closeR3(period);
  }
  
  /**
   * @dev This function prepares the staking and bonus reward settings
   * and it also provides liquidity to a freshly created uniswap pair.
   */  
  function activateStakesAndUniswapLiquidity() external {
      require(_hasEnded[0] && _hasEnded[1] && _hasEnded[2], 
      "all rounds must have ended");
      require(!_bonusOfferingActive, 
      "the bonus offering and uniswap paring can only be done once per ISO");
      
      uint256[3] memory bonusSupplies = [
          (_actualSupply[0].mul(_bonusReductionFactor)).div(10000),
          (_actualSupply[1].mul(_bonusReductionFactor)).div(10000),
          (_actualSupply[2].mul(_bonusReductionFactor)).div(10000)
          ];
          
      uint256 totalSupply = totalSupplyR1.add(totalSupplyR2).add(totalSupplyR3);
      uint256 soldSupply = _actualSupply[0].add(_actualSupply[1]).add(_actualSupply[2]);
      uint256 unsoldSupply = totalSupply.sub(soldSupply);
          
      uint256 exceededBonus = totalSupply
      .sub(bonusSupplies[0])
      .sub(bonusSupplies[1])
      .sub(bonusSupplies[2]);
      
      uint256 exceededUniswapAmount = _createUniswapPair(_endedDayR3); 
      
      _bonusOfferingActive = true;
      _bonusOfferingActivated = block.timestamp;
      _bonusTotal = bonusSupplies[0].add(bonusSupplies[1]).add(bonusSupplies[2]);
      _contributionsTotal = soldSupply;
      
      _distribute(unsoldSupply.add(exceededBonus).add(exceededUniswapAmount));
     
      emit Activated(true, block.timestamp);
  }
  
  /**
   * @dev This function allows the caller to stake claimable dividends.
   */   
  function restakeDividends() external {
      uint256 pending = _pendingDividends(msg.sender);
      pending = pending.add(_contributors[msg.sender].remainder);
      require(pending >= 0, "You do not have dividends to restake");
      _restkedDividends[msg.sender] = _restkedDividends[msg.sender].add(pending);
      _totalRestakedDividends = _totalRestakedDividends.add(pending);
      _bonusTotal = _bonusTotal.sub(pending);

      _contributors[msg.sender].phase = _phase;
      _contributors[msg.sender].remainder = 0;
      _contributors[msg.sender].fromTotalDivs = _totalDividends;
      
      emit Staked(msg.sender, pending);
  }

  /**
   * @dev This function is called by contributors to 
   * withdraw round 1 tokens. 
   * -----------------------------------------------------
   * Withdrawing tokens might result in bonus tokens, dividends,
   * or similar (based on the staking duration of the contributor).
   * 
   */  
  function withdrawR1Tokens() external {
      require(_bonusOfferingActive, 
      "The bonus offering is not active yet");
      
      _withdrawTokens(0);
  }
 
  /**
   * @dev This function is called by contributors to 
   * withdraw round 2 tokens. 
   * -----------------------------------------------------
   * Withdrawing tokens might result in bonus tokens, dividends,
   * or similar (based on the staking duration of the contributor).
   * 
   */      
  function withdrawR2Tokens() external {
      require(_bonusOfferingActive, 
      "The bonus offering is not active yet");
      
      _withdrawTokens(1);
  }
 
  /**
   * @dev This function is called by contributors to 
   * withdraw round 3 tokens. 
   * -----------------------------------------------------
   * Withdrawing tokens might result in bonus tokens, dividends,
   * or similar (based on the staking duration of the contributor).
   * 
   */   
  function withdrawR3Tokens() external {
      require(_bonusOfferingActive, 
      "The bonus offering is not active yet");  

      _withdrawTokens(2);
  }
 
  /**
   * @dev wrapper around the withdrawal of funds function. 
   */    
  function withdrawFunds() external {
      uint256 amount = ((address(this).balance).sub(_fundsWithdrawn)).div(2);
      
      _withdrawFunds(amount);
  }  
 
  /**
   * @dev Returns the total amount of restaked dividends in the ISO.
   */    
  function getRestakedDividendsTotal() external view returns (uint256) { 
      return _totalRestakedDividends;
  }
  
  /**
   * @dev Returns the total staking bonuses in the ISO. 
   */     
  function getStakingBonusesTotal() external view returns (uint256) {
      return _bonusTotal;
  }

  /**
   * @dev Returns the latest amount of tokens sent to the timed distribution contract.  
   */    
  function getLatestStakingPlatformPayment() external view returns (uint256) {
      return _latestStakingPlatformPayment;
  }
 
  /**
   * @dev Returns the current day of round 3.
   */   
  function getCurrentDayR3() external view returns (uint256) {
      if (_endedDayR3 != 0) {
          return _endedDayR3;
      }
      return _calculatePeriod(block.timestamp);
  }

  /**
   * @dev Returns the ending day of round 3. 
   */    
  function getEndedDayR3() external view returns (uint256) {
      return _endedDayR3;
  }

  /**
   * @dev Returns the start time of round 2. 
   */    
  function getR2Start() external view returns (uint256) {
      return _startTimeR2;
  }

  /**
   * @dev Returns the start time of round 3. 
   */  
  function getR3Start() external view returns (uint256) {
      return _startTimeR3;
  }

  /**
   * @dev Returns the end time of round 3. 
   */  
  function getR3End() external view returns (uint256) {
      return _endTimeR3;
  }

  /**
   * @dev Returns the total amount of contributors in the ISO. 
   */  
  function getContributorsTotal() external view returns (uint256) {
      return _contributorsTotal;
  }

  /**
   * @dev Returns the total amount of contributed funds (ETH) in the ISO 
   */  
  function getContributedFundsTotal() external view returns (uint256) {
      return _contributedFundsTotal;
  }
  
  /**
   * @dev Returns the current round of the ISO. 
   */  
  function getCurrentRound() external view returns (uint8) {
      uint8 round = _calculateCurrentRound();
      
      if (round == 0 && !_hasEnded[0]) {
          return 1;
      } 
      if (round == 1 && !_hasEnded[1] && _hasEnded[0]) {
          if (block.timestamp <= _startTimeR2) {
              return 0;
          }
          return 2;
      }
      if (round == 2 && !_hasEnded[2] && _hasEnded[1]) {
          if (block.timestamp <= _startTimeR3) {
              return 0;
          }
          return 3;
      } 
      else {
          return 0;
      }
  }

  /**
   * @dev Returns whether round 1 has ended or not. 
   */   
  function hasR1Ended() external view returns (bool) {
      return _hasEnded[0];
  }

  /**
   * @dev Returns whether round 2 has ended or not. 
   */   
  function hasR2Ended() external view returns (bool) {
      return _hasEnded[1];
  }

  /**
   * @dev Returns whether round 3 has ended or not. 
   */   
  function hasR3Ended() external view returns (bool) { 
      return _hasEnded[2];
  }

  /**
   * @dev Returns the remaining time delay between round 1 and round 2.
   */    
  function getRemainingTimeDelayR1R2() external view returns (uint256) {
      if (timeDelayR1 > 0) {
          if (_hasEnded[0] && !_hasEnded[1]) {
              if (_startTimeR2.sub(block.timestamp) > 0) {
                  return _startTimeR2.sub(block.timestamp);
              } else {
                  return 0;
              }
          } else {
              return 0;
          }
      } else {
          return 0;
      }
  }

  /**
   * @dev Returns the remaining time delay between round 2 and round 3.
   */  
  function getRemainingTimeDelayR2R3() external view returns (uint256) {
      if (timeDelayR2 > 0) {
          if (_hasEnded[0] && _hasEnded[1] && !_hasEnded[2]) {
              if (_startTimeR3.sub(block.timestamp) > 0) {
                  return _startTimeR3.sub(block.timestamp);
              } else {
                  return 0;
              }
          } else {
              return 0;
          }
      } else {
          return 0;
      }
  }

  /**
   * @dev Returns the total sales for round 1.
   */  
  function getR1Sales() external view returns (uint256) {
      return _actualSupply[0];
  }

  /**
   * @dev Returns the total sales for round 2.
   */  
  function getR2Sales() external view returns (uint256) {
      return _actualSupply[1];
  }

  /**
   * @dev Returns the total sales for round 3.
   */  
  function getR3Sales() external view returns (uint256) {
      return _actualSupply[2];
  }

  /**
   * @dev Returns whether the staking- and bonus functionality has been activated or not.
   */    
  function getStakingActivationStatus() external view returns (bool) {
      return _bonusOfferingActive;
  }
  
  /**
   * @dev This function allows the caller to withdraw claimable dividends.
   */    
  function claimDividends() public {
      if (_totalDividends > _contributors[msg.sender].fromTotalDivs) {
          uint256 pending = _pendingDividends(msg.sender);
          pending = pending.add(_contributors[msg.sender].remainder);
          require(pending >= 0, "You do not have dividends to claim");
          
          _contributors[msg.sender].phase = _phase;
          _contributors[msg.sender].remainder = 0;
          _contributors[msg.sender].fromTotalDivs = _totalDividends;
          
          _bonusTotal = _bonusTotal.sub(pending);

          require(token.transfer(msg.sender, pending), "Error in sending reward from contract");

          emit Claimed(msg.sender, pending);

      }
  }

  /**
   * @dev This function allows the caller to withdraw restaked dividends.
   */     
  function withdrawRestakedDividends() public {
      uint256 amount = _restkedDividends[msg.sender];
      require(amount >= 0, "You do not have restaked dividends to withdraw");
      
      claimDividends();
      
      _restkedDividends[msg.sender] = 0;
      _totalRestakedDividends = _totalRestakedDividends.sub(amount);
      
      token.transfer(msg.sender, amount);      
      
      emit Reclaimed(msg.sender, amount);
  }    
  
  /**
   * @dev Returns claimable dividends.
   */    
  function getDividends(address accountArg) public view returns (uint256) {
      uint256 amount = ((_totalDividends.sub(_payouts[_contributors[accountArg].phase - 1])).mul(getContributionTotal(accountArg))).div(_scaling);
      amount += ((_totalDividends.sub(_payouts[_contributors[accountArg].phase - 1])).mul(getContributionTotal(accountArg))) % _scaling ;
      return (amount.add(_contributors[msg.sender].remainder));
  }
 
  /**
   * @dev Returns restaked dividends.
   */   
  function getRestakedDividends(address accountArg) public view returns (uint256) { 
      return _restkedDividends[accountArg];
  }

  /**
   * @dev Returns round 1 contributions of an account. 
   */  
  function getR1Contribution(address accountArg) public view returns (uint256) {
      return _contributions[0][accountArg];
  }
  
  /**
   * @dev Returns round 2 contributions of an account. 
   */    
  function getR2Contribution(address accountArg) public view returns (uint256) {
      return _contributions[1][accountArg];
  }
  
  /**
   * @dev Returns round 3 contributions of an account. 
   */  
  function getR3Contribution(address accountArg) public view returns (uint256) { 
      return _contributions[2][accountArg];
  }

  /**
   * @dev Returns the total contributions of an account. 
   */    
  function getContributionTotal(address accountArg) public view returns (uint256) {
      uint256 contributionR1 = getR1Contribution(accountArg);
      uint256 contributionR2 = getR2Contribution(accountArg);
      uint256 contributionR3 = getR3Contribution(accountArg);
      uint256 restaked = getRestakedDividends(accountArg);

      return contributionR1.add(contributionR2).add(contributionR3).add(restaked);
  }

  /**
   * @dev Returns the total contributions in the ISO (including restaked dividends). 
   */    
  function getContributionsTotal() public view returns (uint256) {
      return _contributionsTotal.add(_totalRestakedDividends);
  }

  /**
   * @dev Returns expected round 1 staking bonus for an account. 
   */  
  function getStakingBonusR1(address accountArg) public view returns (uint256) {
      uint256 contribution = _contributions[0][accountArg];
      
      return (contribution.mul(_bonusReductionFactor)).div(10000);
  }

  /**
   * @dev Returns expected round 2 staking bonus for an account. 
   */ 
  function getStakingBonusR2(address accountArg) public view returns (uint256) {
      uint256 contribution = _contributions[1][accountArg];
      
      return (contribution.mul(_bonusReductionFactor)).div(10000);
  }

  /**
   * @dev Returns expected round 3 staking bonus for an account. 
   */ 
  function getStakingBonusR3(address accountArg) public view returns (uint256) {
      uint256 contribution = _contributions[2][accountArg];
      
      return (contribution.mul(_bonusReductionFactor)).div(10000);
  }

  /**
   * @dev Returns the total expected staking bonuses for an account. 
   */   
  function getStakingBonusTotal(address accountArg) public view returns (uint256) {
      uint256 stakeR1 = getStakingBonusR1(accountArg);
      uint256 stakeR2 = getStakingBonusR2(accountArg);
      uint256 stakeR3 = getStakingBonusR3(accountArg);

      return stakeR1.add(stakeR2).add(stakeR3);
 }   

  /**
   * @dev This function handles distribution of extra supply.
   */    
  function _distribute(uint256 amountArg) private {
      uint256 vested = amountArg.div(2);
      uint256 burned = amountArg.sub(vested);
      
      token.transfer(platformStakingContract, vested);
      token.burn(burned);
  }

  /**
   * @dev This function handles calculation of token withdrawals
   * (it also withdraws dividends and restaked dividends 
   * during certain circumstances).
   */    
  function _withdrawTokens(uint8 indexArg) private {
      require(_hasEnded[0] && _hasEnded[1] && _hasEnded[2], 
      "The rounds must be inactive before any tokens can be withdrawn");
      require(!_hasWithdrawn[indexArg][msg.sender], 
      "The caller must have withdrawable tokens available from this round");
      
      claimDividends();
      
      uint256 amount = _contributions[indexArg][msg.sender];
      uint256 amountBonus = (amount.mul(_bonusReductionFactor)).div(10000);
      
      _contributions[indexArg][msg.sender] = _contributions[indexArg][msg.sender].sub(amount);
      _contributionsTotal = _contributionsTotal.sub(amount);
      
      uint256 contributions = getContributionTotal(msg.sender);
      uint256 restaked = getRestakedDividends(msg.sender);
      
      if (contributions.sub(restaked) == 0) withdrawRestakedDividends();
    
      uint pending = _pendingDividends(msg.sender);
      _contributors[msg.sender].remainder = (_contributors[msg.sender].remainder).add(pending);
      _contributors[msg.sender].fromTotalDivs = _totalDividends;
      _contributors[msg.sender].phase = _phase;
      
      _hasWithdrawn[indexArg][msg.sender] = true;
      
      token.transfer(msg.sender, amount);
      
      _endStake(indexArg, msg.sender, amountBonus);
  }
 
  /**
   * @dev This function handles fund withdrawals.
   */  
  function _withdrawFunds(uint256 amountArg) private {
      require(msg.sender == wallet, 
      "The caller must be the specified funds wallet of the team");
      require(amountArg <= ((address(this).balance.sub(_fundsWithdrawn)).div(2)),
      "The 'amountArg' argument exceeds the limit");
      require(!_hasEnded[2], 
      "The third round is not active");
      
      _fundsWithdrawn = _fundsWithdrawn.add(amountArg);
      
      wallet.transfer(amountArg);
  }  

  /**
   * @dev This function handles token purchases for round 1.
   */ 
  function _buyTokenR1() private {
      if (token.balanceOf(address(this)) > 0) {
          require(!_hasEnded[0], 
          "The first round must be active");
          
          bool isRoundEnded = _buyToken(0, rateR1, totalSupplyR1);
          
          if (isRoundEnded == true) {
              _startTimeR2 = block.timestamp.add(timeDelayR1);
          }
      } else {
          revert("The stake offering must be active");
    }
  }
 
  /**
   * @dev This function handles token purchases for round 2.
   */   
  function _buyTokenR2() private {
      require(_hasEnded[0] && !_hasEnded[1],
      "The first round one must not be active while the second round must be active");
      require(block.timestamp >= _startTimeR2,
      "The time delay between the first round and the second round must be surpassed");
      
      bool isRoundEnded = _buyToken(1, rateR2, totalSupplyR2);
      
      if (isRoundEnded == true) {
          _startTimeR3 = block.timestamp.add(timeDelayR2);
      }
  }
 
  /**
   * @dev This function handles token purchases for round 3.
   */   
  function _buyTokenR3() private {
      require(_hasEnded[1] && !_hasEnded[2],
      "The second round one must not be active while the third round must be active");
      require(block.timestamp >= _startTimeR3,
      "The time delay between the first round and the second round must be surpassed"); 
      
      uint256 period = _calculatePeriod(block.timestamp);
      
      (bool isRoundClosed, uint256 actualPeriodTotalSupply) = _closeR3(period);

      if (!isRoundClosed) {
          bool isRoundEnded = _buyToken(2, rateR3, actualPeriodTotalSupply);
          
          if (isRoundEnded == true) {
              _endTimeR3 = block.timestamp;
              uint256 endingPeriod = _calculateEndingPeriod();
              uint256 reductionFactor = _calculateBonusReductionFactor(endingPeriod);
              _bonusReductionFactor = reductionFactor;
              _endedDayR3 = endingPeriod;
          }
      }
  }
  
  /**
   * @dev This function handles bonus payouts and the split of forfeited bonuses.
   */     
  function _endStake(uint256 indexArg, address accountArg, uint256 amountArg) private {
      uint256 elapsedTime = (block.timestamp).sub(_bonusOfferingActivated);
      uint256 payout;
      
      uint256 duration = _getDuration(indexArg);
      
      if (elapsedTime >= duration) {
          payout = amountArg;
      } else if (elapsedTime >= duration.mul(3).div(4) && elapsedTime < duration) {
          payout = amountArg.mul(3).div(4);
      } else if (elapsedTime >= duration.div(2) && elapsedTime < duration.mul(3).div(4)) {
          payout = amountArg.div(2);
      } else if (elapsedTime >= duration.div(4) && elapsedTime < duration.div(2)) {
          payout = amountArg.div(4);
      } else {
          payout = 0;
      }
      
      _split(amountArg.sub(payout));
      
      if (payout != 0) {
          token.transfer(accountArg, payout);
      }
      
      emit Ended(accountArg, amountArg, block.timestamp);
  }
 
  /**
   * @dev This function splits forfeited bonuses into dividends 
   * and to timed distribution contract accordingly.
   */     
  function _split(uint256 amountArg) private {
      if (amountArg == 0) {
        return;
      }
      
      uint256 dividends = amountArg.div(2);
      uint256 platformStakingShare = amountArg.sub(dividends);
      
      _bonusTotal = _bonusTotal.sub(platformStakingShare);
      _latestStakingPlatformPayment = platformStakingShare;
      
      token.transfer(platformStakingContract, platformStakingShare);
      
      _addDividends(_latestStakingPlatformPayment);
      
      emit Splitted(msg.sender, dividends, platformStakingShare);
  }
  
   /**
   * @dev this function handles addition of new dividends.
   */   
  function _addDividends(uint256 bonusArg) private {
      uint256 latest = (bonusArg.mul(_scaling)).add(_scaledRemainder);
      uint256 dividendPerToken = latest.div(_contributionsTotal.add(_totalRestakedDividends));
      _scaledRemainder = latest.mod(_contributionsTotal.add(_totalRestakedDividends));
      _totalDividends = _totalDividends.add(dividendPerToken);
      _payouts[_phase] = _payouts[_phase-1].add(dividendPerToken);
      _phase++;
  }
  
   /**
   * @dev returns pending dividend rewards.
   */    
  function _pendingDividends(address accountArg) private returns (uint256) {
      uint256 amount = ((_totalDividends.sub(_payouts[_contributors[accountArg].phase - 1])).mul(getContributionTotal(accountArg))).div(_scaling);
      _contributors[accountArg].remainder += ((_totalDividends.sub(_payouts[_contributors[accountArg].phase - 1])).mul(getContributionTotal(accountArg))) % _scaling ;
      return amount;
  }
  
  /**
   * @dev This function creates a uniswap pair and handles liquidity provisioning.
   * Returns the uniswap token leftovers.
   */  
  function _createUniswapPair(uint256 endingPeriodArg) private returns (uint256) {
      uint256 listingPrice = endingPeriodArg.mul(decreasingPctRate);

      uint256 ethDecrease = uint256(5000).sub(endingPeriodArg.mul(decreasingPctETH));
      uint256 ethOnUniswap = (_contributedFundsTotal.mul(ethDecrease)).div(10000);
      
      ethOnUniswap = ethOnUniswap <= (address(this).balance)
      ? ethOnUniswap
      : (address(this).balance);
      
      uint256 tokensOnUniswap = ethOnUniswap
      .mul(listingRate)
      .mul(10000)
      .div(uint256(10000).sub(listingPrice))
      .div(100000);
      
      token.approve(address(uniswapRouter), tokensOnUniswap);
      
      uniswapRouter.addLiquidityETH.value(ethOnUniswap)(
      address(token),
      tokensOnUniswap,
      0,
      0,
      wallet,
      block.timestamp
      );
      
      wallet.transfer(address(this).balance);
      
      return (totalSupplyUniswap.sub(tokensOnUniswap));
  } 
 
  /**
   * @dev this function will close round 3 if based on day and sold supply.
   * Returns whether a particular round has ended or not and 
   * the max supply of a particular day during round 3.
   */    
  function _closeR3(uint256 periodArg) private returns (bool isRoundEnded, uint256 maxPeriodSupply) {
      require(_hasEnded[0] && _hasEnded[1] && !_hasEnded[2],
      'Round 3 has ended or Round 1 or 2 have not ended yet');
      require(block.timestamp >= _startTimeR3,
      'Pause period between Round 2 and 3');
      
      uint256 decreasingTokenNumber = totalSupplyR3.mul(decreasingPctToken).div(10000);
      maxPeriodSupply = totalSupplyR3.sub(periodArg.mul(decreasingTokenNumber));
      
      if (maxPeriodSupply <= _actualSupply[2]) {
          msg.sender.transfer(msg.value);
          _hasEnded[2] = true;
          
          _endTimeR3 = block.timestamp;
          
          uint256 endingPeriod = _calculateEndingPeriod();
          uint256 reductionFactor = _calculateBonusReductionFactor(endingPeriod);
          
          _endedDayR3 = endingPeriod;
          
          _bonusReductionFactor = reductionFactor;
          return (true, maxPeriodSupply);
          
      } else {
          return (false, maxPeriodSupply);
      }
  }
 
  /**
   * @dev this function handles low level token purchases. 
   * Returns whether a particular round has ended or not.
   */     
  function _buyToken(uint8 indexArg, uint256 rateArg, uint256 totalSupplyArg) private returns (bool isRoundEnded) {
      uint256 tokensNumber = msg.value.mul(rateArg).div(100000);
      uint256 actualTotalBalance = _actualSupply[indexArg];
      uint256 newTotalRoundBalance = actualTotalBalance.add(tokensNumber);
      
      if (!_contributor[msg.sender]) {
          _contributor[msg.sender] = true;
          _contributorsTotal++;
      }  
      
      if (newTotalRoundBalance < totalSupplyArg) {
          _contributions[indexArg][msg.sender] = _contributions[indexArg][msg.sender].add(tokensNumber);
          _actualSupply[indexArg] = newTotalRoundBalance;
          _contributedFundsTotal = _contributedFundsTotal.add(msg.value);
          
          emit Bought(uint8(indexArg + 1), msg.sender, tokensNumber);
          
          return false;
          
      } else {
          uint256 availableTokens = totalSupplyArg.sub(actualTotalBalance);
          uint256 availableEth = availableTokens.mul(100000).div(rateArg);
          
          _contributions[indexArg][msg.sender] = _contributions[indexArg][msg.sender].add(availableTokens);
          _actualSupply[indexArg] = totalSupplyArg;
          _contributedFundsTotal = _contributedFundsTotal.add(availableEth);
          _hasEnded[indexArg] = true;
          
          msg.sender.transfer(msg.value.sub(availableEth));

          emit Bought(uint8(indexArg + 1), msg.sender, availableTokens);
          
          return true;
      }
  }

  /**
   * @dev Returns the staking duration of a particular round.
   */   
  function _getDuration(uint256 indexArg) private view returns (uint256) {
      if (indexArg == 0) {
          return stakingPeriodR1;
      }
      if (indexArg == 1) {
          return stakingPeriodR2;
      }
      if (indexArg == 2) {
          return stakingPeriodR3;
      }
    }
 
  /**
   * @dev Returns the bonus reduction factor.
   */       
  function _calculateBonusReductionFactor(uint256 periodArg) private view returns (uint256) {
      uint256 reductionFactor = uint256(10000).sub(periodArg.mul(decreasingPctBonus));
      return reductionFactor;
  } 
 
  /**
   * @dev Returns the current round.
   */     
  function _calculateCurrentRound() private view returns (uint8) {
      if (!_hasEnded[0]) {
          return 0;
      } else if (_hasEnded[0] && !_hasEnded[1] && !_hasEnded[2]) {
          return 1;
      } else if (_hasEnded[0] && _hasEnded[1] && !_hasEnded[2]) {
          return 2;
      } else {
          return 2**8 - 1;
      }
  }
 
  /**
   * @dev Returns the current day.
   */     
  function _calculatePeriod(uint256 timeArg) private view returns (uint256) {
      uint256 period = ((timeArg.sub(_startTimeR3)).div(periodDurationR3));
      uint256 maxPeriods = uint256(10000).div(decreasingPctToken);
      
      if (period > maxPeriods) {
          return maxPeriods;
      }
      return period;
  }
 
  /**
   * @dev Returns the ending day of round 3.
   */     
  function _calculateEndingPeriod() private view returns (uint256) {
      require(_endTimeR3 != (2**256) - 1, 
      "The third round must be active");
      
      uint256 endingPeriod = _calculatePeriod(_endTimeR3);
      return endingPeriod;
  }
 

  
  
  
  
  
}