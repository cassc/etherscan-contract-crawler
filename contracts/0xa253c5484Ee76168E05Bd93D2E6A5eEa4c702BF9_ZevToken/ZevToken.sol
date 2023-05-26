/**
 *Submitted for verification at Etherscan.io on 2023-05-22
*/

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

interface IERC20Metadata is IERC20{
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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

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

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
}


contract TokenHandler is Ownable {
    function sendTokenToOwner(address token) external onlyOwner {
        if(IERC20(token).balanceOf(address(this)) > 0){
            SafeERC20.safeTransfer(IERC20(token),owner(), IERC20(token).balanceOf(address(this)));
        }
    }
}

interface IWETH {
    function deposit() external payable; 
}

interface ILpPair {
    function sync() external;
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract ZevToken is ERC20, Ownable {

    mapping (address => bool) public exemptFromFees;
    mapping (address => bool) public exemptFromLimits;

    uint256 public launchTime_;
    bool public allowEarlyZ3Buyers_;
    mapping (address => bool) verifiedAddress;
    uint256 public constant verificationDuration = 20 minutes;
    uint256 public constant z3BuyerDuration = 2 minutes;

    mapping (address => bool) public isAMMPair;

    IERC20Metadata public immutable Z3TOKEN;

    uint256 public maxTransaction;
    uint256 public maxWallet;

    address public projectAddress;
    address public zentinelAddress;

    uint256 public buyTotalTax;
    uint256 public buyProjectTax;
    uint256 public buyLiquidityTax;
    uint256 public buyBurnTax;

    uint256 public initialBuyTax;

    uint256 public sellTotalTax;
    uint256 public sellProjectTax;
    uint256 public sellLiquidityTax;
    uint256 public sellBurnTax;
    
    uint256 public initialSellTax;

    uint256 public tokensForProject;
    uint256 public tokensForLiquidity;
    uint256 public tokensForBurn;
    
    TokenHandler public immutable tokenHandler;

    bool public limitsInEffect = true;
    bool public lpAdded;

    bool private swapping;
    uint256 public swapTokensAtAmt;

    address public lpPair;
    IDexRouter public dexRouter;
    IERC20Metadata public pairedToken;
    IWETH public WETH;

    // events

    event UpdatedMaxTransaction(uint256 newMax);
    event UpdatedMaxWallet(uint256 newMax);
    event SetExemptFromFees(address _address, bool _isExempt);
    event SetExemptFromLimits(address _address, bool _isExempt);
    event RemovedLimits();
    event UpdatedBuyTax(uint256 newAmt);
    event UpdatedSellTax(uint256 newAmt);

    // constructor

    constructor(StructsLibrary.CreationParams memory params, address _zentinel)
        
        ERC20(params._name, params._symbol)
    {
        _mint(msg.sender, params._supply);
        Z3TOKEN = IERC20Metadata(params._Z3TOKEN);
        

        zentinelAddress = _zentinel;

        launchTime_ = params._launchTime;
        allowEarlyZ3Buyers_ = params._allowZ3EarlyBuyers;

        maxTransaction = totalSupply() * params._maxTransaction / 10000;
        maxWallet = totalSupply() * params._maxWallet / 10000;
        swapTokensAtAmt = totalSupply() * 5 / 10000;

        projectAddress = params._projectAddress;

        if(params._buyTaxes.length == 3){
            buyProjectTax = params._buyTaxes[0];
            buyLiquidityTax = params._buyTaxes[1];
            buyBurnTax = params._buyTaxes[2];
            buyTotalTax = buyProjectTax + buyLiquidityTax + buyBurnTax;
            initialBuyTax = buyTotalTax;
            require(initialBuyTax <= 8, "Tax too high");
        }

        if(params._sellTaxes.length == 3){
            sellProjectTax = params._sellTaxes[0];
            sellLiquidityTax = params._sellTaxes[1];
            sellBurnTax = params._sellTaxes[2];
            sellTotalTax = sellProjectTax + sellLiquidityTax + sellBurnTax;
            initialSellTax = sellTotalTax;
            require(initialSellTax <= 8, "Tax too high");
        }

        pairedToken = IERC20Metadata(params._pairedToken);
        require(pairedToken.decimals()  > 0 , "Incorrect liquidity token");

        tokenHandler = new TokenHandler();
        dexRouter = IDexRouter(params._router);
        lpPair = IDexFactory(dexRouter.factory()).createPair(address(this), address(pairedToken));

        WETH = IWETH(dexRouter.WETH());
        isAMMPair[lpPair] = true;

        exemptFromLimits[lpPair] = true;
        exemptFromLimits[address(this)] = true;
        exemptFromLimits[address(0xdead)] = true;

        exemptFromFees[msg.sender] = true;
        exemptFromFees[address(this)] = true;
        exemptFromLimits[address(0xdead)] = true;

        _approve(address(owner()), address(dexRouter), totalSupply());
        _approve(address(this), address(dexRouter), type(uint256).max);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        
        if(limitsInEffect){
            checkLimits(from, to, amount);
        }

        if(!exemptFromFees[from] && !exemptFromFees[to]){
            amount -= handleTax(from, to, amount);
        }

        super._transfer(from,to,amount);
    }

    function checkLimits(address from, address to, uint256 amount) internal {
        if(!lpAdded && from == owner() && to == lpPair){
            lpAdded = true;
            return;
        }

        if(!exemptFromFees[from] && !exemptFromFees[to]){
            require(block.timestamp >= launchTime_, "Not Launched Yet");
        }
        
        if(allowEarlyZ3Buyers_ && block.timestamp <= launchTime_ + z3BuyerDuration){
            checkZ3Eligible(to, amount); 
        }

        if(!isAMMPair[to] && block.timestamp <= launchTime_ + verificationDuration){
            require(verifiedAddress[to] && to == tx.origin, "Buy via Zev dapp only");
        }

        // buy
        if (isAMMPair[from] && !exemptFromLimits[to]) {
            require(amount <= maxTransaction, "Max Tx exceeded");
            require(amount + balanceOf(to) <= maxWallet, "Max Wallet Exceeded");
        } 
        // sell
        else if (isAMMPair[to] && !exemptFromLimits[from]) {
            require(amount <= maxTransaction, "Max Tx exceeded");
        }
        else if(!exemptFromLimits[to]) {
            require(amount + balanceOf(to) <= maxWallet, "Max Wallet Exceeded");
        }
    }

    function handleTax(address from, address to, uint256 amount) internal returns (uint256){
        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmt;

        if(canSwap && !swapping && isAMMPair[to]) {
            swapBack();
        }
        
        uint256 tax = 0;

        // on sell
        if (isAMMPair[to] && sellTotalTax > 0){
            tax = amount * sellTotalTax / 100;
            tokensForLiquidity += tax * sellLiquidityTax / sellTotalTax;
            tokensForProject += tax * sellProjectTax / sellTotalTax;
            tokensForBurn += tax * sellBurnTax / sellTotalTax;
        }

        // on buy
        else if(isAMMPair[from] && buyTotalTax > 0) {
            tax = amount * buyTotalTax / 100;
            tokensForProject += tax * buyProjectTax / buyTotalTax;
            tokensForLiquidity += tax * buyLiquidityTax / buyTotalTax;
            tokensForBurn += tax * buyBurnTax / buyTotalTax;
        }
        
        if(tax > 0){    
            super._transfer(from, address(this), tax);
        }
        
        return tax;
    }

    function swapTokensForPAIREDTOKEN(uint256 tokenAmt) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(pairedToken);

        // make the swap
        dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmt,
            0, // accept any amt of ETH
            path,
            address(tokenHandler),
            block.timestamp
        );

