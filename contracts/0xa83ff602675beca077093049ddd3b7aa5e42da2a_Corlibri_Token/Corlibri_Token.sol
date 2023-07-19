/**
 *Submitted for verification at Etherscan.io on 2020-11-21
*/

// File: contracts/Corlibri_Libraries.sol

// SPDX-License-Identifier: WHO GIVES A FUCK ANYWAY??

pragma solidity ^0.6.6;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

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

    event Log(string log);

}

// File: contracts/Corlibri_Interfaces.sol



pragma solidity ^0.6.6;

//CORLIBRI
    interface ICorlibri {
        function viewGovernanceLevel(address _address) external view returns(uint8);
        function viewVault() external view returns(address);
        function viewUNIv2() external view returns(address);
        function viewWrappedUNIv2()external view returns(address);
        function burnFromUni(uint256 _amount) external;
    }

//Nectar is wrapping Tokens, generates wrappped UNIv2
    interface INectar {
        function wrapUNIv2(uint256 amount) external;
        function wTransfer(address recipient, uint256 amount) external;
        function setPublicWrappingRatio(uint256 _ratioBase100) external;
    }
    
//VAULT
    interface IVault {
        function updateRewards() external;
    }


//UNISWAP
    interface IUniswapV2Factory {
        event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    
        function feeTo() external view returns (address);
        function feeToSetter() external view returns (address);
        function migrator() external view returns (address);
    
        function getPair(address tokenA, address tokenB) external view returns (address pair);
        function allPairs(uint) external view returns (address pair);
        function allPairsLength() external view returns (uint);
    
        function createPair(address tokenA, address tokenB) external returns (address pair);
    
        function setFeeTo(address) external;
        function setFeeToSetter(address) external;
        function setMigrator(address) external;
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
        ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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
            bool approveMax, uint8 v, bytes32 r, bytes32 s
        ) external returns (uint amountA, uint amountB);
        function removeLiquidityETHWithPermit(
            address token,
            uint liquidity,
            uint amountTokenMin,
            uint amountETHMin,
            address to,
            uint deadline,
            bool approveMax, uint8 v, bytes32 r, bytes32 s
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
        function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
            external
            payable
            returns (uint[] memory amounts);
        function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
            external
            returns (uint[] memory amounts);
        function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
            external
            returns (uint[] memory amounts);
        function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
            external
            payable
            returns (uint[] memory amounts);
    
        function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
        function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
        function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
        function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
        function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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
            bool approveMax, uint8 v, bytes32 r, bytes32 s
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
    
        function DOMAIN_SEPARATOR() external view returns (bytes32);
        function PERMIT_TYPEHASH() external pure returns (bytes32);
        function nonces(address owner) external view returns (uint);
    
        function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    
        event Mint(address indexed sender, uint amount0, uint amount1);
        event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
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
        function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
        function price0CumulativeLast() external view returns (uint);
        function price1CumulativeLast() external view returns (uint);
        function kLast() external view returns (uint);
    
        function mint(address to) external returns (uint liquidity);
        function burn(address to) external returns (uint amount0, uint amount1);
        function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
        function skim(address to) external;
        function sync() external;
    
        function initialize(address, address) external;
    }
    interface IWETH {
        function deposit() external payable;
        function transfer(address to, uint value) external returns (bool);
        function withdraw(uint) external;
    }

// File: contracts/Corlibri_ERC20.sol



pragma solidity ^0.6.6;



contract ERC20 is Context, IERC20 { 
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

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

//Public Functions
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
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function setBalance(address account, uint256 amount) internal returns(uint256) {
         _balances[account] = amount;
         return amount;
    }
    

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


//Internal Functions
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }  //overriden in Defiat_Token

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
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: contracts/Corlibri_Token.sol


// but thanks a million Gwei to MIT and Zeppelin. You guys rock!!!

// MAINNET VERSION.

pragma solidity >=0.6.0;


