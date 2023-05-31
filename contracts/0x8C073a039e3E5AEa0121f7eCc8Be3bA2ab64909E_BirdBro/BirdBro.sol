/**
 *Submitted for verification at Etherscan.io on 2023-05-30
*/

/**
Bird Bro (BRO)
Website: https://birdbro.io
Telegram Group: https://t.me/BirdBroToken
Telegram Channel: https://t.me/BirdBroNews
Twitter: https://twitter.com/BirdBroToken
*/

pragma solidity ^0.8.19;

// SPDX-License-Identifier: Unlicensed

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IBirdBro {
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
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

    /**
     * @dev Emits an event indicating the router and pair have been updated.
     * @param uniswapV2Router The address of the UniswapV2Router02 contract.
     * @param uniswapV2Pair The address of the UniswapV2Pair contract.
     */
    event RouterAndPairUpdated(
        address indexed uniswapV2Router,
        address indexed uniswapV2Pair
    );

    /**
     * @dev This function is called when a new bridge is added to the network.
     * @param bridge The address of the new bridge.
     */
    event BridgeUpdated(address bridge);

    event ManagerUpdated(address manager);

    event OperatorUpdated(address operator);

    event QuantityInPercentageForSaleUpdated(uint256 percentage);

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyContractCreator() {
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
     * `onlyContractCreator` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyContractCreator {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(
        address newOwner
    ) public virtual onlyContractCreator {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract BirdBro is Context, IBirdBro, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address private _burnWallet; // address 0x0, dead
    address private _deadWallet; // dead address
    address private _token; // address of the token contract
    mapping(address => bool) public _bridges; // address bridges
    mapping(address => bool) private _managers; // address managers
    mapping(address => bool) private _operators; // address operators
    mapping(address => uint256) private _maxTxAmountAddress; // mapping of address to max tx amount allowed for that address
    mapping(address => uint256) private _maxWalletAmountAddress; // mapping the address to the maximum amount of tokens in the wallet allowed for that address
    mapping(address => uint256) private _balances; // mapping of address to balance of that address
    mapping(address => mapping(address => uint256)) private _allowances; // mapping of address to mapping of address to allowance of that address to the spender.
    mapping(address => bool) private _isExcludedMaxTxAmount; // mapping of address to whether or not that address is excluded from max tx amount.
    mapping(address => bool) private _isExcludedMaxWalletAmount; // address mapping to whether or not that address is excluded from the maximum wallet amount.

    IUniswapV2Router02 public _uniswapRouter; // uniswap router contract.
    address public _uniswapPair; // uniswap pair contract.
    address public _WETH; // WETH token address.
    uint256 private _ethBalanceCheck;

    string private _name = "Bird Bro"; // name of the token
    string private _symbol = "BRO"; // symbol of the token
    uint8 private _decimals = 9; // number of decimals of the token
    uint256 private _totalSupply = 100_000_000 * 10 ** _decimals; // total supply of the token.

    uint256 private _maxTxAmountPercent = 10; // number for percentage 0.1%
    uint256 private _maxMaxWalltAmountPercent = 100; // number for percentage 1%
    uint256 private _maxTxAmount = ((_totalSupply * _maxTxAmountPercent) /
        10000); // minimum transfer limit of 0.1%
    uint256 private _maxWalletAmount = ((_totalSupply *
        _maxMaxWalltAmountPercent) / 10000); // minimum wallet amount 1%

    uint256 private _previousMaxTxAmount = _maxTxAmount;
    uint256 private _previousMaxWalletAmount = _maxWalletAmount;

    // mini role system
    modifier onlyBridge() {
        require(
            _bridges[msg.sender],
            "BirdBro: Only the Bridge contract can call this function"
        );
        _;
    }

    modifier onlyManager() {
        require(
            _managers[msg.sender],
            "BirdBro: Only the Manager contract can call this function"
        );
        _;
    }

    modifier onlyOperator() {
        require(
            _operators[msg.sender],
            "BirdBro: Only the Operator contract can call this function"
        );
        _;
    }

    /**
     * @dev to receive ETH from uniswapV2Router when swapping
     */
    receive() external payable {}

    constructor() {
        _token = address(this); // set the token address.
        _burnWallet = address(0);
        _deadWallet = address(0xdEaD);
        _balances[_msgSender()] = _totalSupply; // set the initial balance of the sender.

        // exclude from max tx
        _isExcludedMaxTxAmount[owner()] = true; // set the owner as excluded from max tx.
        _isExcludedMaxTxAmount[_token] = true; // set the token as excluded from max tx.
        _isExcludedMaxTxAmount[_deadWallet] = true; // set the address as excluded from max tx.
        _isExcludedMaxTxAmount[_burnWallet] = true; // set the null address as excluded from max tx.

        // exclude fro max wallet
        _isExcludedMaxWalletAmount[owner()] = true; // set the owner as excluded from max wallet.
        _isExcludedMaxWalletAmount[_token] = true; // set the token as excluded from max wallet.
        _isExcludedMaxWalletAmount[_deadWallet] = true; // set the address as excluded from max wallet.
        _isExcludedMaxWalletAmount[_burnWallet] = true; // set the null address as excluded from max wallet.

        emit Transfer(_burnWallet, _msgSender(), _totalSupply); // emit the transfer event.
    }

    /**
     * @dev Initializes the router and pair for the token.
     * @param _router The address of the router.
     */
    function initRouterAndPair(address _router) external onlyOperator {
        _uniswapRouter = IUniswapV2Router02(_router);
        _WETH = _uniswapRouter.WETH();
        // Create a uniswap pair for this new token
        _uniswapPair = IUniswapV2Factory(_uniswapRouter.factory()).createPair(
            address(this), // token address of the token being paired with WETH.
            _WETH // WETH is the WETH token of the router.
        );
    }

    /**
     * @dev Update the UniswapV2Router and UniswapV2Pair addresses.
     * @param _uniswapV2Router The address of the UniswapV2Router contract.
     * @param _uniswapV2Pair The address of the UniswapV2Pair contract.
     */
    function updateRouterAndPair(
        address _uniswapV2Router,
        address _uniswapV2Pair
    ) external onlyOperator {
        _uniswapRouter = IUniswapV2Router02(_uniswapV2Router); // Update the UniswapV2Router address.
        _uniswapPair = _uniswapV2Pair; // Update the UniswapV2Pair address.
        _WETH = _uniswapRouter.WETH(); // WETH is the WETH token address of the UniswapV2Router contract.

        emit RouterAndPairUpdated(_uniswapV2Router, _uniswapV2Pair);
    }

    function setBridgeAddress(
        address account,
        bool _isBridge
    ) external onlyOperator {
        require(account != _burnWallet, "BirdBro: address(0x0)"); // Check if the bridge address is valid.
        _bridges[account] = _isBridge;

        emit BridgeUpdated(account);
    }

    function setManagerAddress(
        address account,
        bool _isManager
    ) external onlyContractCreator {
        require(account != _burnWallet, "BirdBro: address(0x0)"); // Check if the manager address is valid.
        _managers[account] = _isManager;

        emit ManagerUpdated(account);
    }

    function setOperatorAddress(
        address account,
        bool _isOperator
    ) external onlyContractCreator {
        require(account != _burnWallet, "BirdBro: address(0x0)"); // Check if the operator address is valid.
        _operators[account] = _isOperator;

        emit OperatorUpdated(account);
    }

    /**
     * @dev Returns the name of the token
     * @return string The name of the token
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the symbol of the token.
     * @return string The symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals the token uses (number of zeros after the decimal point).
     * @return uint8 The number of decimals the token uses.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Gets the total token supply.
     * @return The total token supply.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param account The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Call `_transfer`
     *
     * @param recipient The address of the destination account.
     * @param amount The amount of token to be transferred.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Returns the amount which `spender` is still allowed to withdraw from `owner`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Throws if the `spender` is not authorized to spend on behalf of `owner`.
     *
     * **Note**: This is a read-only function which does not modify state.
     *
     * @param owner The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return An uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param amount The amount of tokens to be spent.
     */
    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev Transfer `amount` tokens from `sender` to `recipient` using the
     *  allowance mechanism. `recipient` must be allowed by `sender`'s `allowance`
     *  mapping. This is internal function is equivalent to
     *  `ERC20.transferFrom` except that it emits the `Transfer` event.
     * @param sender The address of the source account.
     * @param recipient The address of the destination account.
     * @param amount The amount of token to be transferred.
     * @return True if the transfer was successful or false otherwise.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BirdBro: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Increases the amount of tokens that an owner allowed to a spender.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     * @return True if the operation was successful.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Decreases the amount of tokens that an owner allowed to a spender.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BirdBro: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Sets the maximum amount of tokens that can be transferred in a single transaction.
     * @param maxTxAmount The maximum amount of tokens that can be transferred in a single transaction.
     */
    function setMaxTxAmount(uint256 maxTxAmount) external onlyOperator {
        require(
            maxTxAmount >= _maxTxAmount,
            "BirdBro: The new limit must be greater than or equal to the minimum transfer limit."
        );

        _previousMaxTxAmount = _maxTxAmount;
        _maxTxAmount = maxTxAmount * 10 ** _decimals;
    }

    /**
     * @dev Sets the maximum amount of tokens in a wallet
     * @param maxWalletAmount The maximum amount of tokens a wallet can have
     */
    function setMaxWalletAmount(uint256 maxWalletAmount) external onlyOperator {
        require(
            maxWalletAmount >= _maxWalletAmount,
            "BirdBro: The new limit must be greater than or equal to the minimum transfer limit."
        );

        _previousMaxWalletAmount = _maxWalletAmount;
        _maxWalletAmount = maxWalletAmount * 10 ** _decimals;
    }

    /**
     * @dev Sets the maximum amount of tokens that can be sent to an address in a single transaction.
     * @param account The address to set the maximum amount for.
     * @param maxTxAmount The maximum amount of tokens that can be sent to the address in a single transaction.
     */
    function setMaxTxAmountAddress(
        address account,
        uint256 maxTxAmount
    ) external onlyOperator {
        require(
            maxTxAmount >= _maxTxAmount,
            "BirdBro: The new limit must be greater than or equal to the minimum transfer limit."
        );

        _maxTxAmountAddress[account] = maxTxAmount * 10 ** _decimals;
    }

    /**
     * @dev Sets the maximum amount of tokens in a wallet
     * @param account The address to set the maximum amount for.
     * @param maxWalletAmount The maximum amount of tokens a wallet can have
     */
    function setMaxWalletAmountAddress(
        address account,
        uint256 maxWalletAmount
    ) external onlyOperator {
        require(
            maxWalletAmount >= _maxWalletAmount,
            "BirdBro: The new limit must be greater than or equal to the minimum wallet limit."
        );

        _maxWalletAmountAddress[account] = maxWalletAmount * 10 ** _decimals;
    }

    /**
     * @dev Sets whether an address is excluded from the maximum amount of tokens that can be sent to it in a single transaction.
     * @param account The address to set the exclusion for.
     * @param isExcluded Whether the address is excluded from the maximum amount of tokens that can be sent to it in a single
     */
    function setExcludedAddressMaxTxAmount(
        address account,
        bool isExcluded
    ) external onlyOperator {
        _isExcludedMaxTxAmount[account] = isExcluded;
    }

    /**
     * @dev Sets whether an address is excluded from the maximum amount of tokens in a wallet
     * @param account The address to set the exclusion for.
     * @param isExcluded Whether the address is excluded from the maximum amount of tokens in a wallet
     */
    function setExcludedAddressMaxWalletAmount(
        address account,
        bool isExcluded
    ) external onlyOperator {
        _isExcludedMaxWalletAmount[account] = isExcluded;
    }

    /**
     * @dev Returns true if the account is excluded from the max tx limit.
     * @param account The account to check.
     * @return True if the account is excluded from the max tx limit.
     */
    function isExcludedMaxTx(address account) public view returns (bool) {
        return _isExcludedMaxTxAmount[account];
    }

    /**
     * @dev Returns true if the account is excluded from the maximum wallet limit
     * @param account The account to check.
     * @return True if the account is excluded from the max wallet limit.
     */
    function isExcludedMaxWallet(address account) public view returns (bool) {
        return _isExcludedMaxWalletAmount[account];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param amount The amount of tokens to be spent.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(
            owner != _burnWallet,
            "BirdBro: _approve, owner cannot be the burn address"
        );
        require(
            spender != _burnWallet,
            "BirdBro: _approve, spender cannot be the burn address"
        );

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Transfer `amount` tokens from `from` to `to`.
     *
     * @param from The address from which the transfer is performed.
     * @param to The address to which the transfer is performed.
     * @param amount The amount of tokens to be transferred.
     */
    function _transfer(address from, address to, uint256 amount) internal {
        // Check if the transfer involves the burn wallet address
        require(
            from != _burnWallet && to != _burnWallet,
            "BirdBro: Invalid transfer to or from burn address"
        );

        // Check if the transfer amount is greater than zero
        require(
            amount > 0,
            "BirdBro: Transfer amount must be greater than zero"
        );

        // Check if the sender or recipient address is excluded from the maxTxAmount
        bool isExcludedFromMaxTx = _isExcludedMaxTxAmount[from] ||
            _isExcludedMaxTxAmount[to];

        // Check if the sender or recipient address is excluded from the maxWalletAmount
        bool isExcludedFromMaxWallet = _isExcludedMaxWalletAmount[from] ||
            _isExcludedMaxWalletAmount[to];

        // If the address is not excluded from the maxTxAmount, check if the transfer amount exceeds it
        if (!isExcludedFromMaxTx) {
            require(
                amount <= _maxTxAmount,
                "BirdBro: Transfer amount exceeds the maxTxAmount"
            );
        }

        // If the address is not excluded from the maxWalletAmount, check if the recipient's wallet has exceeded the limit
        if (!isExcludedFromMaxWallet) {
            uint256 maxWalletAmount = _maxWalletAmount;

            if (_maxWalletAmountAddress[to] > 0) {
                maxWalletAmount = _maxWalletAmountAddress[to];
            }

            require(
                balanceOf(to).add(amount) <= maxWalletAmount,
                "BirdBro: Recipient's wallet has exceeded the allowed token limit"
            );
        }

        // Ensure that the sender has enough balance to transfer the original amount
        require(
            _balances[from] >= amount,
            "BirdBro: Not enough balance to transfer"
        );

        // Subtract the original amount from sender balance and add the transfer amount to recipient balance
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);

        // Emit transfer event to recipient
        emit Transfer(from, to, amount);
    }

    /**
     * @dev Adds liquidity to the Uniswap exchange.
     * @param tokenAmount The amount of tokens to add to the exchange.
     * @param ethAmount The amount of ETH to add to the exchange.
     */
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(_token, address(_uniswapRouter), tokenAmount);

        // add the liquidity
        _uniswapRouter.addLiquidityETH{value: ethAmount}(
            _token, // token address
            tokenAmount, // amount of tokens to add to the exchange.
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _burnWallet, //
            block.timestamp + 5 minutes // expiration time of the transaction.
        );
    }

    /**
     * @dev Gets the balance of the specified address.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function getContractBalance() public view returns (uint256) {
        return balanceOf(address(this));
    }

    /**
     * @dev Returns the ETH balance of the contract.
     * @return The ETH balance of the contract.
     */
    function getETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Withdraws tokens from the contract.
     * @param _tokenAddress The address of the token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawToken(
        address _tokenAddress,
        uint256 _amount
    ) external onlyManager {
        require(address(_tokenAddress) != _burnWallet, "BirdBro: address(0x0)");

        IBirdBro(_tokenAddress).transfer(msg.sender, _amount);
    }

    /**
     * @dev Withdraws ETH from the contract.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawEth(uint256 _amount) external onlyManager {
        payable(msg.sender).transfer(_amount);
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
        require(account != _burnWallet, "BirdBro: address(0x0)");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

        require(
            _totalSupply <= 100_000_000 * 10 ** _decimals,
            "BirdBro: Maximum supply reached"
        );

        emit Transfer(_burnWallet, account, amount);
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
        require(account != _burnWallet, "BirdBro: address(0x0)");

        uint256 balance = _balances[account];
        require(balance >= amount, "BirdBro: Insufficient balance");

        _balances[account] = balance.sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, _burnWallet, amount);
    }

    /**
     * @dev Mints new tokens.
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     *
     * NOTE: Only onlyBridge can call this function
     *
     */
    function mint(
        address to,
        uint256 amount
    ) external onlyBridge returns (bool) {
        _mint(to, amount);
        return true;
    }

    /**
     * @dev Burns a specific amount of tokens from the given address.
     * @param from The address of the sender.
     * @param amount The amount of token to be burned.
     * @return True if the operation was successful.
     *
     * NOTE: Only onlyBridge can call this function
     *
     */
    function burn(
        address from,
        uint256 amount
    ) external onlyBridge returns (bool) {
        require(from != _burnWallet, "BirdBro: address(0x0)");
        _burn(from, amount);
        return true;
    }
}