        tokenHandler.sendTokenToOwner(address(pairedToken));
    }

    function swapBack() private {

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForProject + tokensForBurn;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmt * 40){
            contractBalance = swapTokensAtAmt * 40;
        }
        
        if(tokensForLiquidity > 0){
            uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap;
            super._transfer(address(this), lpPair, liquidityTokens);
            try ILpPair(lpPair).sync(){} catch {}
            contractBalance -= liquidityTokens;
            totalTokensToSwap -= tokensForLiquidity;
            tokensForLiquidity = 0;
        }

        if(tokensForBurn > 0){
            uint256 burnTokens = contractBalance * tokensForBurn / totalTokensToSwap;
            super._transfer(address(this), address(0xdead), burnTokens);
            contractBalance -= burnTokens;
            totalTokensToSwap -= burnTokens;
            tokensForBurn = 0;
        }

        tokensForProject = 0;
        
        if(totalTokensToSwap > 0){
            swapTokensForPAIREDTOKEN(contractBalance);
            
            if(pairedToken.balanceOf(address(this)) > 0){
                SafeERC20.safeTransfer(pairedToken, projectAddress, pairedToken.balanceOf(address(this)));
            }
        }
    }


    // views

    function checkZ3Eligible(address holder, uint256 amountRequestedTobuy) internal view {
        require(amountRequestedTobuy <= maxBuyForZ3HolderAtLaunch(holder), "Too much"); 
    }
    
    function maxBuyForZ3HolderAtLaunch(address holder) public view returns (uint256) { // Can buy up to 10% of relative Z3 holdsings.  i.e. if you hold 1% of Z3, you can buy 0.1% of token in advance.
        uint256 holderZ3Percent = Z3TOKEN.balanceOf(holder) * 10000 / Z3TOKEN.totalSupply();
        uint256 currentHoldings = balanceOf(holder);
        uint256 maxWalletForLaunch = holderZ3Percent * totalSupply() / 100000;
        return (maxWalletForLaunch - currentHoldings);
    }

    // Zentinel Function
    function setVerified(address _address) external onlyZentinel {
        verifiedAddress[_address] = true;
    }

    // owner functions

    function setExemptFromFees(address _address, bool _isExempt) external ownerCanChange {
        require(_address != address(0), "Zero Address");
        exemptFromFees[_address] = _isExempt;
        emit SetExemptFromFees(_address, _isExempt);
    }

    function setExemptFromLimits(address _address, bool _isExempt) external ownerCanChange {
        require(_address != address(0), "Zero Address");
        if(!_isExempt){
            require(_address != lpPair, "Cannot remove pair");
        }
        exemptFromLimits[_address] = _isExempt;
        emit SetExemptFromLimits(_address, _isExempt);
    }

    function updateMaxTransaction(uint256 newNumInTokens) external ownerCanChange {
        require(newNumInTokens >= (totalSupply() * 25 / 10000)/(10**decimals()), "Too low");
        maxTransaction = newNumInTokens * (10**decimals());
        emit UpdatedMaxTransaction(maxTransaction);
    }

    function updateMaxWallet(uint256 newNumInTokens) external ownerCanChange {
        require(newNumInTokens >= (totalSupply() * 25 / 10000)/(10**decimals()), "Too low");
        maxWallet = newNumInTokens * (10**decimals());
        emit UpdatedMaxWallet(maxWallet);
    }

    function updateBuyTax(uint256 _projectTax, uint256 _liquidityTax, uint256 _burnTax) external ownerCanChange {
        buyProjectTax = _projectTax;
        buyLiquidityTax = _liquidityTax;
        buyBurnTax = _burnTax;
        buyTotalTax = buyProjectTax + buyLiquidityTax + buyBurnTax;
        require(buyTotalTax <= initialBuyTax, "Keep tax below initial tax");
        emit UpdatedBuyTax(buyTotalTax);
    }

    function updateSellTax(uint256 _projectTax, uint256 _liquidityTax, uint256 _burnTax) external ownerCanChange {
        sellProjectTax = _projectTax;
        sellLiquidityTax = _liquidityTax;
        sellBurnTax = _burnTax;
        sellTotalTax = sellProjectTax + sellLiquidityTax + sellBurnTax;
        require(sellTotalTax <= initialSellTax, "Keep tax below initial tax");
        emit UpdatedSellTax(sellTotalTax);
    }

    function removeLimits() external ownerCanChange {
        limitsInEffect = false;
        emit RemovedLimits();
    }

    function airdropToWallets(address[] calldata wallets, uint256[] calldata amountsInWei) external onlyOwner {
        require(wallets.length == amountsInWei.length, "arrays length mismatch");
        for(uint256 i = 0; i < wallets.length; i++){
            super._transfer(msg.sender, wallets[i], amountsInWei[i]);
        }
    }

    function rescueTokens(address _token, address _to) external onlyOwner {
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        SafeERC20.safeTransfer(IERC20(_token),_to, _contractBalance);
    }

    // modifiers
    modifier ownerCanChange {
        require(owner() == _msgSender(), "caller not owner");
        require(block.timestamp >= launchTime_ + verificationDuration, "Too early");
        _;
    }

    modifier onlyZentinel {
        require(zentinelAddress == _msgSender(), "Caller not Zentinel");
        _;
    }

    function updateProjectAddress(address _address) external ownerCanChange {
        require(_address != address(0), "zero address");
        projectAddress = _address;
    }
}

interface ITokenFactory {
    function generateToken(StructsLibrary.CreationParams memory params)
        external 
        payable returns (address);
}

interface ITokenLocker {
    function lock(
        address owner,
        address token,
        bool isLpToken,
        uint256 amount,
        uint256 unlockDate,
        string memory description
    ) external returns (uint256 lockId);
}

library StructsLibrary {
    struct CreationParams {
        address _tokenFactory;
        uint256 _launchTime;
        bool _allowZ3EarlyBuyers;
        string _name; 
        string _symbol;
        uint256 _supply;
        uint256 _maxWallet;
        uint256 _maxTransaction;
        address _pairedToken;
        uint256 _liquidityPercent;
        address _newOwner;
        address[] _airdropWallets;
        uint256[] _airdropAmounts;
        string _referralCode;
        uint256[] _buyTaxes; // limit to 3 taxes ("project" tax, lp tax, burn tax)
        uint256[] _sellTaxes; // limit to 3 taxes ("project" tax, lp tax, burn tax)
        address _verifier;
        address _Z3TOKEN;
        address _router;
        uint256 _amountPairedTokenIfNotEth;
        address _projectAddress;
        uint256[] _spareUints;
        bool[] _spareBools;
        address[] _spareAddresses;
    }
}