/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

/**

███████╗██╗  ██╗██╗██████╗     ██╗    ██╗ █████╗ ██████╗ ██████╗ ██╗ ██████╗ ██████╗ 
██╔════╝██║  ██║██║██╔══██╗    ██║    ██║██╔══██╗██╔══██╗██╔══██╗██║██╔═══██╗██╔══██╗
███████╗███████║██║██████╔╝    ██║ █╗ ██║███████║██████╔╝██████╔╝██║██║   ██║██████╔╝
╚════██║██╔══██║██║██╔══██╗    ██║███╗██║██╔══██║██╔══██╗██╔══██╗██║██║   ██║██╔══██╗
███████║██║  ██║██║██████╔╝    ╚███╔███╔╝██║  ██║██║  ██║██║  ██║██║╚██████╔╝██║  ██║
╚══════╝╚═╝  ╚═╝╚═╝╚═════╝      ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═╝  ╚═╝
                                                                                     

Shib Warrior

https://shibwarrior.com

https://t.me/ShibWarriorEth

*** SELL TAX HIGHER ON LAUNCH WILL BE LOWERED ***

Total Supply: 1,000,000
Max Wallet: 2% (20,000 Tokens)
Max Buy: 2% (20,000 Tokens)
Max Sell: 2% (20,000 Tokens)
Buy / Sell Tax: 7% 
- 4% Marketing
- 2% LP
- 1% Development


*/

pragma solidity ^0.8.15;

// SPDX-License-Identifier: Unlicensed

