/**
 *Submitted for verification at Etherscan.io on 2020-11-16
*/

// File: node_modules\openzeppelin-solidity\contracts\GSN\Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: node_modules\openzeppelin-solidity\contracts\token\ERC20\IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: node_modules\openzeppelin-solidity\contracts\math\SafeMath.sol

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: node_modules\openzeppelin-solidity\contracts\token\ERC20\ERC20.sol

pragma solidity ^0.5.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
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
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

// File: node_modules\openzeppelin-solidity\contracts\token\ERC20\ERC20Detailed.sol

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: node_modules\openzeppelin-solidity\contracts\utils\ReentrancyGuard.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// File: node_modules\openzeppelin-solidity\contracts\utils\Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: contracts\Eclipseum.sol

pragma solidity =0.5.17;

/// @title The Eclipseum ERC20 Smart Contract
contract Eclipseum is ERC20, ERC20Detailed, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address payable;

    struct SoftSellEclAmountsToReceive {
        uint256 ethFromEclPool;
        uint256 ethFromDaiPool;
        uint256 daiFromDaiPool;
    }

    IERC20 public daiInterface;
    bool public launched;
    uint256 public ethBalanceOfEclPool;
    uint256 public ethVolumeOfEclPool;
    uint256 public ethVolumeOfDaiPool;

    event LogBuyEcl(
        address indexed userAddress,
        uint256 ethSpent,
        uint256 eclReceived
    );
    event LogSellEcl(
        address indexed userAddress,
        uint256 eclSold,
        uint256 ethReceived
    );
    event LogSoftSellEcl(
        address indexed userAddress,
        uint256 eclSold,
        uint256 ethReceived,
        uint256 daiReceived
    );
    event LogBuyDai(
        address indexed userAddress,
        uint256 ethSpent,
        uint256 daiReceived
    );
    event LogSellDai(
        address indexed userAddress,
        uint256 daiSold,
        uint256 ethReceived
    );

    modifier requireLaunched() {
        require(launched, "Contract must be launched to invoke this function.");
        _;
    }

    /// @notice Must be called with at least 0.02 ETH.
    /// @notice Mints 100,000 ECL into the contract account
    constructor(address _daiAddress)
        public
        payable
        ERC20Detailed("Eclipseum", "ECL", 18)
    {
        require(
            msg.value >= 0.02 ether,
            "Must call constructor with at least 0.02 Ether."
        );

        _mint(address(this), 1e5 * (10**18));
        daiInterface = IERC20(_daiAddress);
    }

    /// @notice This function is called once after deployment to launch the contract.
    /// @notice Some amount of DAI must be transferred to the contract for launch to succeed.
    /// @notice Once launched, the transaction functions may be invoked.
    function launch() external {
        require(!launched, "Contract has already been launched.");
        require(
            daiInterface.balanceOf(address(this)) > 0,
            "DAI pool balance must be greater than zero to launch contract."
        );

        ethBalanceOfEclPool = 0.01 ether;
        launched = true;
    }

    /// @notice Enables a user to buy ECL with ETH from the ECL liquidity pool.
    /// @param minEclToReceive The minimum amount of ECL the user is willing to receive.
    /// @param deadline Epoch time deadline that the transaction must complete before, otherwise reverts.
    function buyEcl(uint256 minEclToReceive, uint256 deadline)
        external
        payable
        nonReentrant
        requireLaunched
    {
        require(
            deadline >= block.timestamp,
            "Transaction deadline has elapsed."
        );
        require(msg.value > 0, "Value of ETH sent must be greater than zero.");

        uint256 ethBalanceOfDaiPoolLocal = ethBalanceOfDaiPool().sub(msg.value);
        uint256 eclBalanceOfEclPoolLocal = eclBalanceOfEclPool();
        uint256 eclToReceive = applyTransactionFee(
            calcBOut(ethBalanceOfEclPool, eclBalanceOfEclPoolLocal, msg.value)
        );
        uint256 eclToMint = eclToReceive.mul(7).div(6).add(1);
        uint256 ethTransferToDaiPool = calcEthTransferForBuyEcl(
            ethBalanceOfEclPool,
            ethBalanceOfDaiPoolLocal,
            msg.value
        );

        require(
            eclToReceive >= minEclToReceive,
            "Unable to send the minimum quantity of ECL to receive."
        );

        ethBalanceOfEclPool = ethBalanceOfEclPool.add(msg.value).sub(
            ethTransferToDaiPool
        );
        ethBalanceOfDaiPoolLocal = ethBalanceOfDaiPoolLocal.add(
            ethTransferToDaiPool
        );
        eclBalanceOfEclPoolLocal = eclBalanceOfEclPoolLocal
            .sub(eclToReceive)
            .add(eclToMint);
        ethVolumeOfEclPool += msg.value;

        emit LogBuyEcl(msg.sender, msg.value, eclToReceive);

        _transfer(address(this), msg.sender, eclToReceive);
        _mint(address(this), eclToMint);

        assert(ethBalanceOfDaiPoolLocal == ethBalanceOfDaiPool());
        assert(eclBalanceOfEclPoolLocal == eclBalanceOfEclPool());
        assert(ethBalanceOfEclPool > 0);
        assert(ethBalanceOfDaiPool() > 0);
        assert(eclBalanceOfEclPool() > 0);
        assert(daiBalanceOfDaiPool() > 0);
    }

    /// @notice Enables a user to sell ECL for ETH to the ECL liquidity pool.
    /// @param eclSold The amount of ECL the user is selling.
    /// @param minEthToReceive The minimum amount of ETH the user is willing to receive.
    /// @param deadline Epoch time deadline that the transaction must complete before.
    function sellEcl(
        uint256 eclSold,
        uint256 minEthToReceive,
        uint256 deadline
    ) external nonReentrant requireLaunched {
        require(
            deadline >= block.timestamp,
            "Transaction deadline has elapsed."
        );
        require(eclSold > 0, "Value of ECL sold must be greater than zero.");
        require(
            eclSold <= balanceOf(address(msg.sender)),
            "ECL sold must be less than or equal to ECL balance."
        );

        uint256 ethBalanceOfDaiPoolLocal = ethBalanceOfDaiPool();
        uint256 eclBalanceOfEclPoolLocal = eclBalanceOfEclPool();
        uint256 eclToBurn = eclSold.mul(7).div(6);
        uint256 ethToReceive = applyTransactionFee(
            calcBOut(eclBalanceOfEclPoolLocal, ethBalanceOfEclPool, eclSold)
        );

        require(
            ethToReceive >= minEthToReceive,
            "Unable to send the minimum quantity of ETH to receive."
        );

        ethBalanceOfEclPool = ethBalanceOfEclPool.sub(ethToReceive);
        eclBalanceOfEclPoolLocal = eclBalanceOfEclPoolLocal.add(eclSold).sub(
            eclToBurn
        );
        ethVolumeOfEclPool += ethToReceive;

        emit LogSellEcl(msg.sender, eclSold, ethToReceive);

        _transfer(address(msg.sender), address(this), eclSold);
        _burn(address(this), eclToBurn);
        msg.sender.sendValue(ethToReceive);

        assert(ethBalanceOfDaiPoolLocal == ethBalanceOfDaiPool());
        assert(eclBalanceOfEclPoolLocal == eclBalanceOfEclPool());
        assert(ethBalanceOfEclPool > 0);
        assert(ethBalanceOfDaiPool() > 0);
        assert(eclBalanceOfEclPool() > 0);
        assert(daiBalanceOfDaiPool() > 0);
    }

    /// @notice Enables a user to sell ECL for ETH and DAI to the ECL liquidity pool.
    /// @param eclSold The amount of ECL the user is selling.
    /// @param minEthToReceive The minimum amount of ETH the user is willing to receive.
    /// @param minDaiToReceive The minimum amount of DAI the user is willing to receive.
    /// @param deadline Epoch time deadline that the transaction must complete before.
    function softSellEcl(
        uint256 eclSold,
        uint256 minEthToReceive,
        uint256 minDaiToReceive,
        uint256 deadline
    ) external nonReentrant requireLaunched {
        require(
            deadline >= block.timestamp,
            "Transaction deadline has elapsed."
        );
        require(eclSold > 0, "Value of ECL sold must be greater than zero.");
        require(
            eclSold <= balanceOf(address(msg.sender)),
            "ECL sold must be less than or equal to ECL balance."
        );

        uint256 ethBalanceOfDaiPoolLocal = ethBalanceOfDaiPool();
        uint256 circulatingSupplyLocal = circulatingSupply();
        uint256 eclBalanceOfEclPoolLocal = eclBalanceOfEclPool();
        uint256 daiBalanceOfDaiPoolLocal = daiBalanceOfDaiPool();
        uint256 eclToBurn = applyTransactionFee(
            eclSold.mul(eclBalanceOfEclPoolLocal).div(circulatingSupplyLocal)
        )
            .add(eclSold);
        SoftSellEclAmountsToReceive memory amountsToReceive;
        amountsToReceive.ethFromEclPool = applyTransactionFee(
            eclSold.mul(ethBalanceOfEclPool).div(circulatingSupplyLocal)
        );
        amountsToReceive.ethFromDaiPool = applyTransactionFee(
            eclSold.mul(ethBalanceOfDaiPoolLocal).div(circulatingSupplyLocal)
        );
        amountsToReceive.daiFromDaiPool = applyTransactionFee(
            eclSold.mul(daiBalanceOfDaiPoolLocal).div(circulatingSupplyLocal)
        );

        require(
            amountsToReceive.ethFromEclPool.add(
                amountsToReceive.ethFromDaiPool
            ) >= minEthToReceive,
            "Unable to send the minimum quantity of ETH to receive."
        );
        require(
            amountsToReceive.daiFromDaiPool >= minDaiToReceive,
            "Unable to send the minimum quantity of DAI to receive."
        );

        ethBalanceOfEclPool = ethBalanceOfEclPool.sub(
            amountsToReceive.ethFromEclPool
        );
        ethBalanceOfDaiPoolLocal = ethBalanceOfDaiPoolLocal.sub(
            amountsToReceive.ethFromDaiPool
        );
        daiBalanceOfDaiPoolLocal = daiBalanceOfDaiPoolLocal.sub(
            amountsToReceive.daiFromDaiPool
        );
        eclBalanceOfEclPoolLocal = eclBalanceOfEclPoolLocal.add(eclSold).sub(
            eclToBurn
        );
        ethVolumeOfEclPool += amountsToReceive.ethFromEclPool;
        ethVolumeOfDaiPool += amountsToReceive.ethFromDaiPool;

        emit LogSoftSellEcl(
            msg.sender,
            eclSold,
            amountsToReceive.ethFromEclPool.add(
                amountsToReceive.ethFromDaiPool
            ),
            amountsToReceive.daiFromDaiPool
        );

        _transfer(address(msg.sender), address(this), eclSold);
        _burn(address(this), eclToBurn);
        require(
            daiInterface.transfer(msg.sender, amountsToReceive.daiFromDaiPool),
            "DAI Transfer failed."
        );
        msg.sender.sendValue(
            amountsToReceive.ethFromEclPool.add(amountsToReceive.ethFromDaiPool)
        );

        assert(
            ethBalanceOfEclPool.add(ethBalanceOfDaiPoolLocal) ==
                address(this).balance
        );
        assert(eclBalanceOfEclPoolLocal == eclBalanceOfEclPool());
        assert(daiBalanceOfDaiPoolLocal == daiBalanceOfDaiPool());
        assert(ethBalanceOfDaiPoolLocal == ethBalanceOfDaiPool());
        assert(ethBalanceOfEclPool > 0);
        assert(ethBalanceOfDaiPool() > 0);
        assert(eclBalanceOfEclPool() > 0);
        assert(daiBalanceOfDaiPool() > 0);
    }

    /// @notice Enables a user to buy DAI with ETH from the DAI liquidity pool.
    /// @param minDaiToReceive The minimum amount of DAI the user is willing to receive.
    /// @param deadline Epoch time deadline that the transaction must complete before.
    function buyDai(uint256 minDaiToReceive, uint256 deadline)
        external
        payable
        nonReentrant
        requireLaunched
    {
        require(
            deadline >= block.timestamp,
            "Transaction deadline has elapsed."
        );
        require(msg.value > 0, "Value of ETH sent must be greater than zero.");

        uint256 ethBalanceOfDaiPoolLocal = ethBalanceOfDaiPool().sub(msg.value);
        uint256 daiBalanceOfDaiPoolLocal = daiBalanceOfDaiPool();
        uint256 daiToReceive = applyTransactionFee(
            calcBOut(
                ethBalanceOfDaiPoolLocal,
                daiBalanceOfDaiPoolLocal,
                msg.value
            )
        );
        uint256 ethTransferToEclPool = msg.value.mul(15).div(10000);

        require(
            daiToReceive >= minDaiToReceive,
            "Unable to send the minimum quantity of DAI to receive."
        );

        ethBalanceOfEclPool = ethBalanceOfEclPool.add(ethTransferToEclPool);
        ethBalanceOfDaiPoolLocal = ethBalanceOfDaiPoolLocal.add(msg.value).sub(
            ethTransferToEclPool
        );
        daiBalanceOfDaiPoolLocal = daiBalanceOfDaiPoolLocal.sub(daiToReceive);
        ethVolumeOfDaiPool += msg.value;

        emit LogBuyDai(msg.sender, msg.value, daiToReceive);

        require(
            daiInterface.transfer(address(msg.sender), daiToReceive),
            "DAI Transfer failed."
        );

        assert(ethBalanceOfDaiPoolLocal == ethBalanceOfDaiPool());
        assert(daiBalanceOfDaiPoolLocal == daiBalanceOfDaiPool());
        assert(ethBalanceOfEclPool > 0);
        assert(ethBalanceOfDaiPool() > 0);
        assert(eclBalanceOfEclPool() > 0);
        assert(daiBalanceOfDaiPool() > 0);
    }

    /// @notice Enables a user to sell DAI for ETH to the DAI liquidity pool.
    /// @param daiSold The amount of DAI the user is selling.
    /// @param minEthToReceive The minimum amount of ETH the user is willing to receive.
    /// @param deadline Epoch time deadline that the transaction must complete before.
    function sellDai(
        uint256 daiSold,
        uint256 minEthToReceive,
        uint256 deadline
    ) external nonReentrant requireLaunched {
        require(
            deadline >= block.timestamp,
            "Transaction deadline has elapsed."
        );
        require(daiSold > 0, "Value of DAI sold must be greater than zero.");
        require(
            daiSold <= daiInterface.balanceOf(address(msg.sender)),
            "DAI sold must be less than or equal to DAI balance."
        );
        require(
            daiSold <=
                daiInterface.allowance(address(msg.sender), address(this)),
            "DAI sold exceeds allowance."
        );

        uint256 ethBalanceOfDaiPoolLocal = ethBalanceOfDaiPool();
        uint256 daiBalanceOfDaiPoolLocal = daiBalanceOfDaiPool();
        uint256 ethToReceiveBeforeFee = calcBOut(
            daiBalanceOfDaiPoolLocal,
            ethBalanceOfDaiPoolLocal,
            daiSold
        );
        uint256 ethToReceive = applyTransactionFee(ethToReceiveBeforeFee);
        uint256 ethTransferToEclPool = ethToReceiveBeforeFee
            .sub(ethToReceive)
            .div(2);

        require(
            ethToReceive >= minEthToReceive,
            "Unable to send the minimum quantity of ETH to receive."
        );

        ethBalanceOfEclPool = ethBalanceOfEclPool.add(ethTransferToEclPool);
        ethBalanceOfDaiPoolLocal = ethBalanceOfDaiPoolLocal
            .sub(ethToReceive)
            .sub(ethTransferToEclPool);
        daiBalanceOfDaiPoolLocal = daiBalanceOfDaiPoolLocal.add(daiSold);
        ethVolumeOfDaiPool += ethToReceive;

        emit LogSellDai(msg.sender, daiSold, ethToReceive);

        require(
            daiInterface.transferFrom(
                address(msg.sender),
                address(this),
                daiSold
            ),
            "DAI Transfer failed."
        );
        msg.sender.sendValue(ethToReceive);

        assert(ethBalanceOfDaiPoolLocal == ethBalanceOfDaiPool());
        assert(daiBalanceOfDaiPoolLocal == daiBalanceOfDaiPool());
        assert(ethBalanceOfEclPool > 0);
        assert(ethBalanceOfDaiPool() > 0);
        assert(eclBalanceOfEclPool() > 0);
        assert(daiBalanceOfDaiPool() > 0);
    }

    /// @notice Calculates amount of asset B for user to receive using constant product market maker algorithm.
    /// @dev A value of one is subtracted in the _bToReceive calculation such that rounding
    /// @dev errors favour the pool over the user.
    /// @param aBalance The balance of asset A in the liquidity pool.
    /// @param bBalance The balance of asset B in the liquidity pool.
    /// @param aSent The quantity of asset A sent by the user to the liquidity pool.
    /// @return bToReceive The quantity of asset B the user would receive before transaction fee is applied.
    function calcBOut(
        uint256 aBalance,
        uint256 bBalance,
        uint256 aSent
    ) public pure returns (uint256) {
        uint256 denominator = aBalance.add(aSent);
        uint256 fraction = aBalance.mul(bBalance).div(denominator);
        uint256 bToReceive = bBalance.sub(fraction).sub(1);

        assert(bToReceive < bBalance);

        return bToReceive;
    }

    /// @notice Calculates the amount of ETH to transfer from the ECL pool to the DAI pool for the buyEcl function.
    /// @param ethBalanceOfEclPoolLocal The balance of ETH in the ECL liquidity pool.
    /// @param ethBalanceOfDaiPoolLocal The balance of ETH in the DAI liquidity pool.
    /// @param ethSent The quantity of ETH sent by the user in the buyEcl function.
    /// @return ethTransferToDaiPool The quantity of ETH to transfer from the ECL pool to the DAI pool.
    function calcEthTransferForBuyEcl(
        uint256 ethBalanceOfEclPoolLocal,
        uint256 ethBalanceOfDaiPoolLocal,
        uint256 ethSent
    ) public pure returns (uint256) {
        uint256 ethTransferToDaiPool;

        if (
            ethBalanceOfEclPoolLocal >=
            ethSent.mul(4).div(6).add(ethBalanceOfDaiPoolLocal)
        ) {
            ethTransferToDaiPool = ethSent.mul(5).div(6);
        } else if (
            ethSent.add(ethBalanceOfEclPoolLocal) <= ethBalanceOfDaiPoolLocal
        ) {
            ethTransferToDaiPool = 0;
        } else {
            ethTransferToDaiPool = ethSent
                .add(ethBalanceOfEclPoolLocal)
                .sub(ethBalanceOfDaiPoolLocal)
                .div(2);
        }

        assert(ethTransferToDaiPool <= ethSent.mul(5).div(6));

        return ethTransferToDaiPool;
    }

    /// @notice Calculates the amount for the user to receive with a 0.3% transaction fee applied.
    /// @param amountBeforeFee The amount the user will receive before transaction fee is applied.
    /// @return amountAfterFee The amount the user will receive with transaction fee applied.
    function applyTransactionFee(uint256 amountBeforeFee)
        public
        pure
        returns (uint256)
    {
        uint256 amountAfterFee = amountBeforeFee.mul(997).div(1000);
        return amountAfterFee;
    }

    /// @notice Returns the ECL balance of the ECL pool.
    function eclBalanceOfEclPool()
        public
        view
        requireLaunched
        returns (uint256)
    {
        return balanceOf(address(this));
    }

    /// @notice Returns the ETH balance of the DAI pool.
    function ethBalanceOfDaiPool()
        public
        view
        requireLaunched
        returns (uint256)
    {
        return address(this).balance.sub(ethBalanceOfEclPool);
    }

    /// @notice Returns the DAI balance of the DAI pool.
    function daiBalanceOfDaiPool()
        public
        view
        requireLaunched
        returns (uint256)
    {
        return daiInterface.balanceOf(address(this));
    }

    /// @notice Returns the circulating supply of ECL.
    function circulatingSupply() public view requireLaunched returns (uint256) {
        return totalSupply().sub(eclBalanceOfEclPool());
    }
}