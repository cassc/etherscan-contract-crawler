/**
 *Submitted for verification at Etherscan.io on 2023-10-20
*/

// SPDX-License-Identifier: MIT


/**
 * -----------------------------------------------------------------------------
 *                                  Prometheum Prodigy
 * -----------------------------------------------------------------------------
 *
 * Welcome to the official smart contract of Prometheum Prodigy Token!
 *
 * This contract manages the transactions, balances, and functionalities
 * of the Prometheum Prodigy Token within the Ethereum Blockchain.
 *
 * For more information, please visit our official website.
 *
 */

pragma solidity ^0.8.0;

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

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin\contracts\utils\Address.sol


pragma solidity ^0.8.1;

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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// File: @openzeppelin\contracts\access\Ownable.sol


pragma solidity ^0.8.0;

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

// File: contracts\reflect.sol


pragma solidity ^0.8.18;


contract PrometheumProdigy is Context, IERC20, Ownable {
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    // excluded from reflections
    mapping (address => bool) public _isExcluded;
    mapping (address => bool) public _isExcludedFromFees;
    mapping (address => bool) public _isExcludedFromMax;

    address[] public _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private  _tTotal = 1000000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 private _tReflectTotal;

    uint256 public reflectRate = 2;
    uint256 public feeRate = 5;

    uint256 public maxTransfer;
    bool public maxTransferEnabled = false;

    bool public isPaused;
    bool public feesEnabled;

    address public dev;

    string private constant _name = 'Prometheum Prodigy';
    string private constant _symbol = 'PMPY';
    uint8 private constant _decimals = 18;

    constructor (address _toMint, address _dev) public Ownable() {
        _rOwned[_toMint] = _rTotal;
        dev = _dev;
        excludeAccount(_toMint);
        excludeAccount(_dev);
        excludeAccount(address(0));
        excludeFromMax(_toMint);
        excludeFromMax(_dev);
        excludeFromFees(_toMint);
        excludeFromFees(_dev);
        excludeFromFees(address(this));
        excludeFromFees(address(0));
        emit Transfer(address(0), _toMint, _tTotal);
    }

    /**
    * @dev Returns the name of the token.
    */
    function name() public pure returns (string memory) {
        return _name;
    }

    /**
    * @dev Returns the symbol of the token.
    */
    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the decimals of the token.
    */
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    /**
    * @dev returns total supply in the tSpace
    */
    function totalSupply() public view override returns (uint256) {
        return _tTotal - balanceOf(address(0));
    }

    /**
    * @dev Returns rTotal.
    * @dev rTotal began as a large multiple of tTotal, it decreases every time reflections are collected
    */
    function rTotal() public view returns (uint256) {
        return _rTotal;
    }

    /**
    * @dev returns balance in the tSpace (the "regular" balance).
    * @dev is calculated fro rOwned if account is not excluded
    */
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    /**
    * @dev returns balance in the rSpace.
    * @dev This value is always converted to tOwned for practical use
    */
    function rOwned(address account) public view returns (uint256) {
        return _rOwned[account];
    }

    /**
    * @dev Transfers `amount` tokens from the caller's account to `recipient`.
    * @param recipient The address to receive the tokens.
    * @param amount The amount of tokens to send.
    * @return A boolean value indicating whether the operation succeeded.
    */
    function transfer(address recipient, uint256 amount) public override checkPause returns (bool) {
        require(balanceOf(_msgSender()) >= amount, "ERC20: Insufficient Funds");
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

    /**
    * @dev Moves tokens `amount` from `sender` to `recipient`.
    * @param sender The address to send tokens from.
    * @param recipient The address to receive the tokens.
    * @param amount The amount of tokens to send.
    * @return A boolean value indicating whether the operation succeeded.
    */
    function transferFrom(address sender, address recipient, uint256 amount) public override checkPause returns (bool) {
        require(balanceOf(sender) >= amount, "ERC20: Insufficient Funds");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    /**
    * @dev displays if an account is excluded from receiving reflections
    */
    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    /**
    * @dev returns total amount of tokens reflected
    */
    function totalReflections() public view returns (uint256) {
        return _tReflectTotal;
    }

    /**
    * @dev Performs a reflection of `tAmount` tokens.
    * @dev The caller must hold at least `tAmount` tokens.
    * @dev these tokens are redistributed to all included holders
    * @param tAmount Amount of tokens to reflect.
    */
    function reflect(uint256 tAmount) public checkPause {
        address sender = _msgSender();

        require(balanceOf(sender) >= tAmount, "ERC20: Insufficient Funds");
        require(tAmount > 0, "value must be greater than 0");
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount, false);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rTotal = _rTotal - rAmount;
        _tReflectTotal = _tReflectTotal + tAmount;
    }

    /**
    * @dev converts a tAmount into its rAmount equivalent
    * @dev includes option to deduct fees
    * @param tAmount the amount of tokens in the t space
    * @param deductTransferFee a flag indicating if taxes should be deducted from final amount
    */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount, false);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount, true);
            return rTransferAmount;
        }
    }

    /**
    * @dev calculates t space token amount from an r space value
    * @param rAmount the r-space value of tokens
    */
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function burn(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Can't burn");
        _burn(msg.sender, amount);
    }

    function _burn(address sender, uint256 amount) internal {
        if (_isExcluded[sender]) {
            _transferBothExcluded(sender, address(0), amount, false);
        } else {
            _transferToExcluded(sender, address(0), amount, false);
        }
    }

    /**
    * @dev Internal transfer functions. Selects the correct transfer based on exclusion of participants
    * @param sender The address to send tokens from.
    * @param recipient The address to receive the tokens.
    * @param amount The amount of tokens to send.
    */
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(amount >= 100, "Transfer amount must be greater than 100");

        if (recipient == address(0)) {
            //BURN TIME!
            _burn(sender, amount);
            return;
        }

        bool addFees = true;

        if (!feesEnabled) {
            addFees = false;
        } else if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            addFees = false;
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount, addFees);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount, addFees);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount, addFees);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount, addFees);
        } else {
            _transferStandard(sender, recipient, amount, addFees);
        }
    }

    /**
    * @dev Internal function that transfers tokens according to exclusion rules.
    * @dev Is called when neither sendor nor receiver are excluded
    * @param sender The address to send tokens from.
    * @param recipient The address to receive the tokens.
    * @param tAmount The amount of tokens to send.
    */
    function _transferStandard(address sender, address recipient, uint256 tAmount, bool _fees) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 rReflect, uint256 tReflect) = _getValues(tAmount, _fees);
        // balance limit
        if (maxTransferEnabled && !_isExcludedFromMax[recipient]) {
            require(tAmount <= maxTransfer, "balance exceeds limit");
        }

        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        if (_fees) {
            _reflectFee(rReflect, tReflect);
            _addToDev(rFee, tFee, sender);

        }
        emit Transfer(sender, recipient, tTransferAmount);



    }

    /**
    * @dev Internal function that transfers when only the receiver is excluded from reflections.
    * @param sender The address to send tokens from.
    * @param recipient The address to receive the tokens.
    * @param tAmount The amount of tokens to send.
    */
    function _transferToExcluded(address sender, address recipient, uint256 tAmount, bool _fees) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 rReflect, uint256 tReflect) = _getValues(tAmount, _fees);
        // balance limit
        if (maxTransferEnabled && !_isExcludedFromMax[recipient]) {
            require(tAmount <= maxTransfer, "balance exceeds limit");
        }

        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        // Add to totalExcluded;
        if (_fees) {
            _reflectFee(rReflect, tReflect);
            _addToDev(rFee, tFee, sender);

        }

        emit Transfer(sender, recipient, tTransferAmount);

    }

    /**
    * @dev Internal function that transfers when only the sender is excluded from reflections.
    * @param sender The address to send tokens from.
    * @param recipient The address to receive the tokens.
    * @param tAmount The amount of tokens to send.
    */
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount, bool _fees) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 rReflect, uint256 tReflect) = _getValues(tAmount, _fees);
        // balance limit
        if (maxTransferEnabled && !_isExcludedFromMax[recipient]) {
            require(tAmount <= maxTransfer, "balance exceeds limit");
        }

        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        // remove from totalExcluded;
        if (_fees) {
            _reflectFee(rReflect, tReflect);
            _addToDev(rFee, tFee, sender);

        }

        emit Transfer(sender, recipient, tTransferAmount);

    }

    /**
    * @dev Internal function that transfers when both sender and receiver are excluded from reflections.
    * @notice taxes are omitted in this scenario only
    * @param sender The address to send tokens from.
    * @param recipient The address to receive the tokens.
    * @param tAmount The amount of tokens to send.
    */
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount, bool _fees) private {

        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 rReflect, uint256 tReflect) = _getValues(tAmount, _fees);
        // balance limit
        if (maxTransferEnabled && !_isExcludedFromMax[recipient]) {
            require(tAmount <= maxTransfer, "balance exceeds limit");
        }
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        if (_fees) {
            // remove from totalExcluded;
            _reflectFee(rReflect, tReflect);
            _addToDev(rFee, tFee, sender);


        }
        // if fees are not applied, amount = transferAmount, therefore tExcluded and rExcluded does not chage
        emit Transfer(sender, recipient, tTransferAmount);

    }

    /**
    * @dev Adds the fee to the dev account.
    * @param rFee The fee amount in r space.
    * @param tFee The fee amount in t space.
    */
    function _addToDev(uint256 rFee, uint256 tFee, address sender) internal {
        address _dev = dev;
        if (_isExcluded[_dev]) {
            _tOwned[_dev] = _tOwned[_dev] + tFee;
        }
        _rOwned[_dev] = _rOwned[_dev] + rFee;
        emit Transfer(sender, _dev, tFee);

    }

    /**
    * @dev subtracts rReflect from rTotal to distribute reflections to all holders via deflationary mechanism
    */
    function _reflectFee(uint256 rReflect, uint256 tReflect) private {
        _rTotal = _rTotal - rReflect;
        _tReflectTotal = _tReflectTotal + tReflect;
    }

    /**
    * @dev Calculates and returns values related to transactions and reflections.
    * @param tAmount The amount of tokens.
    * @return The calculated values.
    */
    function _getValues(uint256 tAmount, bool _fees) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tReflect) = _getTValues(tAmount, _fees);
        uint256 currentRate =  _getRate();
        // (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rReflect) = _getRValues(tAmount, tFee, currentRate, tReflect);
        uint256[4] memory tItems = [tAmount, tFee, tReflect, currentRate];
        uint256[4] memory rValues = _getRValues( tItems, _fees);

        //      rAmount   , rTransferAmount, rFee,  , tTransfer,     tFee, rReflect
        return (rValues[0], rValues[3], rValues[1], tTransferAmount, tFee, rValues[2], tReflect);
    }

    /**
    * @dev returns devFee amount, reflect amount, and final transfer amount, all in the tSpace. Calculated from tAmount
    */
    function _getTValues(uint256 tAmount, bool _fees) private view returns (uint256, uint256, uint256) {
        uint256 tFee = 0;
        uint256 tReflect = 0;
        uint256 tTransferAmount = tAmount;
        if (_fees)  {
            tFee = tAmount * feeRate / 100;
            tReflect = tAmount * reflectRate / 100;
            tTransferAmount = tTransferAmount - tFee - tReflect;
        }

        return (tTransferAmount, tFee, tReflect);
    }

    /**
    * @dev returns values in the rSpace calculated from tSpace inputs
    */
    // items[0] = tAmount, items[1] = tFee, items[2] = tReflect items[3] = currentRate
    function _getRValues(uint256[4] memory items, bool _fees) private pure returns (uint256[4] memory results) {
        // rAmount
        results[0] = items[0] * items[3];

        if (!_fees) {


            // rFee
            results[1] = 0;

            // rReflect
            results[2] = 0;

            // rTransferAmount
            results[3] = results[0];
        } else {
            // rFee
            results[1] = items[1] * items[3];

            // rReflect
            results[2] = items[2] * items[3];

            // rTransferAmount
            results[3] = results[0] - results[1] - results[2];
        }


    }

    /**
     * @dev Calculates the current reflection rate based on the total supply and reflection supply.
     * @return The current reflection rate.
     */
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    /**
     * @dev Calculates the current reflection supply and token supply, considering excluded addresses.
     * @return The current reflection supply and token supply.
     */
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply)
                return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    // Owner Functions

    /**
    * @dev flips the feesEnabled flag. If false, all fees are omitted from transfers
    */
    function flipFees() external onlyOwner {
        feesEnabled = !feesEnabled;
    }

    /**
    * @dev changes address of "dev" account that collects fee
    * @param newDev address of fee collection account
    */
    function changeDev(address newDev) external onlyOwner {
        require(newDev != address(0), "invalid");
        dev = newDev;
    }

    /**
    * @dev enables and sets a maximum holder balance
    * @param _max the maximum amount an account can hold.
    */
    function enableMaxTransfer(uint256 _max) external onlyOwner {
        maxTransfer = _max;
        maxTransferEnabled = true;

        require(maxTransfer >= _tTotal / 1000, "Invalid");
    }

     /**
     * @dev Disables the maximum balance restriction
     */
    function disableMaxTransfer() external onlyOwner {
        maxTransferEnabled = false;
    }

     /**
     * @dev updates the distribution of taxes.
     * @notice both params must add to 100. only whole percentages supported
     * @param newFee updates the dev fee percentage.
     * @param newReflect updates the reflection percentage
     */
    function changeTaxes(uint256 newFee, uint256 newReflect) external onlyOwner {
        require(newFee > 0 && newReflect > 0 && newFee + newReflect <= 10, "Invalid");
        feeRate = newFee;
        reflectRate = newReflect;
    }

    /**
     * @dev Excludes an account from fee and reflection calculations, used for special addresses like owners and liquidity pools.
     * @param account Address to be excluded.
     */
    function excludeAccount(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }

        _isExcluded[account] = true;
        _excluded.push(account);
    }

     /**
     * @dev Includes an account back into fee and reflection calculations.
     * @param account Address to be included.
     */
    function includeAccount(address account) external onlyOwner() {
        require(account != address(0), "cannot include burn address");
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

    function excludeFromFees(address user) public onlyOwner {
        _isExcludedFromFees[user] = true;
    }

    function excludeFromMax(address user) public onlyOwner {
        _isExcludedFromMax[user] = true;
    }

    function includeToFees(address user) public onlyOwner {
        _isExcludedFromFees[user] = false;
    }

    function includeToMax(address user) public onlyOwner {
        _isExcludedFromMax[user] = false;
    }

    /**
     * @dev Pauses movement of tokens if isPaused is true
     */
    function flipPause() external onlyOwner() {
        isPaused = !isPaused;
    }

    // modifiers
    modifier checkPause() {
        require(!isPaused, "Cannot move tokens at this time");
        _;
    }
}