interface IERC20 {
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


interface IUniswapV2ERC20 {
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

interface IUniswapV2Router01 {
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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
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

////////// Contract /////////////

contract ShibWarrior is IERC20, Ownable
{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    event antiBotBan(address indexed value);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _sellLock;
    mapping (address => uint256) private _buyLock;

    EnumerableSet.AddressSet private _excluded;
    EnumerableSet.AddressSet private _excludedFromSellLock;
    EnumerableSet.AddressSet private _excludedFromBuyLock;
    EnumerableSet.AddressSet private _excludedFromStaking;

    EnumerableSet.AddressSet private _isBlacklisted;

    //Token Info
    string public _name = "Shib Warrior";
    string public _symbol = "$SWRR";
    uint8 private constant _decimals = 9;
    uint256 public constant InitialSupply= 1000000 * 10**_decimals;//equals 1,000,000 tokens 1000000

    //Used for anti-bot autoblacklist
    uint256 private tradingEnabledAt; //DO NOT CHANGE, THIS IS FOR HOLDING A TIMESTAMP
    uint256 public autoBanTime = 20; // Set to the amount of time in seconds after enable trading you want addresses to be auto blacklisted if they buy/sell/transfer in this time.
    uint256 public enableAutoBlacklist = 0; //Leave 1 if using, set to 0 if not using.
    //Divider for the MaxBalance based on circulating Supply (2%)
    uint8 public constant BalanceLimitDivider=50;
    //Divider for sellLimit based on circulating Supply (2%))
    uint16 public constant SellLimitDivider=50;
    //Sellers get locked for MaxSellLockTime (put in seconds, works better especially if changing later) so they can't dump repeatedly
    uint16 public constant MaxSellLockTime= 0 seconds;
    //Buyers get locked for MaxBuyLockTime (put in seconds, works better especially if changing later) so they can't buy repeatedly
    uint16 public constant MaxBuyLockTime= 0 seconds;
    //The time Liquidity gets locked at start and prolonged once it gets released
    uint256 private constant DefaultLiquidityLockTime= 1800;
    //DevWallets
    address public Development=payable(0x2Dcb6E31e206Cd91B601369Fdb601ac4D6233D68);
    address public Marketing=payable(0xf30bb0b3C67c596F770F9cEC66d5D5DB24f94d3C);
    //MainNet
    address private constant UniswapV2Router=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    //variables that track balanceLimit and sellLimit,
    //can be updated based on circulating supply and Sell- and BalanceLimitDividers
    uint256 private _circulatingSupply =InitialSupply;
    uint256 public  balanceLimit = _circulatingSupply;
    uint256 public  sellLimit = _circulatingSupply;
    uint256 private MaxBuy = 20000 * 10**_decimals; // 40,000 tokens
    
    //Tracks the current Taxes, different Taxes can be applied for buy/sell/transfer
    uint8 private _buyTax;
    uint8 private _sellTax;
    uint8 private _transferTax;

    uint8 private _burnTax;
    uint8 private _liquidityTax;
    uint8 private _stakingTax;

       
    address private _uniswapv2PairAddress; 
    IUniswapV2Router02 private  _uniswapv2Router;
    
    //Checks if address is in Team, is needed to give Team access even if contract is renounced
    //Team doesn't have access to critical Functions that could turn this into a Rugpull(Exept liquidity unlocks)
    function _isTeam(address addr) private view returns (bool){
        return addr==owner()||addr==Development||addr==Marketing;
    }

    //Constructor///////////

    constructor () {
        //contract creator gets 90% of the token to create LP-Pair
        uint256 deployerBalance=_circulatingSupply;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);
        // UniswapV2 Router
        _uniswapv2Router = IUniswapV2Router02(UniswapV2Router);
        //Creates a UniswapV2 Pair
        _uniswapv2PairAddress = IUniswapV2Factory(_uniswapv2Router.factory()).createPair(address(this), _uniswapv2Router.WETH());
        
        //Sets Buy/Sell limits
        balanceLimit=InitialSupply/BalanceLimitDivider;
        sellLimit=InitialSupply/SellLimitDivider;

        //Sets sellLockTime
        sellLockTime=0;
        
        //Sets buyLockTime
        buyLockTime=0;

        //Set Starting Tax 
        
        _buyTax=7;
        _sellTax=14;
        _transferTax=7;

        _burnTax=0;
        _liquidityTax=20;
        _stakingTax=80;

        //Team wallets and deployer are excluded from Taxes
        _excluded.add(Development);
        _excluded.add(Marketing);
        _excluded.add(msg.sender);
        //excludes UniswapV2 Router, pair, contract and burn address from staking
        _excludedFromStaking.add(address(_uniswapv2Router));
        _excludedFromStaking.add(_uniswapv2PairAddress);
        _excludedFromStaking.add(address(this));
        _excludedFromStaking.add(0x000000000000000000000000000000000000dEaD);
    
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
        
        //transfers between UniswapV2Router and UniswapV2Pair are tax and lock free
        address uniswapv2Router=address(_uniswapv2Router);
        bool isLiquidityTransfer = ((sender == _uniswapv2PairAddress && recipient == uniswapv2Router) 
        || (recipient == _uniswapv2PairAddress && sender == uniswapv2Router));

        //differentiate between buy/sell/transfer to apply different taxes/restrictions
        bool isBuy=sender==_uniswapv2PairAddress|| sender == uniswapv2Router;
        bool isSell=recipient==_uniswapv2PairAddress|| recipient == uniswapv2Router;

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
    //applies taxes, checks for limits, locks generates autoLP and stakingETH, and autostakes
    function _taxedTransfer(address sender, address recipient, uint256 amount,bool isBuy,bool isSell) private{
        uint256 recipientBalance = _balances[recipient];
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");

        uint8 tax;
        if(isSell){
            if(!_excludedFromSellLock.contains(sender)){
                 //If seller sold less than sellLockTime(2h 50m) ago, sell is declined, can be disabled by Team         
                require(_sellLock[sender]<=block.timestamp||sellLockDisabled,"Seller in sellLock");
                //Sets the time sellers get locked(2 hours 50 mins by default)
                _sellLock[sender]=block.timestamp+sellLockTime;
            }
            //Sells can't exceed the sell limit(21,000 Tokens at start, can be updated to circulating supply)
            require(amount<=sellLimit,"Dump protection");
            require(_isBlacklisted.contains(sender) == false, "Address blacklisted!");

            if (block.timestamp <= tradingEnabledAt + autoBanTime && enableAutoBlacklist == 1) {
                _isBlacklisted.add(sender);
                emit antiBotBan(sender);
            }

            tax=_sellTax;


        } else if(isBuy){
            if(!_excludedFromBuyLock.contains(recipient)){
                 //If buyer bought less than buyLockTime(2h 50m) ago, buy is declined, can be disabled by Team         
                require(_buyLock[recipient]<=block.timestamp||buyLockDisabled,"Buyer in buyLock");
                //Sets the time buyers get locked(2 hours 50 mins by default)
                _buyLock[recipient]=block.timestamp+buyLockTime;
            }
            //Checks If the recipient balance(excluding Taxes) would exceed Balance Limit
            require(recipientBalance+amount<=balanceLimit,"whale protection");
            require(amount <= MaxBuy,"Tx amount exceeding max buy amount");
            require(_isBlacklisted.contains(recipient) == false, "Address blacklisted!");

            if (block.timestamp <= tradingEnabledAt + autoBanTime && enableAutoBlacklist == 1) {
                _isBlacklisted.add(recipient);
                emit antiBotBan(recipient);
            }

            tax=_buyTax;

        } else {//Transfer
            //withdraws ETH when sending less or equal to 1 Token
            //that way you can withdraw without connecting to any dApp.
            //might needs higher gas limit
            if(amount<=10**(_decimals)) claimETH(sender);
            //Checks If the recipient balance(excluding Taxes) would exceed Balance Limit
            require(recipientBalance+amount<=balanceLimit,"whale protection");
            //Transfers are disabled in sell lock, this doesn't stop someone from transfering before
            //selling, but there is no satisfying solution for that, and you would need to pax additional tax
            if(!_excludedFromSellLock.contains(sender))
                require(_sellLock[sender]<=block.timestamp||sellLockDisabled,"Sender in Lock");
            
            require(_isBlacklisted.contains(sender) == false, "Sender address blacklisted!");
            require(_isBlacklisted.contains(recipient) == false, "Recipient address blacklisted!");

            if (block.timestamp <= tradingEnabledAt + autoBanTime && enableAutoBlacklist == 1) {
                _isBlacklisted.add(sender);
                emit antiBotBan(sender);
            }

            tax=_transferTax;

        }     
        //Swapping AutoLP and MarketingETH is only possible if sender is not uniswapv2 pair, 
        //if its not manually disabled, if its not already swapping and if its a Sell to avoid
        // people from causing a large price impact from repeatedly transfering when theres a large backlog of Tokens
        if((sender!=_uniswapv2PairAddress)&&(!manualConversion)&&(!_isSwappingContractModifier)&&isSell)
            _swapContractToken();
        //Calculates the exact token amount for each tax
        uint256 tokensToBeBurnt=_calculateFee(amount, tax, _burnTax);
        //staking and liquidity Tax get treated the same, only during conversion they get split
        uint256 contractToken=_calculateFee(amount, tax, _stakingTax+_liquidityTax);
        //Subtract the Taxed Tokens from the amount
        uint256 taxedAmount=amount-(tokensToBeBurnt + contractToken);

        //Removes token and handles staking
        _removeToken(sender,amount);
        
        //Adds the taxed tokens to the contract wallet
        _balances[address(this)] += contractToken;
        //Burns tokens
        _circulatingSupply-=tokensToBeBurnt;

        //Adds token and handles staking
        _addToken(recipient, taxedAmount);
        
        emit Transfer(sender,recipient,taxedAmount);

    }

    //Feeless transfer only transfers and autostakes
    function _feelessTransfer(address sender, address recipient, uint256 amount) private{
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        //Removes token and handles staking
        _removeToken(sender,amount);
        //Adds token and handles staking
        _addToken(recipient, amount);
        
        emit Transfer(sender,recipient,amount);

    }
    //Calculates the token that should be taxed
    function _calculateFee(uint256 amount, uint8 tax, uint8 taxPercent) private pure returns (uint256) {
        return (amount*tax*taxPercent) / 10000;
    }

     //ETH Autostake/////////////////////////////////////////////////////////////////////////////////////////
       //Autostake uses the balances of each holder to redistribute auto generated ETH.
    //Each transaction _addToken and _removeToken gets called for the transaction amount
    //WithdrawETH can be used for any holder to withdraw ETH at any time, like true Staking,
    //so unlike MRAT clones you can leave and forget your Token and claim after a while

    //lock for the withdraw
    bool private _isWithdrawing;
    //Multiplier to add some accuracy to profitPerShare
    uint256 private constant DistributionMultiplier = 2**64;
    //profit for each share a holder holds, a share equals a token.
    uint256 public profitPerShare;
    //the total reward distributed through staking, for tracking purposes
    uint256 public totalStakingReward;
    //the total payout through staking, for tracking purposes
    uint256 public totalPayouts;
    
  
    uint8 public marketingShare=100;
    //balance that is claimable by the team
    uint256 public marketingBalance;

    //Mapping of the already paid out(or missed) shares of each staker
    mapping(address => uint256) private alreadyPaidShares;
    //Mapping of shares that are reserved for payout
    mapping(address => uint256) private toBePaid;

    //Contract, uniswapv2 and burnAddress are excluded, other addresses like CEX
    //can be manually excluded, excluded list is limited to 30 entries to avoid a
    //out of gas exeption during sells
    function isExcludedFromStaking(address addr) public view returns (bool){
        return _excludedFromStaking.contains(addr);
    }

    //Check if address is blacklisted
    function isBlacklisted(address addr) public view returns (bool){
        return _isBlacklisted.contains(addr);
    }
    //Total shares equals circulating supply minus excluded Balances
    function _getTotalShares() public view returns (uint256){
        uint256 shares=_circulatingSupply;
        //substracts all excluded from shares, excluded list is limited to 30
        // to avoid creating a Honeypot through OutOfGas exeption
        for(uint i=0; i<_excludedFromStaking.length(); i++){
            shares-=_balances[_excludedFromStaking.at(i)];
        }
        return shares;
    }

    //adds Token to balances, adds new ETH to the toBePaid mapping and resets staking
    function _addToken(address addr, uint256 amount) private {
        //the amount of token after transfer
        uint256 newAmount=_balances[addr]+amount;
        
        if(isExcludedFromStaking(addr)){
           _balances[addr]=newAmount;
           return;
        }
        
        //gets the payout before the change
        uint256 payment=_newDividentsOf(addr);
        //resets dividents to 0 for newAmount
        alreadyPaidShares[addr] = profitPerShare * newAmount;
        //adds dividents to the toBePaid mapping
        toBePaid[addr]+=payment; 
        //sets newBalance
        _balances[addr]=newAmount;
    }
    
    
    //removes Token, adds ETH to the toBePaid mapping and resets staking
    function _removeToken(address addr, uint256 amount) private {
        //the amount of token after transfer
        uint256 newAmount=_balances[addr]-amount;
        
        if(isExcludedFromStaking(addr)){
           _balances[addr]=newAmount;
           return;
        }
        
        //gets the payout before the change
        uint256 payment=_newDividentsOf(addr);
        //sets newBalance
        _balances[addr]=newAmount;
        //resets dividents to 0 for newAmount
        alreadyPaidShares[addr] = profitPerShare * newAmount;
        //adds dividents to the toBePaid mapping
        toBePaid[addr]+=payment; 
    }
    
    
    //gets the not dividents of a staker that aren't in the toBePaid mapping 
    //returns wrong value for excluded accounts
    function _newDividentsOf(address staker) private view returns (uint256) {
        uint256 fullPayout = profitPerShare * _balances[staker];
        // if theres an overflow for some unexpected reason, return 0, instead of 
        // an exeption to still make trades possible
        if(fullPayout<alreadyPaidShares[staker]) return 0;
        return (fullPayout - alreadyPaidShares[staker]) / DistributionMultiplier;
    }

    //distributes eth between marketing share and dividents 
    function _distributeStake(uint256 ETHamount) private {
        // Deduct marketing Tax
        uint256 marketingSplit = (ETHamount * marketingShare) / 100;
        uint256 amount = ETHamount - marketingSplit;

       marketingBalance+=marketingSplit;
       
        if (amount > 0) {
            totalStakingReward += amount;
            uint256 totalShares=_getTotalShares();
            //when there are 0 shares, add everything to marketing budget
            if (totalShares == 0) {
                marketingBalance += amount;
            }else{
                //Increases profit per share based on current total shares
                profitPerShare += ((amount * DistributionMultiplier) / totalShares);
            }
        }
    }
    event OnWithdrawETH(uint256 amount, address recipient);
    
    //withdraws all dividents of address
    function claimETH(address addr) private{
        require(!_isWithdrawing);
        _isWithdrawing=true;
        uint256 amount;
        if(isExcludedFromStaking(addr)){
            //if excluded just withdraw remaining toBePaid ETH
            amount=toBePaid[addr];
            toBePaid[addr]=0;
        }
        else{
            uint256 newAmount=_newDividentsOf(addr);
            //sets payout mapping to current amount
            alreadyPaidShares[addr] = profitPerShare * _balances[addr];
            //the amount to be paid 
            amount=toBePaid[addr]+newAmount;
            toBePaid[addr]=0;
        }
        if(amount==0){//no withdraw if 0 amount
            _isWithdrawing=false;
            return;
        }


        totalPayouts+=amount;
        address[] memory path = new address[](2);
        path[0] = _uniswapv2Router.WETH(); //ETH
        path[1] = RewardsAddress; //@dev Marketing Share can contribute to Rewards if allocated. Define by editing RewardsAddress=(?)

        _uniswapv2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
        0,
        path,
        addr,
        block.timestamp);
        
        emit OnWithdrawETH(amount, addr);
        _isWithdrawing=false;
    }
        //Launch Rewards Address - Can be Changed - Rewards not enabled at launch.
    address public RewardsAddress=(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); //@ this is the address for USDC USDC
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
    uint256 currentAmountToSwap = 4000 * 10**_decimals;  // 4,000 tokens (0.4%)
    //swaps the token on the contract for Marketing ETH and LP Token.
    //always swaps the sellLimit of token to avoid a large price impact
    function _swapContractToken() private lockTheSwap{
        uint256 contractBalance=_balances[address(this)];
        uint16 totalTax=_liquidityTax+_stakingTax;
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
        //Gets the initial ETH balance, so swap won't touch any staked ETH
        uint256 initialETHBalance = address(this).balance;
        _swapTokenForETH(swapToken);
        uint256 newETH=(address(this).balance - initialETHBalance);
        //calculates the amount of ETH belonging to the LP-Pair and converts them to LP
        uint256 liqETH = (newETH*liqETHToken)/swapToken;
        _addLiquidity(liqToken, liqETH);
        //Get the ETH balance after LP generation to get the
        //exact amount of token left for Staking
        uint256 distributeETH=(address(this).balance - initialETHBalance);
        //distributes remaining ETH between stakers and Marketing
        _distributeStake(distributeETH);
    }
    //swaps tokens on the contract for ETH
    function _swapTokenForETH(uint256 amount) private {
        _approve(address(this), address(_uniswapv2Router), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapv2Router.WETH();

        _uniswapv2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    //Adds Liquidity directly to the contract where LP are locked(unlike safemoon forks, that transfer it to the owner)
    function _addLiquidity(uint256 tokenamount, uint256 ethamount) private {
        totalLPETH+=ethamount;
        _approve(address(this), address(_uniswapv2Router), tokenamount);
        _uniswapv2Router.addLiquidityETH{value: ethamount}(
            address(this),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    //public functions /////////////////////////////////////////////////////////////////////////////////////

    function getLiquidityReleaseTimeInSeconds() public view returns (uint256){
        if(block.timestamp<_liquidityUnlockTime){
            return _liquidityUnlockTime-block.timestamp;
        }
        return 0;
    }

    function getBurnedTokens() public view returns(uint256){
        return (InitialSupply-_circulatingSupply)/10**_decimals;
    }

    function getLimits() public view returns(uint256 balance, uint256 sell){
        return(balanceLimit/10**_decimals, sellLimit/10**_decimals);
    }

    function getTaxes() public view returns(uint256 burnTax,uint256 liquidityTax,uint256 marketingTax, uint256 buyTax, uint256 sellTax, uint256 transferTax){
        return (_burnTax,_liquidityTax,_stakingTax,_buyTax,_sellTax,_transferTax);
    }

    //How long is a given address still locked from selling
    //function getAddressSellLockTimeInSeconds(address AddressToCheck) public view returns (uint256){
    //   uint256 lockTime=_sellLock[AddressToCheck];
    //   if(lockTime<=block.timestamp)
    //   {
    //       return 0;
    //   }
    //   return lockTime-block.timestamp;
    //}
    //function getSellLockTimeInSeconds() public view returns(uint256){
    //    return sellLockTime;
    //}
    
    function getcurrentAmountToSwap() public view returns (uint256){
          return currentAmountToSwap;
    }

    //How long is a given address still locked from buying - not used
    //function getAddressBuyLockTimeInSeconds(address AddressToCheck) public view returns (uint256){
    //   uint256 lockTime=_buyLock[AddressToCheck];
    //   if(lockTime<=block.timestamp)
    //   {
    //       return 0;
    //   }
    //   return lockTime-block.timestamp;
    //}
    //function getBuyLockTimeInSeconds() public view returns(uint256){
    //    return buyLockTime;
    //}
    
    //Functions every wallet can call - no sell lock in isde
    //Resets sell lock of caller to the default sellLockTime should something go very wrong
    //function AddressResetSellLock() public{
    //    _sellLock[msg.sender]=block.timestamp+sellLockTime;
    //}
    
    //Resets buy lock of caller to the default buyLockTime should something go very wrong - no buy lock in usde
 //   function AddressResetBuyLock() public{
 //       _buyLock[msg.sender]=block.timestamp+buyLockTime;
    
 //   }

        //withdraws dividents of sender
    function Rewards() public{
        claimETH(msg.sender);
    }

    function getDividents(address addr) public view returns (uint256){
        if(isExcludedFromStaking(addr)) return toBePaid[addr];
        return _newDividentsOf(addr)+toBePaid[addr];
    }

    //Settings//////////////////////////////////////////////////////////////////////////////////////////////
 
    bool public sellLockDisabled;
    uint256 public sellLockTime;
    bool public buyLockDisabled;
    uint256 public buyLockTime;
    bool public manualConversion; 

    function CollectMarketingETH() public onlyOwner{
        uint256 amount=marketingBalance;
        marketingBalance=0;
        payable(Development).transfer((amount*50) / 100);
        payable(Marketing).transfer((amount*50) / 100);
    } 
    function TeamCollectXMarketingETH(uint256 amount) public onlyOwner{
        require(amount<=marketingBalance);
        marketingBalance-=amount;
        payable(Development).transfer((amount*50) / 100);
        payable(Marketing).transfer((amount*50) / 100);
    } 

    //switches autoLiquidity and marketing ETH generation during transfers
    function TeamSwitchManualETHConversion(bool manual) public onlyOwner{
        manualConversion=manual;
    }
    
    function TeamChangeMaxBuy(uint256 newMaxBuy) public onlyOwner{
      MaxBuy=newMaxBuy * 10**_decimals;
    }
    
    function TeamChangeDevelopment(address newDevelopment) public onlyOwner{
      Development=payable(newDevelopment);
    }

    function TeamChangeMarketing(address newMarketing) public onlyOwner{
      Marketing=payable(newMarketing);
    }

    function TeamChangeRewardsAddress(address newRewardsAddress) public onlyOwner{
      RewardsAddress=(newRewardsAddress);
    }

    function updateTokenDetails(string memory newName, string memory newSymbol) public onlyOwner {
        _name = newName;
        _symbol = newSymbol;
    }



    //Disables the timeLock after selling for everyone
    function TeamDisableSellLock(bool disabled) public onlyOwner{
        sellLockDisabled=disabled;
    }
    
    //Disables the timeLock after buying for everyone
    function TeamDisableBuyLock(bool disabled) public onlyOwner{
        buyLockDisabled=disabled;
    }

    //Sets SellLockTime, needs to be lower than MaxSellLockTime
    function TeamSetSellLockTime(uint256 sellLockSeconds)public onlyOwner{
            require(sellLockSeconds<=MaxSellLockTime,"Sell Lock time too high");
            sellLockTime=sellLockSeconds;
    } 
    
    //Sets BuyLockTime, needs to be lower than MaxBuyLockTime
    function TeamSetBuyLockTime(uint256 buyLockSeconds)public onlyOwner{
            require(buyLockSeconds<=MaxBuyLockTime,"Buy Lock time too high");
            buyLockTime=buyLockSeconds;
    } 

    //Allows CA owner to change how much the contract sells to prevent massive contract sells as the token grows.
    function TeamUpdateAmountToSwap(uint256 newSwapAmount) public onlyOwner{
        currentAmountToSwap = newSwapAmount;
    }
    
    //Allows wallet exclusion to be added after launch
    function AddWalletExclusion(address exclusionAdd) public onlyOwner{
        _excluded.add(exclusionAdd);
    }
    
    //Sets Taxes
    function TeamSetTaxes(uint8 burnTaxes, uint8 liquidityTaxes, uint8 stakingTaxes,uint8 buyTax, uint8 sellTax, uint8 transferTax) public onlyOwner{
        uint8 totalTax=burnTaxes+liquidityTaxes+stakingTaxes;
        require(totalTax==100, "burn+liq+marketing needs to equal 100%");

        _burnTax=burnTaxes;
        _liquidityTax=liquidityTaxes;
        _stakingTax=stakingTaxes;
        
        _buyTax=buyTax;
        _sellTax=sellTax;
        _transferTax=transferTax;
    }

    //How much of the staking tax should be allocated for marketing
    function TeamChangeMarketingShare(uint8 newShare) public onlyOwner{
        require(newShare<=100); 
        marketingShare=newShare;
    }
    //manually converts contract token to LP and staking ETH
    function TeamCreateLPandETH() public onlyOwner{
    _swapContractToken();
    }
    
     //Limits need to be at least target, to avoid setting value to 0(avoid potential Honeypot)
    function TeamUpdateLimits(uint256 newBalanceLimit, uint256 newSellLimit) public onlyOwner{
        //SellLimit needs to be below 1% to avoid a Large Price impact when generating auto LP
        require(newSellLimit<_circulatingSupply/100);
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
    }

    //Adds address to blacklist and prevents sells, buys or transfers.
    function addAddressToBlacklist(address blacklistedAddress) external onlyOwner {
        _isBlacklisted.add(blacklistedAddress);
    }

    //Remove address from blacklist and allow sells, buys or transfers.
    function removeAddressFromBlacklist(address blacklistedAddress) external onlyOwner {
        _isBlacklisted.remove(blacklistedAddress);
    }
    
    //Setup Functions///////////////////////////////////////////////////////////////////////////////////////
    
    bool public tradingEnabled;
    address private _liquidityTokenAddress;
    //Enables trading for everyone
    function SetupEnableTrading() public onlyOwner{
        tradingEnabled=true;
        tradingEnabledAt=block.timestamp;
    }

    //Sets up the LP-Token Address required for LP Release
    function SetupLiquidityTokenAddress(address liquidityTokenAddress) public onlyOwner{
        _liquidityTokenAddress=liquidityTokenAddress;
    }

    //Liquidity Lock////////////////////////////////////////////////////////////////////////////////////////
    //the timestamp when Liquidity unlocks
    uint256 private _liquidityUnlockTime;

    function TeamExtendLiquidityLock(uint256 secondsUntilUnlock) public onlyOwner{
        _prolongLiquidityLock(secondsUntilUnlock+block.timestamp);
    }
    function _prolongLiquidityLock(uint256 newUnlockTime) private{
        // require new unlock time to be longer than old one
        require(newUnlockTime>_liquidityUnlockTime);
        _liquidityUnlockTime=newUnlockTime;
    }

    //Release Liquidity Tokens once unlock time is over
    function REL() public onlyOwner {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        
        IUniswapV2ERC20 liquidityToken = IUniswapV2ERC20(_liquidityTokenAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));

        //Liquidity release if something goes wrong at start
        liquidityToken.transfer(Development, amount);
        
    }
    //Removes Liquidity once unlock Time is over, 
    function REM(bool addToStaking) public onlyOwner{
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;
        IUniswapV2ERC20 liquidityToken = IUniswapV2ERC20(_liquidityTokenAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));

        liquidityToken.approve(address(_uniswapv2Router),amount);
        //Removes Liquidity and either distributes liquidity ETH to stakers, or 
        // adds them to marketing Balance
        //Token will be converted
        //to Liquidity and Staking ETH again
        uint256 initialETHBalance = address(this).balance;
        _uniswapv2Router.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            amount,
            0,
            0,
            address(this),
            block.timestamp
            );
        uint256 newETHBalance = address(this).balance-initialETHBalance;
        if(addToStaking){
            _distributeStake(newETHBalance);
        }
        else{
            marketingBalance+=newETHBalance;
        }

    }
    //Releases all remaining ETH on the contract wallet, so ETH wont be burned
    function TeamCollectRemainingETH() public onlyOwner{
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;
        (bool sent,) =Development.call{value: (address(this).balance)}("");
        require(sent);
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //external//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    receive() external payable {}
    fallback() external payable {}
    // IERC20

    function getOwner() external view override returns (address) {
        return owner();
    }

    function name() external view override returns (string memory) { 
        return _name; 
    }
    function symbol() external view override returns (string memory) 
    { return _symbol; 
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

    // IERC20 - Helpers

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