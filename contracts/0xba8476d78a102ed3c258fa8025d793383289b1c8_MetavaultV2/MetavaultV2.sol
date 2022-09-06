/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

/*
* 
MetavaultV2 ETH

Supply: 10 000 000 000

DO NOT BUY UNTIL CONTRACT ADDRESS IS POSTED IN TELEGRAM

*
*/

pragma solidity =0.8.9;

// SPDX-License-Identifier: UNLICENSED

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IuniswapV2ERC20 {
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
}

interface IuniswapV2Factory {
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

interface IuniswapV2Router01 {
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

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IuniswapV2Router02 is IuniswapV2Router01 {
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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = msg.sender;
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

//MetaVault V2 ETH Contract /////////////

contract MetavaultV2 is IBEP20, Ownable
{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    event ContractChanged(uint256 indexed value);
    event ContractChangedBool(bool indexed value);
    event ContractChangedAddress(address indexed value);
    event antiBotBan(address indexed value);
    
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _buyLock;
    mapping ( address => bool ) public blackList;

    EnumerableSet.AddressSet private _excluded;

    //Token Info
    string private constant _name = 'METAVAULT';
    string private constant _symbol = 'MVT';
    uint8 private constant _decimals = 9;
    uint256 public constant InitialSupply= 10000000000 * 10**_decimals;

    //Amount to Swap variable (0.2%)
    uint256 currentAmountToSwap = 15000000 * 10**_decimals;
    //Divider for the MaxBalance based on circulating Supply (0.25%)
    uint16 public constant BalanceLimitDivider=400;
    //Divider for sellLimit based on circulating Supply (0.25%)
    uint16 public constant SellLimitDivider=400;
	//Buyers get locked for MaxBuyLockTime (put in seconds, works better especially if changing later) so they can't buy repeatedly
    uint16 public constant MaxBuyLockTime= 9 seconds;
    //The time Liquidity gets locked at start and prolonged once it gets released
    uint256 private constant DefaultLiquidityLockTime= 1800;
    //DevWallets
    address public TeamWallet=payable(0x4A1805ae04C88e321fcc1778c4f2E3EF24FCEEAc);
    address public MarketingWallet=payable(0x2e0fF83A64373e13179e307523fBe3D08e04a4d8);
    //Uniswap router (Main & Testnet)
    address private uniswapV2Router=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;


    //variables that track balanceLimit and sellLimit,
    //can be updated based on circulating supply and Sell- and BalanceLimitDividers
    uint256 private _circulatingSupply =InitialSupply;
    uint256 public  balanceLimit = _circulatingSupply;
    uint256 public  sellLimit = _circulatingSupply;
	uint256 private antiWhale = 20000000 * 10**_decimals; // (0.2%)

    //Used for anti-bot autoblacklist
    uint256 private tradingEnabledAt; //DO NOT CHANGE, THIS IS FOR HOLDING A TIMESTAMP
	uint256 private autoBanTime = 90; // Set to the amount of time in seconds after enable trading you want addresses to be auto blacklisted if they buy/sell/transfer in this time.
	uint256 private enableAutoBlacklist = 1; //Leave 1 if using, set to 0 if not using.
    
    //Tracks the current Taxes, different Taxes can be applied for buy/sell/transfer
    uint8 private _buyTax;
    uint8 private _sellTax;
    uint8 private _transferTax;

    uint8 private _burnTax;
    uint8 private _liquidityTax;
    uint8 private _marketingTax;
       
    address private _uniswapV2PairAddress; 
    IuniswapV2Router02 private _uniswapV2Router;

    //Constructor///////////

    constructor () {
        //contract creator gets 90% of the token to create LP-Pair
        uint256 deployerBalance=_circulatingSupply;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);
        // Uniswap Router
        _uniswapV2Router = IuniswapV2Router02(uniswapV2Router);
        //Creates a Uniswap Pair
        _uniswapV2PairAddress = IuniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        
        //Sets Buy/Sell limits
        balanceLimit=InitialSupply/BalanceLimitDivider;
        sellLimit=InitialSupply/SellLimitDivider;
		
		//Sets buyLockTime
        buyLockTime=0;

        //Set Starting Taxes 
        
        _buyTax=5;
        _sellTax=5;
        _transferTax=5;

        _burnTax=0;
        _liquidityTax=30;
        _marketingTax=80;

        //Team wallets and deployer are excluded from Taxes
        _excluded.add(TeamWallet);
        _excluded.add(MarketingWallet);
        _excluded.add(msg.sender);
    
    }

    //Transfer functionality///

    //transfer function, every transfer runs through this function
    function _transfer(address sender, address recipient, uint256 amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
        
        //Manually Excluded adresses are transfering tax and lock free
        bool isExcluded = (_excluded.contains(sender) || _excluded.contains(recipient));
        
        //Transactions from and to the contract are always tax and lock free
        bool isContractTransfer=(sender==address(this) || recipient==address(this));
        
        //transfers between UniswapRouter and UniswapPair are tax and lock free
        address uniswapV2Router=address(_uniswapV2Router);
        bool isLiquidityTransfer = ((sender == _uniswapV2PairAddress && recipient == uniswapV2Router) 
        || (recipient == _uniswapV2PairAddress && sender == uniswapV2Router));

        //differentiate between buy/sell/transfer to apply different taxes/restrictions
        bool isBuy=sender==_uniswapV2PairAddress|| sender == uniswapV2Router;
        bool isSell=recipient==_uniswapV2PairAddress|| recipient == uniswapV2Router;

        //Pick transfer
        if(isContractTransfer || isLiquidityTransfer || isExcluded){
            _feelessTransfer(sender, recipient, amount);
        }
        else{ 
            //once trading is enabled, it can't be turned off again
            require(tradingEnabled,"trading not yet enabled");
            _taxedTransfer(sender,recipient,amount,isBuy,isSell);
        }
    }
    //applies taxes, checks for limits, locks generates autoLP
    function _taxedTransfer(address sender, address recipient, uint256 amount,bool isBuy,bool isSell) private{
        uint256 recipientBalance = _balances[recipient];
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");

        uint8 tax;
        if(isSell){
            //Sells can't exceed the sell limit
            require(amount<=sellLimit,"Dump protection");
            require(blackList[sender] == false, "Address blacklisted!");
            if (block.timestamp <= tradingEnabledAt + autoBanTime && enableAutoBlacklist == 1) {
                blackList[sender] = true;
                emit antiBotBan(sender);
            }
            tax=_sellTax;


        } else if(isBuy){
            //Checks If the recipient balance(excluding Taxes) would exceed Balance Limit
            require(recipientBalance+amount<=balanceLimit,"whale protection");
			require(amount <= antiWhale,"Tx amount exceeding max buy amount");
            require(blackList[recipient] == false, "Address blacklisted!");
            if (block.timestamp <= tradingEnabledAt + autoBanTime && enableAutoBlacklist == 1) {
                blackList[recipient] = true;
                emit antiBotBan(recipient);
            }
            tax=_buyTax;

        } else {//Transfer
            //Checks If the recipient balance(excluding Taxes) would exceed Balance Limit
            require(blackList[sender] == false, "Sender address blacklisted!");
            require(blackList[recipient] == false, "Recipient address blacklisted!");
            require(recipientBalance+amount<=balanceLimit,"whale protection");
            if (block.timestamp <= tradingEnabledAt + autoBanTime && enableAutoBlacklist == 1) {
                blackList[sender] = true;
                emit antiBotBan(sender);
            }
            tax=_transferTax;


        }     
        //Swapping AutoLP and MarketingETH is only possible if sender is not uniswapV2 pair, 
        //if its not manually disabled, if its not already swapping and if its a Sell to avoid
        // people from causing a large price impact from repeatedly transfering when theres a large backlog of Tokens
        if((sender!=_uniswapV2PairAddress)&&(!manualConversion)&&(!_isSwappingContractModifier)&&isSell)
            _swapContractToken();
        //Calculates the exact token amount for each tax
        uint256 tokensToBeBurnt=_calculateFee(amount, tax, _burnTax);
        uint256 contractToken=_calculateFee(amount, tax, _marketingTax+_liquidityTax);
        //Subtract the Taxed Tokens from the amount
        uint256 taxedAmount=amount-(tokensToBeBurnt + contractToken);

        //Removes token
        _removeToken(sender,amount);
        
        //Adds the taxed tokens to the contract wallet
        _balances[address(this)] += contractToken;
        //Burns tokens
        _circulatingSupply-=tokensToBeBurnt;

        //Adds token
        _addToken(recipient, taxedAmount);
        
        emit Transfer(sender,recipient,taxedAmount);

    }

    //Feeless transfer only transfers
    function _feelessTransfer(address sender, address recipient, uint256 amount) private{
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        //Removes token
        _removeToken(sender,amount);
        //Adds token
        _addToken(recipient, amount);
        
        emit Transfer(sender,recipient,amount);

    }
    //Calculates the token that should be taxed
    function _calculateFee(uint256 amount, uint8 tax, uint8 taxPercent) private pure returns (uint256) {
        return (amount*tax*taxPercent) / 10000;
    }
  
    //balance that is claimable by the team
    uint256 public marketingBalance;

    //adds Token to balances
    function _addToken(address addr, uint256 amount) private {
        //the amount of token after transfer
        uint256 newAmount=_balances[addr]+amount;
        //sets newBalance
        _balances[addr]=newAmount;
    }
    
    
    //removes Token
    function _removeToken(address addr, uint256 amount) private {
        //the amount of token after transfer
        uint256 newAmount=_balances[addr]-amount;
        //sets newBalance
        _balances[addr]=newAmount;
    }

    //Swap Contract Tokens//////////////////////////////////////////////////////////////////////////////////

    //tracks auto generated ETH, useful for ticker etc
    uint256 public totalLPETH;
    //Locks the swap if already swapping
    bool private _isSwappingContractModifier;
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    //swaps the token on the contract for Marketing ETH and LP Token.
    //always swaps the sellLimit of token to avoid a large price impact
    function _swapContractToken() private lockTheSwap{
        uint256 contractBalance=_balances[address(this)];
        uint16 totalTax=_marketingTax+_liquidityTax;
        uint256 tokenToSwap = currentAmountToSwap;
        //only swap if contractBalance is larger than tokenToSwap, and totalTax is unequal to 0
        if(contractBalance<tokenToSwap||totalTax==0){
            return;
        }
        //splits the token in TokenForLiquidity and tokenForMarketing
        uint256 tokenForLiquidity=(tokenToSwap*_liquidityTax)/totalTax;
        uint256 tokenForMarketing= tokenToSwap-tokenForLiquidity;

        //splits tokenForLiquidity in 2 halves
        uint256 liqToken=tokenForLiquidity/2;
        uint256 liqETHToken=tokenForLiquidity-liqToken;

        //swaps marktetingToken and the liquidity token half for ETH
        uint256 swapToken=liqETHToken+tokenForMarketing;
        //Gets the initial ETH balance
        uint256 initialETHBalance = address(this).balance;
        _swapTokenForETH(swapToken);
        uint256 newETH=(address(this).balance - initialETHBalance);
        //calculates the amount of ETH belonging to the LP-Pair and converts them to LP
        uint256 liqETH = (newETH*liqETHToken)/swapToken;
        _addLiquidity(liqToken, liqETH);
        //Get the ETH balance after LP generation to get the
        //exact amount of token left for marketing
        uint256 distributeETH=(address(this).balance - initialETHBalance);
        //distributes remaining BETHNB to Marketing
        marketingBalance+=distributeETH;
    }
    //swaps tokens on the contract for ETH
    function _swapTokenForETH(uint256 amount) private {
        _approve(address(this), address(_uniswapV2Router), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    //Adds Liquidity directly to the contract where LP are locked(unlike safemoon forks, that transfer it to the owner)
    function _addLiquidity(uint256 tokenamount, uint256 ethamount) private returns (uint256 tAmountSent, uint256 ethAmountSent) {
        totalLPETH+=ethamount;
        uint256 minETH = (ethamount*75) / 100;
        uint256 minTokens = (tokenamount*75) / 100;
        _approve(address(this), address(_uniswapV2Router), tokenamount);
        _uniswapV2Router.addLiquidityETH{value: ethamount}(
            address(this),
            tokenamount,
            minTokens,
            minETH,
            address(this),
            block.timestamp
        );
        tAmountSent = tokenamount;
        ethAmountSent = ethamount;
        return (tAmountSent, ethAmountSent);
    }

    //public functions /////////////////////////////////////////////////////////////////////////////////////

    function getLiquidityReleaseTimeInSeconds() external view returns (uint256){
        if(block.timestamp<_liquidityUnlockTime){
            return _liquidityUnlockTime-block.timestamp;
        }
        return 0;
    }

    function getBurnedTokens() external view returns(uint256){
        return (InitialSupply-_circulatingSupply)/10**_decimals;
    }

    function getLimits() external view returns(uint256 balance, uint256 sell){
        return(balanceLimit/10**_decimals, sellLimit/10**_decimals);
    }

    function getTaxes() external view returns(uint256 burnTax,uint256 liquidityTax, uint256 marketingTax, uint256 buyTax, uint256 sellTax, uint256 transferTax){
        return (_burnTax,_liquidityTax,_marketingTax,_buyTax,_sellTax,_transferTax);
    }
	
    //How long is a given address still locked from buying
	function getAddressBuyLockTimeInSeconds(address AddressToCheck) external view returns (uint256){
       uint256 lockTime=_buyLock[AddressToCheck];
       if(lockTime<=block.timestamp)
       {
           return 0;
       }
       return lockTime-block.timestamp;
    }
    function getBuyLockTimeInSeconds() external view returns(uint256){
        return buyLockTime;
    }
    
    //Functions every wallet can call
	
	//Resets buy lock of caller to the default buyLockTime should something go very wrong
    function AddressResetBuyLock() external{
        _buyLock[msg.sender]=block.timestamp+buyLockTime;
	
    }

    //Settings//////////////////////////////////////////////////////////////////////////////////////////////
 
	bool public buyLockDisabled;
    uint256 public buyLockTime;
    bool public manualConversion; 

    function TeamWithdrawALLMarketingETH() external onlyOwner{
        uint256 amount=marketingBalance;
        marketingBalance=0;
        payable(TeamWallet).transfer((amount*50) / 100);
        payable(MarketingWallet).transfer((amount-(amount*50) / 100));
        emit Transfer(address(this), TeamWallet, (amount*50) / 100);
        emit Transfer(address(this), MarketingWallet, (amount-(amount*50) / 100));
    } 
    function TeamWithdrawXMarketingETH(uint256 amount) external onlyOwner{
        require(amount<=marketingBalance,
        "Error: Amount greater than available balance.");
        marketingBalance-=amount;
        payable(TeamWallet).transfer((amount*50) / 100);
        payable(MarketingWallet).transfer((amount-(amount*50) / 100));
        emit Transfer(address(this), TeamWallet, (amount*50) / 100);
        emit Transfer(address(this), MarketingWallet, (amount-(amount*50) / 100));
    } 

    //switches autoLiquidity and marketing ETH generation during transfers
    function TeamSwitchManualETHConversion(bool manual) external onlyOwner{
        manualConversion=manual;
        emit ContractChangedBool(manualConversion);
    }
	
	function TeamChangeAntiWhale(uint256 newAntiWhale) external onlyOwner{
      antiWhale=newAntiWhale * 10**_decimals;
      emit ContractChanged(antiWhale);
    }
    
    function TeamChangeTeamWallet(address newTeamWallet) external onlyOwner{
      require(newTeamWallet != address(0),
      "Error: Cannot be 0 address.");
      TeamWallet=payable(newTeamWallet);
      emit ContractChangedAddress(TeamWallet);
    }
    
    function TeamChangeMarketingWallet(address newMarketingWallet) external onlyOwner{
      require(newMarketingWallet != address(0),
      "Error: Cannot be 0 address.");
      MarketingWallet=payable(newMarketingWallet);
      emit ContractChangedAddress(MarketingWallet);
    }
	
	//Disables the timeLock after buying for everyone
    function TeamDisableBuyLock(bool disabled) external onlyOwner{
        buyLockDisabled=disabled;
        emit ContractChangedBool(buyLockDisabled);
    }
	
	//Sets BuyLockTime, needs to be lower than MaxBuyLockTime
    function TeamSetBuyLockTime(uint256 buyLockSeconds) external onlyOwner{
            require(buyLockSeconds<=MaxBuyLockTime,"Buy Lock time too high");
            buyLockTime=buyLockSeconds;
            emit ContractChanged(buyLockTime);
    } 

    //Allows CA owner to change how much the contract sells to prevent massive contract sells as the token grows.
    function TeamUpdateAmountToSwap(uint256 newSwapAmount) external onlyOwner{
        currentAmountToSwap = newSwapAmount;
        emit ContractChanged(currentAmountToSwap);
    }
    
    //Allows wallet exclusion to be added after launch
    function addWalletExclusion(address exclusionAdd) external onlyOwner{
        _excluded.add(exclusionAdd);
        emit ContractChangedAddress(exclusionAdd);
    }

    //Allows you to remove wallet exclusions after launch
    function removeWalletExclusion(address exclusionRemove) external onlyOwner{
        _excluded.remove(exclusionRemove);
        emit ContractChangedAddress(exclusionRemove);
    }

    //Adds address to blacklist and prevents sells, buys or transfers.
    function addAddressToBlacklist(address blacklistedAddress) external onlyOwner {
        blackList[ blacklistedAddress ] = true;
        emit ContractChangedAddress(blacklistedAddress);
    }

    function blacklistAddressArray ( address [] memory _address ) public onlyOwner {
        
        for ( uint256 x=0; x< _address.length ; x++ ){
            blackList[_address[x]] = true;
            
        }
        
    }

    //Check if address is blacklisted (can be called by anyone)
    function checkAddressBlacklist(address submittedAddress) external view returns (bool isBlacklisted) {
        
        if (blackList[submittedAddress] == true) {
            isBlacklisted = true;
            return isBlacklisted;
        }
        if (blackList[submittedAddress] == false) {
            isBlacklisted = false;
            return isBlacklisted;
        }
    }

    //Remove address from blacklist and allow sells, buys or transfers.
    function removeAddressFromBlacklist(address blacklistedAddress) external onlyOwner {
        blackList[ blacklistedAddress ] = false;
        emit ContractChangedAddress(blacklistedAddress);
    }
    
    //Sets Taxes, is limited by MaxTax(20%) to make it impossible to create honeypot
    function TeamSetTaxes(uint8 burnTaxes, uint8 liquidityTaxes, uint8 marketingTaxes, uint8 buyTax, uint8 sellTax, uint8 transferTax) external onlyOwner{
        uint8 totalTax=burnTaxes+liquidityTaxes+marketingTaxes;
        require(totalTax==100, "burn+liq+marketing needs to equal 100%");
        require(buyTax <= 20,
        "Error: Honeypot prevention prevents buyTax from exceeding 20.");
        require(sellTax <= 20,
        "Error: Honeypot prevention prevents sellTax from exceeding 20.");
        require(transferTax <= 20,
        "Error: Honeypot prevention prevents transferTax from exceeding 20.");

        _burnTax=burnTaxes;
        _liquidityTax=liquidityTaxes;
        _marketingTax=marketingTaxes;
        
        _buyTax=buyTax;
        _sellTax=sellTax;
        _transferTax=transferTax;

        emit ContractChanged(_burnTax);
        emit ContractChanged(_liquidityTax);
        emit ContractChanged(_buyTax);
        emit ContractChanged(_sellTax);
        emit ContractChanged(_transferTax);
    }

    //manually converts contract token to LP
    function TeamCreateLPandETH() external onlyOwner{
    _swapContractToken();
    }
    
    function teamUpdateUniswapRouter(address newRouter) external onlyOwner {
        require(newRouter != address(0),
        "Error: Cannot be 0 address.");
        uniswapV2Router=newRouter;
        emit ContractChangedAddress(newRouter);
    }
     //Limits need to be at least target, to avoid setting value to 0(avoid potential Honeypot)
    function TeamUpdateLimits(uint256 newBalanceLimit, uint256 newSellLimit) external onlyOwner{
        //SellLimit needs to be below 1% to avoid a Large Price impact when generating auto LP
        require(newSellLimit<_circulatingSupply/100,
        "Error: New sell limit above 1% of circulating supply.");
        //Adds decimals to limits
        newBalanceLimit=newBalanceLimit*10**_decimals;
        newSellLimit=newSellLimit*10**_decimals;
        //Calculates the target Limits based on supply
        uint256 targetBalanceLimit=_circulatingSupply/BalanceLimitDivider;
        uint256 targetSellLimit=_circulatingSupply/SellLimitDivider;

        require((newBalanceLimit>=targetBalanceLimit), 
        "newBalanceLimit needs to be at least target");
        require((newSellLimit>=targetSellLimit), 
        "newSellLimit needs to be at least target");

        balanceLimit = newBalanceLimit;
        sellLimit = newSellLimit;
        emit ContractChanged(balanceLimit);
        emit ContractChanged(sellLimit);
    }

    
    //Setup Functions///////////////////////////////////////////////////////////////////////////////////////
    
    bool public tradingEnabled;
    address private _liquidityTokenAddress;
    //Enables trading for everyone
    function SetupEnableTrading() external onlyOwner{
        tradingEnabled=true;
        tradingEnabledAt=block.timestamp;
    }
    //Sets up the LP-Token Address required for LP Release
    function SetupLiquidityTokenAddress(address liquidityTokenAddress) external onlyOwner{
        require(liquidityTokenAddress != address(0),
        "Error: Cannot be 0 address.");
        _liquidityTokenAddress=liquidityTokenAddress;
    }

    //Liquidity Lock////////////////////////////////////////////////////////////////////////////////////////
    //the timestamp when Liquidity unlocks
    uint256 private _liquidityUnlockTime;

    //Adds time to LP lock in seconds.
    function TeamProlongLiquidityLockInSeconds(uint256 secondsUntilUnlock) external onlyOwner{
        _prolongLiquidityLock(secondsUntilUnlock+block.timestamp);
        emit ContractChanged(secondsUntilUnlock+block.timestamp);
    }
    //Adds time to LP lock based on set time.
    function _prolongLiquidityLock(uint256 newUnlockTime) private{
        // require new unlock time to be longer than old one
        require(newUnlockTime>_liquidityUnlockTime,
        "Error: New unlock time is shorter than old one.");
        _liquidityUnlockTime=newUnlockTime;
        emit ContractChanged(_liquidityUnlockTime);
    }

    //Release Liquidity Tokens once unlock time is over
    function TeamReleaseLiquidity() external onlyOwner returns (address tWAddress, uint256 amountSent) {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        
        IuniswapV2ERC20 liquidityToken = IuniswapV2ERC20(_liquidityTokenAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));

        //Liquidity release if something goes wrong at start
        liquidityToken.transfer(TeamWallet, amount);
        emit Transfer(address(this), TeamWallet, amount);
        tWAddress = TeamWallet;
        amountSent = amount;
        return (tWAddress, amountSent);
        
    }
    //Removes Liquidity once unlock Time is over, 
    function TeamRemoveLiquidity() external onlyOwner returns (uint256 newBalance) {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        IuniswapV2ERC20 liquidityToken = IuniswapV2ERC20(_liquidityTokenAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));

        liquidityToken.approve(address(_uniswapV2Router),amount);
        //Removes Liquidity and adds it to marketing Balance
        uint256 initialETHBalance = address(this).balance;
        
        _uniswapV2Router.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            amount,
            (amount*75) / 100,
            (amount*75) / 100,
            address(this),
            block.timestamp
            );
        uint256 newETHBalance = address(this).balance-initialETHBalance;
        marketingBalance+=newETHBalance;
        newBalance=newETHBalance;
        return newBalance;
    }
    //Releases all remaining ETH on the contract wallet, so ETH wont be burned
    function TeamRemoveRemainingETH() external onlyOwner{
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        (bool sent,) =TeamWallet.call{value: (address(this).balance)}("");
        require(sent,
        "Error: Not sent.");
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //external//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    receive() external payable {}
    fallback() external payable {}
    // IBEP20

    function getOwner() external view override returns (address) {
        return owner();
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _circulatingSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    // IBEP20 - Helpers

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

}