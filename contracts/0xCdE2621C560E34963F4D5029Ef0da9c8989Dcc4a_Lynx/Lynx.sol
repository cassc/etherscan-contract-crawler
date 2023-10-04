/**
 *Submitted for verification at Etherscan.io on 2023-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

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

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Cast(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

error LYNX__MaxWalletReached(address wallet, uint triedBalance);
error LYNX__Blacklisted();
error LYNX__InvalidThreshold();
error LYNX__TradingNotEnabled();
error LYNX__NotAllowed();
error LYNX__InvalidTaxAmount();
error LYNX__InvalidMaxWallet();

contract Lynx is Ownable, ERC20 {
    //---------------------------------------------------------------------------------
    // Structs
    //---------------------------------------------------------------------------------
    struct SnapshotInfo {
        uint tier1Total; // Tier 1 eligible balance
        uint tier2Total; // Tier 2 eligible balance
        uint snapshotTakenTimestamp; // Timestamp of the snapshot
    }
    //---------------------------------------------------------------------------------
    // State Variables
    //---------------------------------------------------------------------------------
    mapping(address user => mapping(uint snapId => uint amount))
        public snapshotInfo;
    mapping(address user => uint lastSnapshotId) public lastSnapshotId;
    mapping(uint snapId => SnapshotInfo) public snapshots;
    mapping(address wallet => bool excludedStatus) public isExcludedFromTax;
    mapping(address wallet => bool excludedStatus)
        public isExcludedFromMaxWallet;
    mapping(address wallet => bool blacklistedStatus) public isBlacklisted;
    mapping(address wallet => bool dividendExcepmtionStatus)
        public isDividendExempt;
    mapping(address lpAddress => bool) public isLpAddress;
    mapping(address executor => bool isExecutor) public isSnapshotter;

    uint private constant MAX_SUPPLY = 5_000_000 ether;
    uint private constant TIER_1 = 50_000 ether; // TIER 1 is top TIER
    uint private constant TIER_2 = 1_000 ether; // TIER 2 is middle TIER
    uint private constant TAX_PERCENT = 100;
    IUniswapV2Router02 public router;

    address public blacklister;
    address public mainPair;
    address private immutable WETH;
    address payable public immutable ADMIN_WALLET;
    uint public currentSnapId = 0;
    uint public taxThreshold;

    uint public maxWallet;
    uint public buyTax = 5;
    uint public sellTax = 5;

    bool private isSwapping = false;
    bool public tradingEnabled = false;

    //---------------------------------------------------------------------------------
    // Events
    //---------------------------------------------------------------------------------

    event WalletExcludedFromTax(address indexed _user, bool excluded);
    event WalletExcludedFromMax(address indexed _user, bool excluded);
    event BlacklistWalletUpdate(address indexed _user, bool blacklisted);
    event BlacklistWalletsUpdate(address[] _users, bool blacklisted);
    event SetAddressAsLp(address indexed _lpAddress, bool isLpAddress);
    event SnapshotTaken(uint indexed snapId, uint timestamp);
    event TradingEnabled(bool isEnabled);
    event UpdateBlacklister(address indexed _blacklister);
    event SetSnapshotterStatus(address indexed _snapshotter, bool status);
    event EditMaxWalletAmount(uint newAmount);
    event EditTax(uint newTax, bool buyTax, bool sellTax);

    //---------------------------------------------------------------------------------
    // Modifiers
    //---------------------------------------------------------------------------------
    modifier adminOrBlacklister() {
        if (msg.sender != owner() && msg.sender != blacklister)
            revert LYNX__NotAllowed();
        _;
    }

    modifier onlySnapshotter() {
        if (!isSnapshotter[msg.sender]) revert LYNX__NotAllowed();
        _;
    }

    //---------------------------------------------------------------------------------
    // Constructor
    //---------------------------------------------------------------------------------
    constructor(address _admin, address _newOwner) ERC20("LYNX", "LYNX") {
        _transferOwnership(_newOwner);
        blacklister = 0x89a022f3983Fa81Ae5B02b5A7d471AB1AC0BcC64;
        _mint(_newOwner, MAX_SUPPLY);

        maxWallet = (MAX_SUPPLY * 1_5) / 100_0; // 1.5% of total supply
        taxThreshold = MAX_SUPPLY / 100_00; // 0.01% of total supply

        // Ethereum Mainnet UniswapV2 Router
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        // Create the Pair for this token with WETH
        mainPair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            WETH
        );
        isLpAddress[mainPair] = true;

        isExcludedFromMaxWallet[address(this)] = true;
        isExcludedFromMaxWallet[owner()] = true;
        isExcludedFromMaxWallet[address(router)] = true;
        isExcludedFromMaxWallet[address(mainPair)] = true;

        isExcludedFromTax[owner()] = true;
        isExcludedFromTax[address(this)] = true;
        isExcludedFromTax[address(router)] = true;

        isDividendExempt[owner()] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(router)] = true;
        isDividendExempt[address(mainPair)] = true;

        isSnapshotter[owner()] = true;
        ADMIN_WALLET = payable(_admin);
        _approve(address(this), address(router), type(uint).max);
    }

    //---------------------------------------------------------------------------------
    // External & Public Functions
    //---------------------------------------------------------------------------------

    /**
     * Set wether an address is excluded from taxes or NOT.
     * @param _user User which status will be updated
     * @param _excluded The new excluded status. True is Excluded, False is NOT excluded
     */
    function setExcludeFromTax(
        address _user,
        bool _excluded
    ) external onlyOwner {
        isExcludedFromTax[_user] = _excluded;
        emit WalletExcludedFromTax(_user, _excluded);
    }

    /**
     * Exclude or include a wallet of MAX wallet limit (AntiWhale)
     * @param _user Address which status will be updated
     * @param _excluded The new excluded status. True is Excluded, False is NOT excluded
     */
    function setExcludedFromMaxWallet(
        address _user,
        bool _excluded
    ) external onlyOwner {
        isExcludedFromMaxWallet[_user] = _excluded;
        emit WalletExcludedFromMax(_user, _excluded);
    }

    /**
     * @notice Set the address as Blacklisted
     * @param _user Address which status will be updated
     */
    function blacklistAddress(address _user) external adminOrBlacklister {
        isBlacklisted[_user] = true;
        isDividendExempt[_user] = true;
        _updateSnapDecrease(_user, balanceOf(_user));
        emit BlacklistWalletUpdate(_user, true);
    }

    /**
     * @notice Set the addresses as Blacklisted
     * @param _users Addresses which status will be updated
     */
    function blacklistAddresses(
        address[] calldata _users
    ) external adminOrBlacklister {
        for (uint i = 0; i < _users.length; i++) {
            isBlacklisted[_users[i]] = true;
            isDividendExempt[_users[i]] = true;
            _updateSnapDecrease(_users[i], balanceOf(_users[i]));
        }
        emit BlacklistWalletsUpdate(_users, true);
    }

    /**
     * @notice Remove the address as Blacklisted
     * @param _user Addresses which status will be updated
     */
    function unblacklistAddress(address _user) external adminOrBlacklister {
        isBlacklisted[_user] = false;
        isDividendExempt[_user] = false;
        _updateSnapIncrease(_user, balanceOf(_user));
        emit BlacklistWalletUpdate(_user, false);
    }

    /**
     * @notice Remove the addresses as Blacklisted
     * @param _users Addresses which status will be updated
     */
    function unblacklistAddresses(
        address[] calldata _users
    ) external adminOrBlacklister {
        for (uint i = 0; i < _users.length; i++) {
            isBlacklisted[_users[i]] = false;
            isDividendExempt[_users[i]] = false;
            _updateSnapIncrease(_users[i], balanceOf(_users[i]));
        }
        emit BlacklistWalletsUpdate(_users, false);
    }

    /**
     * @notice Set an Address as LP
     * @param _lpAddress Address to set as LP
     * @param _isLpAddress enable or disable address as an LP
     */
    function setLpAddress(
        address _lpAddress,
        bool _isLpAddress
    ) external onlyOwner {
        isLpAddress[_lpAddress] = _isLpAddress;
        isDividendExempt[_lpAddress] = _isLpAddress;
        emit SetAddressAsLp(_lpAddress, _isLpAddress);
    }

    /**
     * @notice Create a snapshot of the current balances
     */
    function takeSnapshot() external onlySnapshotter {
        uint currentSnap = currentSnapId;
        currentSnapId++;

        SnapshotInfo storage snap = snapshots[currentSnap];
        snap.snapshotTakenTimestamp = block.timestamp;
        // roll over total amounts
        snapshots[currentSnapId] = SnapshotInfo({
            tier1Total: snap.tier1Total,
            tier2Total: snap.tier2Total,
            snapshotTakenTimestamp: 0
        });

        emit SnapshotTaken(currentSnap, block.timestamp);
    }

    /**
     * @notice Set the new Tax swap threshold
     * @param _taxThreshold New tax threshold
     */
    function setTaxThreshold(uint _taxThreshold) external onlyOwner {
        if (_taxThreshold > MAX_SUPPLY) revert LYNX__InvalidThreshold();
        taxThreshold = _taxThreshold;
    }

    function setMaxWallet(uint _maxWallet) external onlyOwner {
        if (_maxWallet < MAX_SUPPLY / 100_00) revert LYNX__InvalidMaxWallet();
        maxWallet = _maxWallet;
        emit EditMaxWalletAmount(_maxWallet);
    }

    /**
     * @notice set trading as enabled
     */
    function enableTrading() external onlyOwner {
        tradingEnabled = true;
        emit TradingEnabled(true);
    }

    /**
     * @notice set trading as disabled
     */
    function pauseTrading() external onlyOwner {
        tradingEnabled = false;
        emit TradingEnabled(false);
    }

    /**
     * @notice Update the blacklister address
     * @param _blacklister New blacklister address
     */
    function setBlacklister(address _blacklister) external onlyOwner {
        blacklister = _blacklister;
        emit UpdateBlacklister(_blacklister);
    }

    /**
     * @notice Set the Snapshotter status to an address. These addresses can take snapshots at any time
     * @param _snapshotter Address to set snapshotter status
     * @param _isSnapshotter True to set as snapshotter, false to remove
     */
    function setSnapshotterAddress(
        address _snapshotter,
        bool _isSnapshotter
    ) external onlyOwner {
        isSnapshotter[_snapshotter] = _isSnapshotter;
        emit SetSnapshotterStatus(_snapshotter, _isSnapshotter);
    }

    /**
     * @notice set the Buy tax to a new value
     * @param _buyTax New buy tax
     * @dev buyTax is a maximimum of 10% so the max acceptable _buyTax is 10
     */
    function setBuyTax(uint _buyTax) external onlyOwner {
        if (_buyTax > 10) revert LYNX__InvalidTaxAmount();
        buyTax = _buyTax;
        emit EditTax(_buyTax, true, false);
    }

    /**
     * @notice set the Sell tax to a new value
     * @param _sellTax New sell tax
     * @dev sellTax is a maximimum of 10% so the max acceptable _sellTax is 10
     */
    function setSellTax(uint _sellTax) external onlyOwner {
        if (_sellTax > 10) revert LYNX__InvalidTaxAmount();
        sellTax = _sellTax;
        emit EditTax(_sellTax, false, true);
    }

    //---------------------------------------------------------------------------------
    // Internal & Private Functions
    //---------------------------------------------------------------------------------

    /**
     * @notice Underlying transfer of tokens used by `transfer` and `transferFrom` in ERC20 which are public
     * @param from Address that holds the funds
     * @param to Address that receives the funds
     * @param amount Amount of funds to send
     */
    function _transfer(
        address from,
        address to,
        uint amount
    ) internal override {
        if (isBlacklisted[from] || isBlacklisted[to])
            revert LYNX__Blacklisted();

        bool taxExclusion = isExcludedFromTax[from] || isExcludedFromTax[to];

        if (!tradingEnabled && !taxExclusion) {
            revert LYNX__TradingNotEnabled();
        }

        _updateSnapDecrease(from, amount);

        uint currentBalance = balanceOf(address(this));

        if (
            !isSwapping &&
            currentBalance >= taxThreshold &&
            !taxExclusion &&
            !isLpAddress[from] // Cant do this on buys
        ) {
            _swapTokens();
        }

        // Check that sender is free of tax or receiver is free of tax
        if (!taxExclusion) {
            uint tax;
            // if not free of tax, check if is buy or sell
            if (isLpAddress[to]) {
                // IS SELL
                tax = (amount * sellTax) / TAX_PERCENT;
            } else if (isLpAddress[from]) {
                // IS BUY
                tax = (amount * buyTax) / TAX_PERCENT;
            }
            if (tax > 0) {
                super._transfer(from, address(this), tax);
                amount -= tax;
            }
        }

        // check if receiver is free of max wallet
        uint toNEWBalance = balanceOf(to) + amount;
        if (!isExcludedFromMaxWallet[to] && toNEWBalance > maxWallet) {
            revert LYNX__MaxWalletReached(to, toNEWBalance);
        }
        _updateSnapIncrease(to, amount);
        super._transfer(from, to, amount);
    }

    /**
     * @notice Swap any tokens the contract has for ETH and send the ETH directly to the Admin Wallet
     */
    function _swapTokens() private {
        isSwapping = true;
        // Get the current amount of tokens stored in the contract
        uint256 contractTokenBalance = balanceOf(address(this));
        // If the contract has tokens
        if (contractTokenBalance > 0) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = WETH;
            // Swap all for ETH and send to Admin Wallet
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                contractTokenBalance,
                0, // Accept any amount of ETH
                path,
                ADMIN_WALLET,
                block.timestamp
            );
        }
        isSwapping = false;
    }

    /**
     * @notice Decrease a wallet's current snapshot balance
     * @param user Wallet to update snapshot info
     * @param amount the difference amount in snapshot
     */
    function _updateSnapDecrease(address user, uint amount) private {
        uint currentSnap = currentSnapId;
        uint currentSnapBalance = snapshotInfo[user][currentSnap];
        uint currentBalance = balanceOf(user);
        uint newBalance = currentBalance - amount;
        SnapshotInfo storage snap = snapshots[currentSnap];
        lastSnapshotId[user] = currentSnap;
        // If user is exempt from dividends, we need to set the snapshot value to 0
        if (isDividendExempt[user]) {
            snapshotInfo[user][currentSnap] = 0;
            // if user is now exempt but used to have funds, we need to decrease the total
            if (currentSnapBalance > 0) {
                if (currentSnapBalance >= TIER_1)
                    snap.tier1Total -= currentSnapBalance;
                else if (currentSnapBalance >= TIER_2)
                    snap.tier2Total -= currentSnapBalance;
            }
        } else {
            snapshotInfo[user][currentSnap] = newBalance;

            /// FROM TIER 1
            if (currentBalance >= TIER_1) {
                // Decrease TIER 1
                snap.tier1Total -= currentBalance;
                // TO SAME TIER
                if (newBalance >= TIER_1) snap.tier1Total += newBalance;
                // TO TIER 2
                if (newBalance < TIER_1 && newBalance >= TIER_2)
                    snap.tier2Total += newBalance;
                // if to NO tier, just decrease is fine
            }
            // FROM TIER 2
            else if (currentBalance >= TIER_2) {
                snap.tier2Total -= currentBalance;
                // TO SAME TIER
                if (newBalance >= TIER_2) snap.tier2Total += newBalance;
                // TO NO TIER JUST DO NOTHING
            }
        }
    }

    /**
     * @notice Increase a wallet's current snapshot balance
     * @param user Wallet to update snapshot info
     * @param amount Difference amount
     */
    function _updateSnapIncrease(address user, uint amount) private {
        uint currentSnap = currentSnapId;
        uint currentBalance = balanceOf(user);
        uint currentSnapBalance = snapshotInfo[user][currentSnap];
        SnapshotInfo storage snap = snapshots[currentSnap];
        lastSnapshotId[user] = currentSnap;
        // If user is exempt from dividends, we need to set the snapshot value to 0
        if (isDividendExempt[user]) {
            snapshotInfo[user][currentSnap] = 0;
            // if user is now exempt but used to have funds, we need to decrease the total
            if (currentSnapBalance > 0) {
                if (currentSnapBalance >= TIER_1)
                    snap.tier1Total -= currentSnapBalance;
                else if (currentSnapBalance >= TIER_2)
                    snap.tier2Total -= currentSnapBalance;
            }
        } else {
            snapshotInfo[user][currentSnap] = currentBalance + amount;
            uint newBalance = currentBalance + amount;
            // Check if there is any tier advancement

            // FROM NO TIER
            if (currentBalance < TIER_2) {
                // TO TIER 1
                if (newBalance >= TIER_1)
                    snap.tier1Total += newBalance;
                    // TO TIER 2
                else if (newBalance >= TIER_2) snap.tier2Total += newBalance;
                // TO NO TIER DO NOTHING
            }
            // FROM TIER 2
            else if (currentBalance >= TIER_2 && currentBalance < TIER_1) {
                // TO TIER 1
                if (newBalance >= TIER_1)
                    snap.tier1Total += newBalance;

                    // TO SAME TIER
                else if (newBalance >= TIER_2) snap.tier2Total += newBalance;
                snap.tier2Total -= currentBalance;
            }
            // FROM TIER 1
            else if (currentBalance >= TIER_1) {
                // Stay in same tier
                snap.tier1Total += newBalance;
                snap.tier1Total -= currentBalance;
            }
        }
    }

    //---------------------------------------------------------------------------------
    // External & Public VIEW | PURE Functions
    //---------------------------------------------------------------------------------

    function getUserSnapshotAt(
        address user,
        uint snapId
    ) external view returns (uint) {
        // If snapshot ID hasn't been taken, return 0
        if (snapId > currentSnapId) return 0;
        uint lastUserSnap = lastSnapshotId[user];
        // if last snapshot is before the requested snapshot, return current balance of the user
        if (snapId > lastUserSnap) return balanceOf(user);
        // else return the snapshot balance
        return snapshotInfo[user][snapId];
    }

    //---------------------------------------------------------------------------------
    // Internal & Private VIEW | PURE Functions
    //---------------------------------------------------------------------------------
}