contract Corlibri_Token is ERC20 {
    using SafeMath for uint256;
    using Address for address;

    event LiquidityAddition(address indexed dst, uint value);
    event LPTokenClaimed(address dst, uint value);

    //ERC20
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 public constant initialSupply = 25000*1e18; // 25k
    
    //timeStamps
    uint256 public contractInitialized;
    uint256 public contractStart_Timestamp;
    uint256 public LGECompleted_Timestamp;
    uint256 public constant contributionPhase =  7 days;
    uint256 public constant stackingPhase = 1 hours;
    uint256 public constant emergencyPeriod = 4 days;
    
    //Tokenomics
    uint256 public totalLPTokensMinted;
    uint256 public totalETHContributed;
    uint256 public LPperETHUnit;
    mapping (address => uint)  public ethContributed;
    uint256 public constant individualCap = 10*1e18; // 10 ETH cap per address for LGE
    uint256 public constant totalCap = 750*1e18; // 750 ETH cap total for LGE
    
    
    //Ecosystem
    address public UniswapPair;
    address public wUNIv2;
    address public Vault;
    IUniswapV2Router02 public uniswapRouterV2;
    IUniswapV2Factory public uniswapFactory;
    
//=========================================================================================================================================

    constructor() ERC20("Corlibri", "CORLIBRI") public {
        _mint(address(this), initialSupply - 1000*1e18); // initial token supply minus tokens for marketing/bonuses
        _mint(address(msg.sender), 1000*1e18); // 1000 tokens minted for marketing/bonus purposes
        governanceLevels[msg.sender] = 2;
    }
    
    function initialSetup() public governanceLevel(2) {
        contractInitialized = block.timestamp;
        setBuySellFees(25, 100); //2.5% on buy, 10% on sell.
        
        POOL_CreateUniswapPair(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D = UniswapV2Router02
        //0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f = UniswapV2Factory
    }
    
    //Pool UniSwap pair creation method (called by  initialSetup() )
    function POOL_CreateUniswapPair(address router, address factory) internal returns (address) {
        require(contractInitialized > 0, "Requires intialization 1st");
        
        uniswapRouterV2 = IUniswapV2Router02(router != address(0) ? router : 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapFactory = IUniswapV2Factory(factory != address(0) ? factory : 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); 
        require(UniswapPair == address(0), "Token: pool already created");
        
        UniswapPair = uniswapFactory.createPair(address(uniswapRouterV2.WETH()),address(this));
        
        return UniswapPair;
    }
    
    /* Once initialSetup has been invoked
    * Team will create the Vault and the LP wrapper token
    *  
    * Only AFTER these 2 addresses have been created the users
    * can start contributing in ETH
    */
    function secondarySetup(address _Vault, address _wUNIv2) public governanceLevel(2) {
        require(contractInitialized > 0 && contractStart_Timestamp == 0, "Requires Initialization and Start");
        setVault(_Vault); //also adds the Vault to noFeeList
        wUNIv2 = _wUNIv2;
        
        require(Vault != address(0) && wUNIv2 != address(0), "Wrapper Token and Vault not Setup");
        contractStart_Timestamp = block.timestamp;
    }
    

//=========================================================================================================================================
    /* Liquidity generation logic
    * Steps - All tokens that will ever exist go to this contract
    *  
    * This contract accepts ETH as payable
    * ETH is mapped to people
    *    
    * When liquidity generation event is over 
    * everyone can call the mint LP function.
    *    
    * which will put all the ETH and tokens inside the uniswap contract
    * without any involvement
    *    
    * This LP will go into this contract
    * And will be able to proportionally be withdrawn based on ETH put in
    *
    * emergency drain function allows the contract owner to drain all ETH and tokens from this contract
    * After the liquidity generation event happened. In case something goes wrong, to send ETH back
    */

    string public liquidityGenerationParticipationAgreement = "I agree that the developers and affiliated parties of the Corlibri team are not responsible for my funds";

    
    /* @dev List of modifiers used to differentiate the project phases
     *      ETH_ContributionPhase lets users send ETH to the token contract
     *      LGP_possible triggers after the contributionPhase duration
     *      Trading_Possible: this modifiers prevent Corlibri _transfer right
     *      after the LGE. It gives time for contributors to stake their 
     *      tokens before fees are generated.
     */
    
    modifier ETH_ContributionPhase() {
        require(contractStart_Timestamp > 0, "Requires contractTimestamp > 0");
        require(block.timestamp <= contractStart_Timestamp.add(contributionPhase), "Requires contributionPhase ongoing");
        _;
    }
    
    /* if totalETHContributed is bigger than 99% of the cap
     * the LGE can happen (allows the LGE to happen sooner if needed)
     * otherwise (ETHcontributed < 99% totalCap), time contraint applies
     */
    modifier LGE_Possible() {
         
        if(totalETHContributed < totalCap.mul(99).div(100)){ 
        require(contractStart_Timestamp > 0 , "Requires contractTimestamp > 0");
        require(block.timestamp > contractStart_Timestamp.add(contributionPhase), "Requies contributionPhase ended");
        }
       _; 
    }
    
    modifier LGE_happened() {
        require(LGECompleted_Timestamp > 0, "Requires LGE initialized");
        require(block.timestamp > LGECompleted_Timestamp, "Requires LGE ongoing");
        _;
    }
    
    //UniSwap Cuck Machine: Blocks Uniswap Trades for a certain period, allowing users to claim and stake NECTAR
    modifier Trading_Possible() {
         require(LGECompleted_Timestamp > 0, "Requires LGE initialized");
         require(block.timestamp > LGECompleted_Timestamp.add(stackingPhase), "Requires StackingPhase ended");
        _;
    }
    

//=========================================================================================================================================
  
    // Emergency drain in case of a bug
    function emergencyDrain24hAfterLiquidityGenerationEventIsDone() public governanceLevel(2) {
        require(contractStart_Timestamp > 0, "Requires contractTimestamp > 0");
        require(contractStart_Timestamp.add(emergencyPeriod) < block.timestamp, "Liquidity generation grace period still ongoing"); // About 24h after liquidity generation happens
        
        (bool success, ) = msg.sender.call{value:(address(this).balance)}("");
        require(success, "ETH Transfer failed... we are cucked");
       
        ERC20._transfer(address(this), msg.sender, balanceOf(address(this)));
    }

//During ETH_ContributionPhase: Users deposit funds

    //funds sent to TOKEN contract.
    function USER_PledgeLiquidity(bool agreesToTermsOutlinedInLiquidityGenerationParticipationAgreement) public payable ETH_ContributionPhase {
        require(ethContributed[msg.sender].add(msg.value) <= individualCap, "max 10ETH contribution per address");
        require(totalETHContributed.add(msg.value) <= totalCap, "750 ETH Hard cap"); 
        
        require(agreesToTermsOutlinedInLiquidityGenerationParticipationAgreement, "No agreement provided");
        
        ethContributed[msg.sender] = ethContributed[msg.sender].add(msg.value);
        totalETHContributed = totalETHContributed.add(msg.value); // for front end display during LGE
        emit LiquidityAddition(msg.sender, msg.value);
    }
    
    function USER_UNPledgeLiquidity() public ETH_ContributionPhase {
        uint256 _amount = ethContributed[msg.sender];
        ethContributed[msg.sender] = 0;
        msg.sender.transfer(_amount); //MUST CALL THE ETHERUM TRANSFER, not the TOKEN one!!!
        totalETHContributed = totalETHContributed.sub(_amount);
    }


// After ETH_ContributionPhase: Pool can create liquidity.
// Vault and wrapped UNIv2 contracts need to be setup in advance.

    function POOL_CreateLiquidity() public LGE_Possible {

        totalETHContributed = address(this).balance;
        IUniswapV2Pair pair = IUniswapV2Pair(UniswapPair);
        
        //Wrap eth
        address WETH = uniswapRouterV2.WETH();
        
        //Send to UniSwap
        IWETH(WETH).deposit{value : totalETHContributed}();
        require(address(this).balance == 0 , "Transfer Failed");
        IWETH(WETH).transfer(address(pair),totalETHContributed);
        
        emit Transfer(address(this), address(pair), balanceOf(address(this)));
        
        //Corlibri balances transfer
        ERC20._transfer(address(this), address(pair), balanceOf(address(this)));
        pair.mint(address(this));       //mint LP tokens. lock method in UniSwapPairV2 PREVENTS FROM DOING IT TWICE
        
        totalLPTokensMinted = pair.balanceOf(address(this));
        
        require(totalLPTokensMinted != 0 , "LP creation failed");
        LPperETHUnit = totalLPTokensMinted.mul(1e18).div(totalETHContributed); // 1e18x for  change
        require(LPperETHUnit != 0 , "LP creation failed");
        
        LGECompleted_Timestamp = block.timestamp;
    }
    
 
//After ETH_ContributionPhase: Pool can create liquidity.
    function USER_ClaimWrappedLiquidity() public LGE_happened {
        require(ethContributed[msg.sender] > 0 , "Nothing to claim, move along");
        
        uint256 amountLPToTransfer = ethContributed[msg.sender].mul(LPperETHUnit).div(1e18);
        INectar(wUNIv2).wTransfer(msg.sender, amountLPToTransfer); // stored as 1e18x value for change
        ethContributed[msg.sender] = 0;
        
        emit LPTokenClaimed(msg.sender, amountLPToTransfer);
    }


//=========================================================================================================================================
    //overriden _transfer to take Fees
    function _transfer(address sender, address recipient, uint256 amount) internal override Trading_Possible {
        
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
    
        //updates _balances
        setBalance(sender, balanceOf(sender).sub(amount, "ERC20: transfer amount exceeds balance"));

        //calculate net amounts and fee
        (uint256 toAmount, uint256 toFee) = calculateAmountAndFee(sender, amount);
        
        //Send Reward to Vault 1st
        if(toFee > 0 && Vault != address(0)){
            setBalance(Vault, balanceOf(Vault).add(toFee));
            IVault(Vault).updateRewards(); //updating the vault with rewards sent.
            emit Transfer(sender, Vault, toFee);
        }
        
        //transfer to recipient
        setBalance(recipient, balanceOf(recipient).add(toAmount));
        emit Transfer(sender, recipient, toAmount);

    }
    
//=========================================================================================================================================
//FEE_APPROVER (now included into the token code)

    mapping (address => bool) public noFeeList;
    
    function calculateAmountAndFee(address sender, uint256 amount) public view returns (uint256 netAmount, uint256 fee){

        if(noFeeList[sender]) { fee = 0;} // Don't have a fee when Vault is sending, or infinite loop
        else if(sender == UniswapPair){ fee = amount.mul(buyFee).div(1000);}
        else { fee = amount.mul(sellFee).div(1000);}
        
        netAmount = amount.sub(fee);
    }
    
//=========================================================================================================================================
//Governance
    /**
     * @dev multi tiered governance logic
     * 
     * 0: plebs
     * 1: voting contracts (setup later in DAO)
     * 2: governors
     * 
    */
    mapping(address => uint8) public governanceLevels;
    
    modifier governanceLevel(uint8 _level){
        require(governanceLevels[msg.sender] >= _level, "Grow some mustache kiddo...");
        _;
    }
    function setGovernanceLevel(address _address, uint8 _level) public governanceLevel(_level) {
        governanceLevels[_address] = _level; //_level in Modifier ensures that lvl1 can only add lvl1 govs.
    }
    
    function viewGovernanceLevel(address _address) public view returns(uint8) {
        return governanceLevels[_address];
    }

//== Governable Functions
    
    //External variables
        function setUniswapPair(address _UniswapPair) public governanceLevel(2) {
            UniswapPair = _UniswapPair;
            noFeeList[_UniswapPair] =  false; //making sure we take rewards
        }
        
        function setVault(address _Vault) public governanceLevel(2) {
            Vault = _Vault;
            noFeeList[_Vault] =  true;
        }
        
        
        /* @dev :allows to upgrade the wrapper
         * future devs will allow the wrapper to read live prices
         * of liquidity tokens and to mint an Universal wrapper
         * wrapping ANY UNIv2 LP token into their equivalent in 
         * wrappedLP tokens, based on the wrapped asset price.
         */
        function setwUNIv2(address _wrapper) public governanceLevel(2) {
            wUNIv2 = _wrapper;
            noFeeList[_wrapper] =  true; //manages the wrapping of Corlibris
        }
       
        //burns tokens from the contract (holding them)
        function burnToken(uint256 amount) public governanceLevel(1) {
            _burn(address(this), amount); //only Works if tokens are on the token contract. They need to be sent here 1st. (by the team Treasury)
        }
    
    //Fees
        uint256 public buyFee; uint256 public sellFee;
        function setBuySellFees(uint256 _buyFee, uint256 _sellFee) public governanceLevel(1) {
            buyFee = _buyFee;  //base 1000 -> 1 = 0.1%
            sellFee = _sellFee;
        }
        
        function setNoFeeList(address _address, bool _bool) public governanceLevel(1) {
          noFeeList[_address] =  _bool;
        }
    
    //wrapper contract
    function setPublicWrappingRatio(uint256 _ratioBase100) public governanceLevel(1) {
          INectar(wUNIv2).setPublicWrappingRatio(_ratioBase100);
        }
//==Getters 

        function viewUNIv2() public view returns(address){
            return UniswapPair;
        }
        function viewWrappedUNIv2() public view returns(address){
            return wUNIv2;
        }
        function viewVault() public view returns(address){
            return Vault;
        }

//=experimental
        uint256 private uniBurnRatio;
        function setUniBurnRatio(uint256 _ratioBase100) public governanceLevel(1) {
        require(_ratioBase100 <= 100);  
        uniBurnRatio = _ratioBase100;
        }
        
        function viewUniBurnRatio() public view returns(uint256) {
            return uniBurnRatio;
        }
            
        function burnFromUni(uint256 _amount) external {
            require(msg.sender == Vault); //only Vault can trigger this function
            
            //   _amount / NECTAR total supply, 1e18 format.
            uint256 amountRatio = _amount.mul(1e18).div(IERC20(wUNIv2).totalSupply()); //amount in % of the NECTAR supply
            
            //apply amountRatio to the UniSwpaPair balance
            uint256 amount = amountRatio.mul(balanceOf(UniswapPair)).div(1e18).mul(uniBurnRatio).div(100); //% times UNIv2 balances or Corlibri times uniBurnRatio
            
            
            if(amount > 0 && uniBurnRatio > 0){
                _burn(UniswapPair, amount);
                IUniswapV2Pair(UniswapPair).sync();
            }
        }
        
}