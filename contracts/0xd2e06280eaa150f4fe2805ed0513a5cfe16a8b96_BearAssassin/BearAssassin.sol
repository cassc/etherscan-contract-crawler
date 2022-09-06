/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: Unlicensed
//https://t.me/Bear_Assassin_Official

pragma solidity ^0.6.12;

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

library SafeERC20 {

    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

}

contract BearAssassin is Context, IERC20, Ownable {

    using SafeMath for uint256;
    using Address for address payable;
    using SafeERC20 for IERC20;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => bool) private _isSniper;
    mapping (address => uint256) private _lastTX;

    address payable public marketing;
    address payable public dev;

    uint256 private _tTotal = 1 * 10**9 * 10**9;
    uint256 public _cooldownPeriod = 20;

    string private _name = "Bear Assassin";
    string private _symbol = "BASS";
    uint8 private _decimals = 9;

    uint256 public _marketingFeeBuy = 20;
    uint256 public _marketingFeeSell = 20;

    uint256 public _liquidityFeeBuy = 10;
    uint256 public _liquidityFeeSell = 20;

    uint256 public _devFeeBuy = 20;
    uint256 public _devFeeSell = 20;

    uint256 public _reflectionsFeeBuy = 30;
    uint256 public _reflectionsFeeSell = 60;

    uint256 constant public _initialBurn = 100 * 10**6 * 10**9;

    uint256 private _liquidityFees;
    uint256 private _reflectionsFees;
    uint256 private _marketingFees;

    uint256 private launchTime;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    address public immutable USDC;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public _maxWalletHolding = 20 * 10**6 * 10**9;
    uint256 public _maxBuyAmount = 20 * 10**6 * 10**9;
    uint256 public _maxSellAmount = 5 * 10**6 * 10**9;
    uint256 private numTokensSellToAddToLiquidity = 3 * 10**4 * 10**9;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (address payable _marketingWallet, address payable _devWallet, address payable _USDC, address[] memory _w) public {
      marketing = _marketingWallet;
      dev = _devWallet;
      USDC = _USDC;

      IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
      uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
      uniswapV2Router = _uniswapV2Router;

      _isExcludedFromFee[owner()] = true;
      _isExcludedFromFee[address(this)] = true;
      _isExcludedFromFee[_marketingWallet] = true;
      _isExcludedFromFee[_devWallet] = true;

      for (uint i = 0; i < _w.length; i++) {
        _isExcludedFromFee[_w[i]] = true;
      }

      emit Transfer(address(0), _msgSender(), _tTotal);
      _tTotal = _tTotal.sub(_initialBurn);
      _balances[_msgSender()] = _tTotal;
      emit Transfer(_msgSender(), address(0), _initialBurn);
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
        return _balances[account];
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

    function manualSwapAndLiquify() public onlyOwner() {
        uint256 contractTokenBalance = balanceOf(address(this));
        swapAndLiquify(contractTokenBalance);
    }

    function excludeFromFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = false;
    }

    function setTaxes(uint256[] memory _taxTypes, uint256[] memory _taxSizes) external onlyOwner() {
      require(_taxTypes.length == _taxSizes.length, "Incorrect input");
      for (uint i = 0; i < _taxTypes.length; i++) {

        uint256 _taxType = _taxTypes[i];
        uint256 _taxSize = _taxSizes[i];

        if (_taxType == 1) {
          _marketingFeeBuy = _taxSize;
        }
        else if (_taxType == 2) {
          _marketingFeeSell = _taxSize;
        }
        else if (_taxType == 3) {
          _devFeeBuy = _taxSize;
        }
        else if (_taxType == 4) {
          _devFeeSell = _taxSize;
        }
        else if (_taxType == 5) {
          _liquidityFeeBuy = _taxSize;
        }
        else if (_taxType == 6) {
          _liquidityFeeSell = _taxSize;
        }
        else if (_taxType == 7) {
          _reflectionsFeeBuy = _taxSize;
        }
        else if (_taxType == 8) {
          _reflectionsFeeSell = _taxSize;
        }
        else if (_taxType == 9) {
          _liquidityFees = _taxSize;
        }
        else if (_taxType == 10) {
          _reflectionsFees = _taxSize;
        }
        else if (_taxType == 11) {
          _marketingFees = _taxSize;
        }
      }
      uint totalSellFee = _marketingFeeSell + _devFeeSell + _liquidityFeeSell + _reflectionsFeeSell;
      uint totalBuyFee = _marketingFeeBuy + _devFeeBuy + _liquidityFeeBuy + _reflectionsFeeBuy;
      require(totalSellFee <= 250);
      require(totalBuyFee <= 100);
    }

    function setSwapAndLiquifyEnabled(bool _enabled, uint256 _numTokensMin) public onlyOwner() {
        swapAndLiquifyEnabled = _enabled;
        numTokensSellToAddToLiquidity = _numTokensMin;
    }

    function enableTrading() public onlyOwner() {
        require(launchTime == 0, "Already enabled");
        launchTime = block.timestamp;
    }

    receive() external payable {}

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            swapAndLiquify(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //depending on type of transfer (buy, sell, or p2p tokens transfer) different taxes & fees are applied
        bool isTransferBuy = from == uniswapV2Pair;
        bool isTransferSell = to == uniswapV2Pair;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        else {
          require(launchTime > 0, "Trading not enabled yet");
          if (!isTransferBuy && !isTransferSell) {
            require((_lastTX[from] + _cooldownPeriod) <= block.timestamp, "Cooldown");
            takeFee = false;
          }
          else if (isTransferSell) {
            require((_lastTX[from] + _cooldownPeriod) <= block.timestamp, "Cooldown");
            _lastTX[from] = block.timestamp;
          }
          else if (isTransferBuy) {
            require((_lastTX[to] + _cooldownPeriod) <= block.timestamp, "Cooldown");
            _lastTX[to] = block.timestamp;
          }
          if (isTransferBuy) require(amount <= _maxBuyAmount, "Max buy limit exceeded");
          if (isTransferSell && (block.timestamp < (launchTime + 48 hours))) require(amount <= _maxSellAmount, "Max sell limit exceeded");
        }

        _transferStandard(from,to,amount,takeFee,isTransferBuy,isTransferSell);

        if (!_isExcludedFromFee[to] && (to != uniswapV2Pair)) require(balanceOf(to) < _maxWalletHolding, "Max Wallet holding limit exceeded");
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 liquidityPart = 0;
        if (_liquidityFees < contractTokenBalance) liquidityPart = _liquidityFees;

        uint256 distributionPart = contractTokenBalance.sub(liquidityPart).sub(_reflectionsFees);
        uint256 liquidityHalfPart = liquidityPart.div(2);
        uint256 liquidityHalfTokenPart = liquidityPart.sub(liquidityHalfPart);

        uint256 totalETHSwap = liquidityHalfPart.add(distributionPart);

        swapTokensForEth(totalETHSwap);

        uint256 newBalance = address(this).balance;
        uint256 marketingBalance = _marketingFees.mul(newBalance).div(totalETHSwap);
        uint256 liquidityBalance = liquidityHalfPart.mul(newBalance).div(totalETHSwap);

        if (liquidityHalfTokenPart > 0 && liquidityBalance > 0) addLiquidity(liquidityHalfTokenPart, liquidityBalance);

        if (marketingBalance > 0 && marketingBalance < address(this).balance) marketing.call{ value: marketingBalance }("");
        if (address(this).balance > 0) dev.call{ value: address(this).balance }("");

        uint256 remBalance = balanceOf(address(this));
        if (remBalance > 0) {
          swapTokensForUSDC(remBalance);
        }

        _marketingFees = 0;
        _liquidityFees = 0;
        _reflectionsFees = 0;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            marketing,
            block.timestamp
        );
    }

    function setBlockedWallet(address _account, bool _blocked ) public onlyOwner() {
        _isSniper[_account] = _blocked;
    }

    function withdrawTokens(address _token, uint256 _amount) public onlyOwner() {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    function swapTokensForUSDC(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = USDC;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 usdcBalance = IERC20(USDC).balanceOf(address(this));
        IERC20(USDC).safeTransfer(marketing, usdcBalance);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount, bool takeFee, bool isTransferBuy, bool isTransferSell) private {
        uint256 tTransferAmount = tAmount;
        if (takeFee) {
          uint256 totalTax;
          uint256 liquidityTax;
          uint256 marketingTax;
          uint256 reflectionsTax;
          if (isTransferBuy) {
            marketingTax = tAmount.mul(_marketingFeeBuy).div(1000);
            reflectionsTax = tAmount.mul(_reflectionsFeeBuy).div(1000);
            liquidityTax = tAmount.mul(_liquidityFeeBuy).div(1000);
            totalTax = marketingTax + reflectionsTax + liquidityTax + (tAmount.mul(_devFeeBuy).div(1000));
          }
          if (isTransferSell) {
            require(!_isSniper[sender], "SNIPER!");
            marketingTax = tAmount.mul(_marketingFeeSell).div(1000);
            reflectionsTax = tAmount.mul(_reflectionsFeeSell).div(1000);
            liquidityTax = tAmount.mul(_liquidityFeeSell).div(1000);
            totalTax = marketingTax + reflectionsTax + liquidityTax + (tAmount.mul(_devFeeSell).div(1000));
          }
          tTransferAmount = tTransferAmount.sub(totalTax);
          _marketingFees = _marketingFees.add(marketingTax);
          _liquidityFees = _liquidityFees.add(liquidityTax);
          _reflectionsFees = _reflectionsFees.add(reflectionsTax);
        }
        else if (!isTransferBuy && !isTransferSell) {
          require(!_isSniper[sender], "SNIPER!");
        }

        _balances[sender] = _balances[sender].sub(tAmount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);
        _balances[address(this)] = _balances[address(this)].add(tAmount.sub(tTransferAmount));

        emit Transfer(sender, recipient, tTransferAmount);
    }

}