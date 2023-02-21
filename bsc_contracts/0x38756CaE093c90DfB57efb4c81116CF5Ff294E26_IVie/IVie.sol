/**
 *Submitted for verification at BscScan.com on 2023-02-20
*/

/**
 * Website : https://www.ivietoken.com
 * Telegram : https://t.me/ivietoken
 *
 * iVie : iVie
 * Symbol : IVIE
 * Total Supply : 1 B IVIE
*/

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IERC20 {

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract OwnableIVie is Ownable {
    bool public walletUpdateRenounced = false;
    address private _lockedLiquidity;
    address payable private _compagny;
    address payable private _project;
    address payable private _walletDev;
    address payable private _reserve;
    address private _icoContract;
    address private _burnAddress = address(0x000000000000000000000000000000000000dEaD);

    function lockedLiquidity() public view returns (address) {
        return _lockedLiquidity;
    }

    function compagny() public view returns (address payable) {
        return _compagny;
    }

    function project() public view returns (address payable) {
        return _project;
    }

    function walletDev() public view returns (address payable) {
        return _walletDev;
    }

    function reserve() public view returns (address payable) {
        return _reserve;
    }

    function icoContract() public view returns (address) {
        return _icoContract;
    }

    function burn() public view returns (address) {
        return _burnAddress;
    }

    modifier onlyCompagny() {
        require(_compagny == _msgSender(), "Caller is not the Compagny address");
        _;
    }

    modifier onlyProject() {
        require(_project == _msgSender(), "Caller is not the Project address");
        _;
    }

    modifier onlyWalletDev() {
        require(_walletDev == _msgSender(), "Caller is not the WalletDev address");
        _;
    }

    modifier onlyICOContract() {
        require(_icoContract == _msgSender(), "Caller is not the ICO contract");
        _;
    }

    function renounceWalletUpdate() public onlyOwner() {
        walletUpdateRenounced = true;
    }

    function setLockedLiquidityAddress(address liquidityAddress) public virtual onlyOwner {
        require(walletUpdateRenounced == false, "Locked Liquidity address cannot be changed anymore");
        _lockedLiquidity = liquidityAddress;
    }

    function setCompagnyAddress(address payable compagnyAddress) public virtual onlyOwner {
        require(walletUpdateRenounced == false, "Compagny address cannot be changed anymore");
        _compagny = compagnyAddress;
    }

    function setProjectAddress(address payable projectAddress) public virtual onlyOwner {
        _project = projectAddress;
    }

    function setWalletDevAddress(address payable walletDevAddress) public virtual onlyOwner {
        require(_walletDev == address(0), "WalletDev address cannot be changed once set");
        _walletDev = walletDevAddress;
    }

    function setReserveAddress(address payable reserveAddress) public virtual onlyOwner {
        _reserve = reserveAddress;
    }

    function setICOContractAddress(address icoContractAddress) public virtual onlyOwner {
        require(_icoContract == address(0), "ICO contract cannot be changed once set");
        _icoContract = icoContractAddress;
    }
}

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// pragma solidity >=0.5.0;

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

// pragma solidity >=0.6.2;

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

// pragma solidity >=0.6.2;

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

contract IVie is IERC20, OwnableIVie {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    mapping (address => bool) private _isInTransferWhitelist;
    address[] private _transferWhitelist;
    mapping (address => bool) private _isInTransferBlacklist;
    address[] private _transferBlacklist;
    bool public transferAllowanceRenounced = false;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1 * 10**9 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "iVie";
    string private _symbol = "IVIE";
    uint8 private _decimals = 9;

    // Holder Rewards
    uint256 private _taxFee = 0;
    uint256 private _previousTaxFee = _taxFee;

    // Pancake Liquidity
    uint256 private constant SWAP_LIQUIDITY_FEE = 1;

    // Project & Team fees
    uint256 private constant COMPAGNY_LIQUIDITY_FEE = 1;
    uint256 private constant PROJECT_LIQUIDITY_FEE = 1;
    uint256 private TOTAL_LIQUIDITY_FEE = SWAP_LIQUIDITY_FEE
        .add(COMPAGNY_LIQUIDITY_FEE)
        .add(PROJECT_LIQUIDITY_FEE);

    uint256 private _liquidityFee = TOTAL_LIQUIDITY_FEE;
    uint256 private _previousLiquidityFee = TOTAL_LIQUIDITY_FEE;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public uniRouterAddress;
    address public constant DEFAULT_PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;

    uint256 public _maxTxAmount = _tTotal;
    uint256 private numTokensSellToAddToLiquidity = _tTotal.div(2000);

    uint256 private _totalCompagnyCollected = 0;
    uint256 private _totalProjectCollected = 0;
    uint256 private _compagnyToCollectLater = 0;
    uint256 private _projectToCollectLater = 0;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 receivedBNB,
        uint256 tokensIntoLiqudity
    );

    event CompagnyCollected(uint256 collectedBNB);
    event ProjectCollected(uint256 collectedBNB);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (address deployer) {
        setICOContractAddress(deployer);
        _rOwned[deployer] = _rTotal;

        // Setup PancakeSwap
        configurePancakeSwapRouter(DEFAULT_PANCAKE_ROUTER);

        // Exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[burn()] = true;
        excludeFromReward(burn());

        emit Transfer(address(0), deployer, _tTotal);
    }

    function setPancakeSwapRouter(address _uniRouterAddress) public onlyOwner {
        uniRouterAddress = _uniRouterAddress;
        uniswapV2Router = IUniswapV2Router02(_uniRouterAddress);
    }

    function createPancakePair() public onlyOwner {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
    }

    function setPancakePair(address _uniswapV2Pair) public onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }

    function configurePancakeSwapRouter(address _uniRouterAddress) public onlyOwner {
        setPancakeSwapRouter(_uniRouterAddress);
        createPancakePair();
    }

    function initLiquidity(uint256 tokenAmount, uint256 amountBNB) public onlyICOContract {
        return addLiquidity(tokenAmount, amountBNB);
    }

    function initSwapAndLiquify() public onlyICOContract {
        swapAndLiquifyEnabled = true;
        emit SwapAndLiquifyEnabledUpdated(true);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function isInTransferWhitelist(address account) public view returns (bool) {
        if (_transferWhitelist.length > 0)
            return _isInTransferWhitelist[account];
        return true;
    }

    function isInTransferBlacklist(address account) public view returns (bool) {
        if (_transferBlacklist.length > 0)
            return _isInTransferBlacklist[account];
        return false;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function totalCompagnyCollected() public view returns (uint256) {
        return _totalCompagnyCollected;
    }

    function totalProjectCollected() public view returns (uint256) {
        return _totalProjectCollected;
    }

    function taxFee() public view returns (uint256) {
        return _taxFee;
    }

    function swapFee() public pure returns (uint256) {
        return SWAP_LIQUIDITY_FEE;
    }

    function compagnyFee() public pure returns (uint256) {
        return COMPAGNY_LIQUIDITY_FEE;
    }

    function projectFee() public pure returns (uint256) {
        return PROJECT_LIQUIDITY_FEE;
    }

    function getUniswapV2Pair() public view returns (address) {
        return uniswapV2Pair;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function renounceTransferAllowance() public onlyOwner() {
        transferAllowanceRenounced = true;
    }

    function transferWhitelistAdd(address account) public onlyOwner() {
        require(transferAllowanceRenounced == false, "Transfer allowance functions are disabled");
        require(!_isInTransferWhitelist[account], "Account is already in whitelist");
        _isInTransferWhitelist[account] = true;
        _transferWhitelist.push(account);
    }

    function transferWhitelistRemove(address account) public onlyOwner() {
        require(_isInTransferWhitelist[account], "Account is already removes from whitelist");
        for (uint256 i = 0; i < _transferWhitelist.length; i++) {
            if (_transferWhitelist[i] == account) {
                _transferWhitelist[i] = _transferWhitelist[_transferWhitelist.length - 1];
                _isInTransferWhitelist[account] = false;
                _transferWhitelist.pop();
                break;
            }
        }
    }

    function transferWhitelistRemoveICO() public onlyICOContract() {
        require(_isInTransferWhitelist[_msgSender()], "Account is already excluded");
        for (uint256 i = 0; i < _transferWhitelist.length; i++) {
            if (_transferWhitelist[i] == _msgSender()) {
                _transferWhitelist[i] = _transferWhitelist[_transferWhitelist.length - 1];
                _isInTransferWhitelist[_msgSender()] = false;
                _transferWhitelist.pop();
                break;
            }
        }
    }

    function transferBlacklistAdd(address account) public onlyOwner() {
        require(transferAllowanceRenounced == false, "Transfer allowance functions are disabled");
        require(!_isInTransferBlacklist[account], "Account is already in blacklist");
        _isInTransferBlacklist[account] = true;
        _transferBlacklist.push(account);
    }

    function transferBlacklistRemove(address account) public onlyOwner() {
        require(_isInTransferBlacklist[account], "Account is already removes from blacklist");
        for (uint256 i = 0; i < _transferBlacklist.length; i++) {
            if (_transferBlacklist[i] == account) {
                _transferBlacklist[i] = _transferBlacklist[_transferBlacklist.length - 1];
                _isInTransferBlacklist[account] = false;
                _transferBlacklist.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    // To recieve BNB from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        if (_transferWhitelist.length > 0)
            require(_isInTransferWhitelist[owner], "The account address cannot approve an amount.");

        if (_transferBlacklist.length > 0)
            require(_isInTransferBlacklist[owner] != true, "The account address cannot approve an amount.");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        if (_transferWhitelist.length > 0)
            require(_isInTransferWhitelist[from], "The account address cannot send tokens.");

        if (_transferBlacklist.length > 0)
            require(_isInTransferBlacklist[from] != true, "The account address cannot send tokens.");

        // Is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            // Add liquidity
            swapAndLiquify();
        }

        // Indicates if fee should be deducted from transfer
        bool takeFee = true;

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        // Transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    function collectCompagny() public onlyCompagny {
        _totalCompagnyCollected = _totalCompagnyCollected.add(_compagnyToCollectLater);
        emit CompagnyCollected(_compagnyToCollectLater);
        compagny().transfer(_compagnyToCollectLater);
        _compagnyToCollectLater = 0;
    }

    function compagnyToCollectLater() public view returns (uint256) {
        return _compagnyToCollectLater;
    }

    function collectProject() public onlyProject {
        _totalProjectCollected = _totalProjectCollected.add(_projectToCollectLater);
        emit ProjectCollected(_projectToCollectLater);
        project().transfer(_projectToCollectLater);
        _projectToCollectLater = 0;
    }

    function projectToCollectLater() public view returns (uint256) {
        return _projectToCollectLater;
    }

    function exedentBNB() public view returns (uint256) {
        return address(this).balance.sub(_compagnyToCollectLater).sub(_projectToCollectLater);
    }

    function emergencyExtract(address payable to, uint256 amountToExtract) external onlyOwner {
        require(amountToExtract <= exedentBNB(), "Nothing to extract");
        to.transfer(amountToExtract);
    }

    function swapAndLiquify() private lockTheSwap {
        // Split the contract balance into halves
        uint256 half = numTokensSellToAddToLiquidity.div(2);
        uint256 otherHalf = numTokensSellToAddToLiquidity.sub(half);

        // Capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        // this also ignores any BNB that was reserved for Compagny & Project last time
        // this was called
        uint256 initialBalance = address(this).balance;

        // Swap tokens for BNB
        swapTokensForBNB(half);

        // How much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);


        // Reserve some of that BNB for compagny to collect
        uint256 balanceToCompagny = newBalance.mul(COMPAGNY_LIQUIDITY_FEE).div(TOTAL_LIQUIDITY_FEE);
        uint256 tokensExtraCompagny = otherHalf.mul(COMPAGNY_LIQUIDITY_FEE).div(TOTAL_LIQUIDITY_FEE);
        _compagnyToCollectLater = _compagnyToCollectLater.add(balanceToCompagny);

        // And reserve some of that BNB for project to collect
        uint256 balanceToProject = newBalance.mul(PROJECT_LIQUIDITY_FEE).div(TOTAL_LIQUIDITY_FEE);
        uint256 tokensExtraProject = otherHalf.mul(PROJECT_LIQUIDITY_FEE).div(TOTAL_LIQUIDITY_FEE);
        _projectToCollectLater = _projectToCollectLater.add(balanceToProject);

        // How much BNB is left for liquidity?
        newBalance = newBalance.sub(balanceToCompagny).sub(balanceToProject);

        // How many tokens are left for liquidity?
        otherHalf = otherHalf.sub(tokensExtraCompagny).sub(tokensExtraProject);

        // Leftover tokens will be swapped into liquidity the next time this is called


        // Add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        // Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 amountBNB) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: amountBNB}(
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            lockedLiquidity(),
            block.timestamp
        );
    }

    // This method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if (!takeFee)
            removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}

contract IVieCrowdsale is Ownable {
    using SafeMath for uint256;
    using Address for address;

    IVie public _ivieToken;
    uint256 private _startTime = 0;
    uint256 private _startTimeSecond = 0;
    uint256 private _endTime = 0;
    uint256 public _tokensRaised = 0;
    uint256 public immutable TOKEN_FUNDING_GOAL_TOTAL;
    uint256 public immutable TOKEN_FUNDING_GOAL;
    uint256 public immutable TOKEN_FUNDING_GOAL_SECOND;
    uint256 public immutable PRESALE_RATIO;
    uint256 public immutable PRESALE_RATIO_SECOND;

    uint256 public constant BNB_DEC = 10 ** 18;

    uint256 public constant TTOTAL_PERCENT3_PRESALE = 1875;
    uint256 public constant TTOTAL_PERCENT3_PRESALE_SECOND = 48125;
    uint256 public constant TTOTAL_PERCENT_PROJECT = 10;
    uint256 public constant TTOTAL_PERCENT_LIQUIDITY = 40;

    uint256 public constant FUNDING_PERCENT_FOR_PANCAKE = 80;
    uint256 public constant FUNDING_PERCENT_FOR_PROJECT = 20;
    uint256 public constant PANKAKE_INIT_PRICE_RATIO = 130;

    uint256 public constant BNB_FUNDING_GOAL = BNB_DEC * 150;
    uint256 public constant BNB_FUNDING_GOAL_SECOND = BNB_DEC * 48125 / 10;
    uint256 public constant BNB_FUNDING_SOFT_CAP_SECOND = (BNB_FUNDING_GOAL * 10**2 / FUNDING_PERCENT_FOR_PROJECT) + (BNB_DEC * 100);

    uint256 public BNB_MIN_BUY = BNB_DEC * 5;
    uint256 public BNB_MAX_BUY = BNB_FUNDING_GOAL;
    uint256 public BNB_MIN_BUY_SECOND = BNB_DEC * 2 / 10;
    uint256 public BNB_MAX_BUY_SECOND = BNB_DEC * 10;

    uint256 public constant PRESALE_FEES_PERCENT = 2;
    uint256 public constant PRESALE_FEES_PERCENT3_SECOND = 500;
    uint256 public constant PRESALE_FEES_BNB_SECOND = BNB_DEC * 10;

    address[] public investors;
    mapping (address => uint256) public investorsBalances;
    address[] public participants;
    mapping (address => uint256) public balances;

    constructor () {
        // Create Token
        _ivieToken = new IVie(address(this));

        // LP tokens burned forever
        _ivieToken.setLockedLiquidityAddress(_ivieToken.burn());

        // Allow transfer only for ICO contract
        _ivieToken.transferWhitelistAdd(address(this));

        _ivieToken.excludeFromFee(_msgSender());
        _ivieToken.transferOwnership(_msgSender());

        // First Presale constants
        uint256 _tokenFundingGoal = _ivieToken.totalSupply().mul(TTOTAL_PERCENT3_PRESALE).div(10**5);
        TOKEN_FUNDING_GOAL = _tokenFundingGoal;
        PRESALE_RATIO = _tokenFundingGoal.mul(BNB_DEC).div(10**_ivieToken.decimals()).div(BNB_FUNDING_GOAL);

        // Second Presale constants
        uint256 _tokenFundingGoalSecond = _ivieToken.totalSupply().mul(TTOTAL_PERCENT3_PRESALE_SECOND).div(10**5);
        TOKEN_FUNDING_GOAL_SECOND = _tokenFundingGoalSecond;
        PRESALE_RATIO_SECOND = _tokenFundingGoalSecond.mul(BNB_DEC).div(10**_ivieToken.decimals()).div(BNB_FUNDING_GOAL_SECOND);

        TOKEN_FUNDING_GOAL_TOTAL = TOKEN_FUNDING_GOAL + TOKEN_FUNDING_GOAL_SECOND;
    }

    function startTime() public view returns (uint256) {
        return _startTime;
    }

    function startTimeSecond() public view returns (uint256) {
        return _startTimeSecond;
    }

    function endTime() public view returns (uint256) {
        return _endTime;
    }

    function _amountTokenForBNB(uint256 _amountBNB) private view returns (uint256) {
        uint256 _presaleRatio = PRESALE_RATIO;

        if (!isInPresale()) {
            _presaleRatio = PRESALE_RATIO_SECOND;
        }

        return (uint256) (_amountBNB.mul(_presaleRatio).mul(10**_ivieToken.decimals())).div(BNB_DEC);
    }

    function startPresale(uint256 startTimestamp) public onlyOwner() {
        _startTime = startTimestamp;
    }

    function startSecondPresale(uint256 startTimestamp, uint256 icoPeriodDays) public onlyOwner() {
        _startTimeSecond = startTimestamp;
        _endTime = _startTimeSecond.add(icoPeriodDays.mul(60).mul(60).mul(24));
    }

    function setMinMaxBuy(uint256 minBuy, uint256 maxBuy, uint256 minBuySecond, uint256 maxBuySecond) public onlyOwner() {
        BNB_MIN_BUY = minBuy;
        BNB_MAX_BUY = maxBuy;
        BNB_MIN_BUY_SECOND = minBuySecond;
        BNB_MAX_BUY_SECOND = maxBuySecond;
    }

    function isInPresale() public view returns (bool) {
        if (block.timestamp > _startTime && _tokensRaised < TOKEN_FUNDING_GOAL) {
            return true;
        }

        return false;
    }

    function isInSecondPresale() public view returns (bool) {
        if (block.timestamp > _startTimeSecond && _tokensRaised < TOKEN_FUNDING_GOAL_TOTAL && block.timestamp < _endTime) {
            return true;
        }

        return false;
    }

    function isSecondSoftCapCompleted() public view returns (bool) {
        return address(this).balance >= BNB_FUNDING_SOFT_CAP_SECOND;
    }

    function endPresale() public onlyOwner returns (bool) {
        require((block.timestamp > _endTime || _tokensRaised == TOKEN_FUNDING_GOAL_TOTAL), "Presale is not over yet");
        require(address(this).balance > 0, "Presale is completed");

        if (address(this).balance < BNB_FUNDING_SOFT_CAP_SECOND) { // Returns BNB to senders
            for (uint256 i = 0; i < participants.length; i++){
                if (balances[participants[i]] > 0){
                    payable(participants[i]).transfer(balances[participants[i]]);
                    balances[participants[i]] = 0;
                }
            }
        } else { // Otherwise, add liquidity to router
            // Allow transfer for all
            _ivieToken.transferWhitelistRemoveICO();

            uint256 _secondBNBRaised = address(this).balance;
            uint256 _totalBNBRaised = _secondBNBRaised + BNB_FUNDING_GOAL;

            // Transfer tokens to the project wallet
            uint256 _projectToken = _ivieToken.totalSupply().mul(TTOTAL_PERCENT_PROJECT).div(10**2);
            require(_ivieToken.transfer(_ivieToken.project(), _projectToken), 'Project tokens transfer failed');

            // Transfer BNB to the walletDev wallet
            uint256 _walletDevBNB = _secondBNBRaised.mul(PRESALE_FEES_PERCENT3_SECOND).div(10**5) + PRESALE_FEES_BNB_SECOND;
            payable(_ivieToken.walletDev()).transfer(_walletDevBNB);

            // Transfer BNB to the project wallet
            uint256 _projectBNB = (_totalBNBRaised.mul(FUNDING_PERCENT_FOR_PROJECT).div(10**2)) - BNB_FUNDING_GOAL - _walletDevBNB;
            payable(_ivieToken.project()).transfer(_projectBNB);

            // Create initial Pancake liquidity
            uint256 _pancakeLiquidityToken = _tokensRaised.mul(FUNDING_PERCENT_FOR_PANCAKE).div(PANKAKE_INIT_PRICE_RATIO);
            uint256 _pancakeLiquidityBNB = _totalBNBRaised.mul(FUNDING_PERCENT_FOR_PANCAKE).div(10**2);
            // Transfer tokens and BNB to the ivieToken contract, then call initLiquidity
            require(_ivieToken.transfer(address(_ivieToken), _pancakeLiquidityToken), 'Pancake liquidity tokens transfer failed');
            payable(_ivieToken).transfer(_pancakeLiquidityBNB);
            _ivieToken.initLiquidity(_pancakeLiquidityToken, _pancakeLiquidityBNB);

            // Send remaining liquidity tokens to locked reserve wallet
            uint256 _remainingLiquidityTokens = (_ivieToken.totalSupply().mul(TTOTAL_PERCENT_LIQUIDITY).div(10**2)).sub(_pancakeLiquidityToken);
            require(_ivieToken.transfer(_ivieToken.reserve(), _remainingLiquidityTokens), 'Remaining liquidity tokens transfer failed');
            // Send remaining liquidity BNB to locked reserve wallet
            uint256 _remainingLiquidityBNB = address(this).balance;
            payable(_ivieToken.reserve()).transfer(_remainingLiquidityBNB);

            // Burn remaining tokens (Remaining tokens of presale)
            require(_ivieToken.transfer(_ivieToken.burn(), _ivieToken.balanceOf(address(this))), 'Burn tokens transfer failed');

            // Enable SwapAndLiquify for future transfer
            _ivieToken.initSwapAndLiquify();
        }

        return true;
    }

    // Participans can withdraw their balance in case of unpredictable events 1 day after presale ends.
    function withdraw() external {
        address payable sender = payable(_msgSender());
        require(address(this).balance > 0, "Nothing to withdraw");
        require(block.timestamp >= _endTime + 60*60*24, "Function not available at this moment");
        require(balances[sender] > 0, "Cannot withdraw zero balance");
        sender.transfer(balances[sender]);
        balances[sender] = 0;
    }

    function numTokenToBuy(uint256 _sendedBNB) public view returns (uint256 _tokensToBuy, uint256 _usedBNB, uint256 _exceedingBNB) {
        require(isInPresale() || isInSecondPresale(), "Presale is not open");

        _usedBNB = _sendedBNB;

        uint256 _tokenGoal = TOKEN_FUNDING_GOAL;
        uint256 _presaleRatio = PRESALE_RATIO;
        uint256 _bnbMinBuy = BNB_MIN_BUY;
        uint256 _bnbMaxBuy = BNB_MAX_BUY;

        if (!isInPresale()) {
            _tokenGoal = TOKEN_FUNDING_GOAL_TOTAL;
            _presaleRatio = PRESALE_RATIO_SECOND;
            _bnbMinBuy = BNB_MIN_BUY_SECOND;
            _bnbMaxBuy = BNB_MAX_BUY_SECOND;
        }

        if (_sendedBNB < _bnbMinBuy) {
            _usedBNB = 0;
        }
        if (_sendedBNB > _bnbMaxBuy) {
            _usedBNB = _bnbMaxBuy;
        }

        _tokensToBuy = _amountTokenForBNB(_usedBNB);
        _exceedingBNB = 0;

        // Check if we have reached and exceeded the funding goal to refund the exceeding BNB
        if (_tokensRaised.add(_tokensToBuy) > _tokenGoal) {
            uint256 _exceedingTokens = _tokensRaised.add(_tokensToBuy).sub(_tokenGoal);
            // Change the tokens to buy to the new number
            _tokensToBuy = _tokensToBuy.sub(_exceedingTokens);
            // Update the counter of BNB used
            _usedBNB = (_tokensToBuy.mul(BNB_DEC)).div(_presaleRatio).div(10**_ivieToken.decimals());
        }
        // Calculate the number of BNB to refund
        _exceedingBNB = _sendedBNB.sub(_usedBNB);
    }

    receive() payable external {
        require(isInPresale() || isInSecondPresale(), "Presale is not open");

        (uint256 _tokensToBuy, uint256 _usedBNB, uint256 _exceedingBNB) = numTokenToBuy(msg.value);

        // Check if we have reached and exceeded the funding goal to refund the exceeding BNB
        if (_exceedingBNB > 0) {
            payable(_msgSender()).transfer(_exceedingBNB);
        }

        if (isInPresale()) {
            // Add new investor
            if (investorsBalances[_msgSender()] == 0) {
                investors.push(_msgSender());
            }

            // Save the BNB amount deposited
            investorsBalances[_msgSender()] = investorsBalances[_msgSender()].add(_usedBNB);

            // Transfer investors used BNB
            if (_usedBNB > 0) {
                uint256 _fees = _usedBNB.mul(PRESALE_FEES_PERCENT).div(10**2);
                uint256 _remaining = _usedBNB - _fees;
                payable(_ivieToken.walletDev()).transfer(_fees);
                payable(_ivieToken.project()).transfer(_remaining);
            }

        } else {
            // Add new participant
            if (balances[_msgSender()] == 0) {
                participants.push(_msgSender());
            }

            // Save the BNB amount deposited
            balances[_msgSender()] = balances[_msgSender()].add(_usedBNB);
        }

        // Send the IVIE
        if (_tokensToBuy > 0) {
            _ivieToken.transfer(_msgSender(), _tokensToBuy);
        }

        // Increase the tokens raised
        _tokensRaised = _tokensRaised.add(_tokensToBuy);
    }
}