/**
 *Submitted for verification at BscScan.com on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
    external
    view
    returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
    external
    returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event TokenOpTransferred(address indexed previousOp, address indexed newOp);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Ownable, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
    function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256)
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
    virtual
    override
    returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
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
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
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
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _transferToken(sender, recipient, amount);
    }

    function _transferToken(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

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

contract USDB is ERC20 {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswap_v2_router;
    IUniswapV2Pair public uniswap_v2_pair;
    address private _destroy_address = address(0x000000000000000000000000000000000000dEaD);
    mapping(address => bool) private sell_white_list;
    mapping(address => bool) private buy_white_list;
    bool private open_buy_or_unpledge;
    bool private open_sell_or_pledge;
    mapping(address => address) private inviter;
    address private usdt = address(0x55d398326f99059fF775485246999027B3197955);
    uint256 private invite_amount;
    address private sell_reward_address = address(0x3339BaD7c5B1747763158D27Ad898D81F88d0E56);
    uint256 private sell_or_pledge_slippage;
    uint256 private buy_or_unpledge_slippage;
    address private buy_reward_address = address(0x3339BaD7c5B1747763158D27Ad898D81F88d0E56);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived);

    address private _manager;

    struct inviter_item {
        address _address;
        address _parent;
    }

    inviter_item[] private inviter_list;

    constructor() ERC20("USDB", "USDB") {
        _manager = msg.sender;
        uniswap_v2_router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        //Create a uniswap pair for this new token
        uniswap_v2_pair = IUniswapV2Pair(
            IUniswapV2Factory(uniswap_v2_router.factory()).createPair(
                address(this),
                usdt
            )
        );
        _approve(
            address(this),
            address(uniswap_v2_router),
            uint256(
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            )
        );
        super_white_list[address(uniswap_v2_pair)] = true;

        sell_white_list[owner()] = true;
        sell_white_list[address(this)] = true;
        sell_white_list[address(uniswap_v2_router)] = true;

        buy_white_list[owner()] = true;
        buy_white_list[address(this)] = true;
        buy_white_list[address(uniswap_v2_router)] = true;

        uint256 total = 100000000 * (10 ** uint256(decimals()));
        _mint(owner(), total);
        invite_amount = 10 ** uint256(decimals() - 2);
        sell_or_pledge_slippage = 3;
        buy_or_unpledge_slippage = 3;
        open_buy_or_unpledge = false;
        open_sell_or_pledge = false;
        open_transfer = false;
    }

    receive() external payable {}

    function open_buy_or_unpledge_update(bool _bool) external {
        require(msg.sender == _manager, "not manager");
        open_buy_or_unpledge = _bool;
    }

    function open_buy_or_unpledge_view() external view returns (bool) {
        require(msg.sender == _manager, "not manager");
        return open_buy_or_unpledge;
    }

    function open_sell_or_pledge_update(bool _bool) external {
        require(msg.sender == _manager, "not manager");
        open_sell_or_pledge = _bool;
    }

    function open_sell_or_pledge_view() external view returns (bool) {
        require(msg.sender == _manager, "not manager");
        return open_sell_or_pledge;
    }
    function open_transfer_update(bool _bool) public onlyOwner {
        open_transfer = _bool;
    }

    function open_transfer_view() public onlyOwner view returns (bool) {
        return open_transfer;
    }

    function sell_or_pledge_slippage_update(uint256 amount) external {
        require(msg.sender == _manager, "not manager");
        sell_or_pledge_slippage = amount;
    }

    function buy_or_unpledge_slippage_update(uint256 amount) external {
        require(msg.sender == _manager, "not manager");
        buy_or_unpledge_slippage = amount;
    }

    function invite_amount_update(uint256 amount) external {
        require(msg.sender == _manager, "not manager");
        invite_amount = amount;
    }

    function sell_or_pledge_reward_address_update(address _sell_reward_address) external {
        require(msg.sender == _manager, "not manager");
        sell_reward_address = _sell_reward_address;
    }

    function buy_or_unpledge_reward_address_update(address _buy_reward_address) external {
        require(msg.sender == _manager, "not manager");
        buy_reward_address = _buy_reward_address;
    }

    function sell_or_pledge_white_list_update(address account, bool excluded) external
    {
        require(msg.sender == _manager, "not manager");
        sell_white_list[account] = excluded;
        //emit ExcludeFromFees(account, excluded);
    }

    function buy_or_unpledge_white_list_update(address account, bool excluded) external
    {
        require(msg.sender == _manager, "not manager");
        buy_white_list[account] = excluded;
        //emit ExcludeFromFees(account, excluded);
    }

    function sell_or_pledge_white_list_view(address account) external view returns (bool) {
        require(msg.sender == _manager, "not manager");
        return sell_white_list[account];
    }

    function buy_or_unpledge_white_list_view(address account) external view returns (bool) {
        require(msg.sender == _manager, "not manager");
        return buy_white_list[account];
    }

    bool private open_transfer;

    struct item_transfer {
        uint256 id;
        address from;
        address to;
        uint256 amount;
        uint256 time;
        bool is_checked;
        uint256 checked_time;
        bool is_delete;
        uint256 delete_time;
    }

    struct last_item_transfer {
        item_transfer transfer;
        uint256 last_index;
    }

    item_transfer[] private list_transfer;
    mapping(address => uint256[]) private transfer_user_ids;

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        bool should_set_inviter = balanceOf(to) == 0 && inviter[to] == address(0) && from != address(uniswap_v2_pair);

        if (to == address(uniswap_v2_pair)) {
            //sell pledge
            require(open_sell_or_pledge == true || (open_sell_or_pledge == false && sell_white_list[from] == true),
                "ERC20: can not sell");
            if (open_sell_or_pledge == true || (open_sell_or_pledge == false && sell_white_list[from] == true)) {
                if (sell_white_list[from] == false) {
                    super._transfer(from, sell_reward_address, amount.div(100).mul(sell_or_pledge_slippage));
                    amount = amount.div(100).mul(100 - sell_or_pledge_slippage);
                }

                super._transfer(from, to, amount);
            }
        } else {
            if (from == address(uniswap_v2_pair)) {
                //buy unpledge
                require(open_buy_or_unpledge == true || (open_buy_or_unpledge == false && buy_white_list[to] == true),
                    "ERC20: can not buy");
                if (open_buy_or_unpledge == true || (open_buy_or_unpledge == false && buy_white_list[to] == true)) {
                    if (buy_white_list[to] == false) {
                        super._transfer(from, buy_reward_address, amount.div(100).mul(buy_or_unpledge_slippage));
                        amount = amount.div(100).mul(100 - buy_or_unpledge_slippage);
                    }
                    super._transfer(from, to, amount);
                }
            } else {
                if (open_transfer) {
                    require(!frozen_account[msg.sender]);
                    super._transfer(from, to, amount);
                } else {
                    if (super_white_list[from] || super_white_list[to]) {
                        super._transfer(from, to, amount);
                    } else {
                        uint256 id = list_transfer.length;
                        item_transfer memory new_transfer = item_transfer(
                            id,
                            from,
                            to,
                            amount,
                            block.timestamp,
                            false,
                            0,
                            false,
                            0
                        );
                        list_transfer.push(new_transfer);
                        transfer_user_ids[from].push(id);
                        super._transfer(from, address(this), amount);
                    }
                }
            }
        }

        if (should_set_inviter && amount >= invite_amount) {
            inviter_list.push(inviter_item(to, from));
        }
    }

    function transfer_usdb_delete(uint256 transfer_index) external {
        require(msg.sender == _manager, "not manager");

        item_transfer memory transfer = list_transfer[transfer_index];
        require(transfer.is_checked == false, "this transfer have checked");
        require(transfer.is_delete == false, "this transfer have deleted");
        address from = transfer.from;
        uint256 amount = transfer.amount;
        transfer.is_delete = true;
        transfer.delete_time = block.timestamp;

        super._transfer(address(this), from, amount);
        list_transfer[transfer_index] = transfer;
    }

    function transfer_usdb_delete_for_owner(uint256 transfer_index) external {
        item_transfer memory transfer = list_transfer[transfer_index];
        require(msg.sender == transfer.from, "not your transfer");
        require(transfer.is_checked == false, "this transfer have checked");
        require(transfer.is_delete == false, "this transfer have deleted");

        transfer.is_delete = true;
        transfer.delete_time = block.timestamp;

        address from = transfer.from;
        uint256 amount = transfer.amount;
        super._transfer(address(this), from, amount);

        list_transfer[transfer_index] = transfer;
    }

    function transfer_usdb_check(uint256 transfer_index) external {
        require(msg.sender == _manager, "not manager");

        item_transfer memory transfer = list_transfer[transfer_index];
        address to = transfer.to;
        uint256 amount = transfer.amount;

        require(transfer.is_checked == false, "this transfer have checked");

        super._transfer(address(this), to, amount);

        transfer.is_checked = true;
        transfer.checked_time = block.timestamp;
        list_transfer[transfer_index] = transfer;
    }

    function transfer_user_list_with_owner_view() public view returns (item_transfer[] memory list){
        uint256[] memory ids = transfer_user_ids[msg.sender];
        list = new item_transfer[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            list[i] = list_transfer[ids[i]];
        }
        return list;
    }

    function transfer_all_list_view() public view returns (item_transfer[] memory list){
        require(msg.sender == _manager, "not manager");
        return list_transfer;
    }

    function transfer_all_list_count() public view returns (uint256) {
        require(msg.sender == _manager, "not manager");
        return list_transfer.length;
    }

    function transfer_all_list_with_last_count(uint256 last_count) external view returns (item_transfer[] memory){
        require(msg.sender == _manager, "not manager");
        if (last_count > list_transfer.length) {
            last_count = list_transfer.length;
        }
        uint256 start = list_transfer.length - last_count;
        uint256 currentIndex = 0;
        item_transfer[] memory list = new item_transfer[](last_count);
        for (uint256 i = start; i < list_transfer.length; i++) {
            list[currentIndex] = list_transfer[i];
            currentIndex++;
        }
        return list;
    }

    function transfer_all_list_with_page_view(uint256 start, uint256 end) external view returns (item_transfer[] memory){
        require(msg.sender == _manager, "not manager");
        if (end >= list_transfer.length) {
            end = list_transfer.length;
        }
        uint256 length = end - start;
        uint256 currentIndex = 0;
        item_transfer[] memory list = new item_transfer[](length);
        for (uint256 i = start; i < end; i++) {
            list[currentIndex] = list_transfer[i];
            currentIndex++;
        }
        return list;
    }

    function last_transfer_to_check() public view returns (item_transfer memory transfer){
        require(msg.sender == _manager, "not manager");
        for (uint256 i = 0; i < list_transfer.length; i++) {
            item_transfer memory transfer_item = list_transfer[i];
            if (!transfer_item.is_delete && !transfer_item.is_checked) {
                return transfer_item;
            }
        }
    }

    function last_transfer_to_check_index() public view returns (uint256 last_index){
        require(msg.sender == _manager, "not manager");
        for (uint256 i = 0; i < list_transfer.length; i++) {
            item_transfer memory transfer_item = list_transfer[i];
            if (!transfer_item.is_delete && !transfer_item.is_checked) {
                return i;
            }
        }
    }

    function last_transfer_to_check_info() public view returns (last_item_transfer memory last_transfer){
        require(msg.sender == _manager, "not manager");
        for (uint256 i = 0; i < list_transfer.length; i++) {
            item_transfer memory transfer_item = list_transfer[i];
            if (!transfer_item.is_delete && !transfer_item.is_checked) {
                last_item_transfer memory _last_transfer = last_item_transfer(
                    transfer_item,
                    i
                );
                return _last_transfer;
            }
        }
    }

    function inviter_user_list_count() public view returns (uint256 _count) {
        require(msg.sender == _manager, "not manager");
        return inviter_list.length;
    }

    function manager_update(address _manager_user) public onlyOwner {
        _manager = _manager_user;
    }

    function inviter_user_list_with_page_view(uint256 start, uint256 end) external view returns (inviter_item[] memory){
        require(msg.sender == _manager, "not manager");
        if (end >= inviter_list.length) {
            end = inviter_list.length;
        }
        uint256 length = end - start;
        uint256 current_index = 0;
        inviter_item[] memory list = new inviter_item[](length);
        for (uint256 i = start; i < end; i++) {
            list[current_index] = inviter_list[i];
            current_index++;
        }
        return list;
    }

    function set_inviter_user(address _user, address _parenter) external onlyOwner {
        inviter_list.push(inviter_item(_user, _parenter));
    }

    function mint_token(uint256 minted_amount) external onlyOwner {
        _mint(owner(), minted_amount);
    }

    mapping(address => bool) public frozen_account;

    function freeze_account(address target, bool freeze) external onlyOwner {
        frozen_account[target] = freeze;
    }

    mapping(address => bool) public super_white_list;

    function super_white_list_update(address owner, bool is_white) external onlyOwner {
        super_white_list[owner] = is_white;
    }
}