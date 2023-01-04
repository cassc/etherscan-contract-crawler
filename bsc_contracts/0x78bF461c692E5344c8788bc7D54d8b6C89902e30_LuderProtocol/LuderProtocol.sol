/**
 *Submitted for verification at BscScan.com on 2023-01-03
*/

/*************************
    __    __  ______  __________ 
   / /   / / / / __ \/ ____/ __ \
  / /   / / / / / / / __/ / /_/ /
 / /___/ /_/ / /_/ / /___/ _, _/ 
/_____/\____/_____/_____/_/ |_|

LUDER PROTOCOL v1.0

Token protocol with automatic lottery system for holders.

Once a certain amount of network currency has been accumulated in the complementary lottery contract,
in the next transaction the token contract will perform the function of choosing a winner from the
funds accumulated in the lottery contract.

To participate in the lottery, the holder must have at least a certain amount of tokens,
if he meets this condition, he will be automatically participating.

More information:
https://luderprotocol.com/

Powered by Powabit Ecosystem:
https://powabit.com/

Random generation by Chainlink VRF v2:
https://chain.link/

*************************/

pragma solidity = 0.8.17;
// SPDX-License-Identifier: Unlicensed

/*************************

INDEX: Search by Index Shortcut (*ISxx)

1- ABSTRACT CONTRACTS
  a) Context - *IS01
  b) ReentrancyGuard - *IS02
  c) VRFV2WrapperConsumerBase - *IS03

2- INTERFACES
  a) IUniswapV2Factory - *IS04
  b) IUniswapV2Pair - *IS05
  c) IUniswapV2Router01 - *IS06
  d) IUniswapV2Router02 - *IS07
  e) IERC20 - *IS08
  f) VRFV2WrapperInterface - *IS09
  g) LinkTokenInterface - *IS10

3- LIBRARIES
  a) Address - *IS11
  b) SafeMath (For build versions less than 0.8) - *IS12

4- CONTRACTS
  a) Ownable - *IS13
  b) ERC20 - *IS14
  c) LuderProtocol - *IS15
  d) LuderLotteryPot - *IS16

*************************/

//**********************
// ABSTRACT CONTRACTS
//**********************

//*IS01

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

//*IS02

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "Error");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

//*IS03

//pragma solidity ^0.8.0;

/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "Error");
    fulfillRandomWords(_requestId, _randomWords);
  }
}

//**********************
// INTERFACES
//**********************

//*IS04

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

//*IS05

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

//*IS06

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

//*IS07

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

//*IS08

//pragma solidity ^0.6.2;

interface IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

//*IS09

//pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);
  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);
  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
}

//*IS10

//pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

//**********************
// LIBRARIES
//**********************

//*IS11

library Address {

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

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{ value: amount }("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

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

//*IS12

library SafeMath { //Use in case of build versions less than 0.8.

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }


  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }


  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }


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


  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }


  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }


  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }


  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

//**********************
// CONTRACTS
//**********************

//*IS13

abstract contract Ownable is Context {
  address private _owner;
  address private _previousOwner;

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
    require(_owner == _msgSender(), "Error");
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Error");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

}

//*IS14

//pragma solidity ^0.6.2;

contract ERC20 is Context, IERC20 {
  using SafeMath for uint256;
  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  uint256 private _totalSupply;
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  /**
  * @dev Sets the values for {name} and {symbol}.
  *
  * The default value of {decimals} is 18. To select a different value for
  * {decimals} you should overload it.
  *
  * All two of these values are immutable: they can only be set once during
  * construction.
  */
  constructor(string memory name_, string memory symbol_, uint8 decimals_) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
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
    return _decimals;
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
  * required by the EIP. See the note at the beginning of {ERC20}.
  *
  * Requirements:
  *
  * - `sender` and `recipient` cannot be the zero address.
  * - `sender` must have a balance of at least `amount`.
  * - the caller must have allowance for ``sender``'s tokens of at least
  * `amount`.
  */
  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Error"));
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
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Error"));
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
    require(sender != address(0), "Error");
    require(recipient != address(0), "Error");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, "Error");
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
    require(account != address(0), "Error");

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
    require(account != address(0), "Error");

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount, "Error");
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
    require(owner != address(0), "Error");
    require(spender != address(0), "Error");
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
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

/*********************
*
* TOKEN CONTRACT
*
********************/

//*IS15

/**
* @title Luder Protocol ($LUDER) Contract
* @author Dev Mexos
* @notice The contract is based on the erc-20 standard, has buy/sell fees on uniswap, It makes
* simple swapping to BNB and send to recipients.The particularity is that it has an 
* automatic integrated lottery system, which consists of a little couple of functions to 
* select a winner at random (it uses the chainlink VRF system) and then send a prize.
* @dev I have ensured that the contract does not exceed the limit of Spurious Dragon 
* (24576 bytes) So that the optimizer does not have to be used in a forced way.
* The contract is all documented in the code (functions and variables).
*/

contract LuderProtocol is ERC20, Ownable, VRFV2WrapperConsumerBase {
  using SafeMath for uint256;
  using Address for address;

  /*********** GENERAL VARIABLES ***********/

  //Uniswap Router and pair
  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;
  mapping (address => bool) public automatedMarketMakerPairs;

  //Excluded from fee
  mapping (address => bool) private _isExcludedFromFee;

  //State swapping
  bool private _swapping;
  //State picking winner
  bool private _pickingWinner;
  //Swap enabled or disabled
  bool public _swapState;
  //Swap in certain quantity of tokens in contract
  uint256 private _swapTokensAtAmount;

  //Buy fees
  uint256 public _buy_DevFee;
  uint256 public _buy_LotoFee;
  uint256 public _buy_BuyBackFee;
  uint256 private _buy_totalFees;

  //Sell fees
  uint256 public _sell_DevFee;
  uint256 public _sell_LotoFee;
  uint256 public _sell_BuyBackFee;
  uint256 private _sell_totalFees;

  //Average fees
  uint256 private _average_DevFee;
  uint256 private _average_LotoFee;
  uint256 private _average_BuyBackFee;
  uint256 private _average_totalFees;

  //Sustainability wallet fee address
  address payable public _devFeeAddress;

  //BuyBack fee address
  address payable public _buybackFeeAddress;

  /*********** LOTTERY VARIABLES ***********/

  //Lottery Pot Contract
  LuderLotteryPot public _lotteryContract;

  //Excluded from lottery
  mapping (address => bool) private _isExcludedFromLottery;

  //Lottery min ETH for execution
  uint256 public _lotteryExecuteAmount;

  //Min. amount to execute Lotto-Plus
  uint256 public _lottoPlusExecuteAmount;

  //Min. amount to participe in Lottery
  uint256 public _minAmountToParticipate;

  //List of holders in lottery
  address [] public _listOfHolders;

  //Holder added check
  mapping (address => bool) public _addedHolderList;

  //Holder index map
  mapping (address => uint256) public _holderIndexes;

  //Number of lottery rounds
  uint256 public _lotteryRound;

  //Information of winner in round
  struct _winnerInfoStruct {
      uint256 randomNumber;
      address wallet;
      uint256 prizeAmount;
      bool chainlink;
  }

  //Round information mapping
  mapping (uint256 => _winnerInfoStruct) private _winnerInfo;

  /*********** CHAINLINK VARIABLES ***********/

  //Address LINK - BSC testnet
  //address internal immutable linkAddress = 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06;
  //Address WRAPPER - BSC testnet
  //address internal immutable wrapperAddress = 0x699d428ee890d55D56d5FC6e26290f3247A762bd;

  //Address LINK - BSC mainnet
  address internal immutable linkAddress = 0x404460C6A5EdE2D891e8297795264fDe62ADBB75;
  //Address WRAPPER - BSC mainnet
  address internal immutable wrapperAddress = 0x721DFbc5Cfe53d32ab00A9bdFa605d3b8E1f3f42;

  struct RequestStatus {
    uint256 paid; // amount paid in link
    bool fulfilled; // whether the request has been successfully fulfilled
    uint256[] randomWords;
  }
  mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
  // past requests Id.
  uint256[] public requestIds;
  uint256 public lastRequestId;
  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 internal callbackGasLimit = 100000;
  // The default is 3, but you can set this higher.
  uint16 internal requestConfirmations = 3;
  // Retrieve 2 random values in one request.
  // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
  uint32 internal numWords = 2;
  // Min. LINK balance to use Chainlink
  uint256 public _minLinkBalanceToUseChainlink;

  /*********** EVENTS ***********/

  //On update router event
  event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

  //On set new automated market maker pair event
  event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

  //On new lottery winner event
  event LotteryWinner(uint256 randomNumber, address wallet, uint256 prizeAmount, bool chainlinkGenerated);

  //On released extra amount for Lotto-Plus
  event LottoPlusReleased(uint256 extraAmount);

  //On random number request (Chainlink) is sent
  event RequestSent(uint256 requestId, uint32 numWords);

  //On VRF V2 wrapper response
  event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint256 payment);

  /*********** INITIALIZATION ***********/

  //Constructor (Default values)
  constructor() ERC20("Luder Protocol", "LUDER", 18) VRFV2WrapperConsumerBase(linkAddress, wrapperAddress) {

    //Creation of a uniswap pair for this token for mainnet/testnet
    //Mainnet
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    //Testnet
    //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
    
    //DEX router and pair setup
    address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = _uniswapV2Pair;
    _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

    // Creation of Lottery Pot subcontract (the token contract is the creator and the one who manages it)
    // If the Lottery Pot subcontract must be changed, the token contract must be established as the owner 
    // for the operation of the lottery dynamics, through the "setTokenAddress" function of the subcontract.
    _lotteryContract = new LuderLotteryPot();

    //Setting of Token -> ETH/BNB swap default variables
    _swapState = true;
    _swapTokensAtAmount = 50000 * (10**decimals());

    //Initial fee wallets
    _devFeeAddress = payable(_msgSender());
    _buybackFeeAddress = payable(_msgSender());

    //Exclude owner and this contract from fee
    _isExcludedFromFee[_msgSender()] = true;
    _isExcludedFromFee[address(this)] = true;

    //Setting of variables for lottery
    _lotteryExecuteAmount = 300000000000000000; //Min. default execution amount: 0.3 ETH/BNB (in wei).
    _minAmountToParticipate = 100000 * (10**decimals()); //Min. default amount to participate: 0.1% of Total Supply.
    _lottoPlusExecuteAmount = 1000000000000000000; //For the execution of Lotto-Plus, there must be 1 ETH/BNB (in wei) left over in the token contract.

    //Total Supply generation
    uint256 _intTotalSupply = 100000000;
    _mint(_msgSender(), _intTotalSupply.mul(10**decimals()));

    //Fee setting for Buy/Sell (Fixed)
    _buy_DevFee = 3;
    _buy_LotoFee = 3;
    _buy_BuyBackFee = 0;
    _buy_totalFees = _buy_DevFee.add(_buy_LotoFee).add(_buy_BuyBackFee);
    _sell_DevFee = 3;
    _sell_LotoFee = 3;
    _sell_BuyBackFee = 3;
    _sell_totalFees = _sell_DevFee.add(_sell_LotoFee).add(_sell_BuyBackFee);
    _average_DevFee = _buy_DevFee.add(_sell_DevFee);
    _average_LotoFee = _buy_LotoFee.add(_sell_LotoFee);
    _average_BuyBackFee = _buy_BuyBackFee.add(_sell_BuyBackFee);
    _average_totalFees = _average_DevFee.add(_average_LotoFee).add(_average_BuyBackFee);

    //Initial value at 0 for lottery rounds
    _lotteryRound = 0;

    //Initial minimum amount of LINK to allow the use of the Chainlink VRF system
    _minLinkBalanceToUseChainlink = 2000000000000000000; //Min. 2 LINK

  }

  /*********** (OWNER) SETTER FUNCTIONS ***********/

  /** @notice Update the address of the lottery subcontract
  * If the Lottery Pot subcontract must be changed, 
  * the token contract must be established as the owner for 
  * the operation of the lottery dynamics, through the 
  * "setTokenAddress" function of the subcontract.
  *
  * @param addr New Luder Protocol Lottery Pot Sub-Contract Address.
  *
  * Requirements:
  *
  * - Must be executed by the contract owner.
  * - The contract must be able to receive ETH/BNB.
  * - The contract must have at least the externally accessible function `withdraw`. 
  *   and the public variable `totalRewardsGiven`.
  */
  function updateLotteryContractAddress (address payable addr) public onlyOwner {
    _lotteryContract = LuderLotteryPot(addr);
  }

  /** @notice Update the minimum amount of ETH/BNB (in wei) stored 
  * in the lottery subcontract to run a new round of the game.
  *
  * @param amount New minimum amount of ETH/BNB (in wei).
  *
  * Requirements:
  *
  * - Must be executed by the contract owner.
  */
  function updateLotteryExecuteAmount(uint256 amount) public onlyOwner {
    _lotteryExecuteAmount = amount;
  }

  /** @notice Update the amount of tokens needed to be a lottery participant.
  * It must be taken into account that it is an update that applies to
  * addresses that interact with the contract in transfers after the update.
  *
  * @param amount New minimum amount of tokens needed to be a lottery participant (in wei format).
  *
  * Requirements:
  *
  * - Must be executed by the contract owner.
  */
  function updateLotteryMinTokensAmount(uint256 amount) public onlyOwner {
    _minAmountToParticipate = amount;
  }

  /** @notice Excludes an address from participating in the lottery 
  * (or includes a previously excluded address).
  *
  * In the event that it is excluded, it is removed from the list of
  * participants and in the event that it is included again and meets the
  * requirements in terms of the number of tokens, it is included again
  * in the list.
  *
  * @param account Address to be excluded.
  * @param state New state for this address `true` = Exclude - `false` = Include.
  *
  * Requirements:
  *
  * - Must be executed by the contract owner.
  */
  function excludeFromLottery(address account, bool state) public onlyOwner {
    _isExcludedFromLottery[account] = state;
    if (state){ //if excluded state is true
      if (_addedHolderList[account]){
           removeHolder(account);
        }
    } else { //if excluded state is false
      if (balanceOf(account) >= _minAmountToParticipate && !_addedHolderList[account]){
           addHolder(account);
        }
    }
  }

  /** @notice Sets the state of a switch to allow the contract to swap Tokens to ETH/BNB.
  *
  * @param state New state for swap function `true` = Active - `false` = Disabled.
  *
  * Requirements:
  *
  * - Must be executed by the contract owner.
  */
  function setswapState(bool state) public onlyOwner {
    _swapState = state;
  }

  /** @notice This function is used to reset the switch that allows the
  * `awardRandom()` process to be executed again if any eventuality
  * occurs in relation to the interaction with external contracts in the
  * random winner selection function.
  *
  * Requirements:
  *
  * - Must be executed by the contract owner.
  */
  function pickingWinnerStateFix() public onlyOwner {
    _pickingWinner = false;
  }

  /** @notice Updates the minimum amount of tokens stored in the contract 
  * to allow it to swap Tokens to ETH/BNB.
  *
  * @param amount New amount of tokens to allow the contract to swap Tokens to ETH/BNB (in wei format).
  *
  * Requirements:
  *
  * - Must be executed by the contract owner.
  */
  function setSwapTokensAtAmount(uint256 amount) public onlyOwner() {
    _swapTokensAtAmount = amount;
  }

  /** @notice Excludes an address from the collection of fees
  * (or includes a previously excluded address).
  *
  * By default, the contract itself is excluded (which must swap tokens
  * for ETH/BNB), the owner who distributes the tokens initially, and it
  * must also be taken into account to exclude addresses of functional
  * contracts with which it is going to interact. For example, pre-sale
  * contracts and lockers.
  *
  * @param account Address to be excluded.
  * @param state New state for this address `true` = Exclude - `false` = Include.
  *
  * Requirements:
  *
  * - Must be executed by the contract owner.
  */
  function excludeFromFee(address account, bool state) public onlyOwner {
    _isExcludedFromFee[account] = state;
  }

  /** @notice Update the sustainability address, which receives the fee
  * percentage established for that purpose from the contract.
  *
  * @param newAddress New address for sustainability.
  *
  * Requirements:
  *
  * - Must be executed by the contract owner.
  */
  function setDevFeeAddress(address newAddress) public onlyOwner{
    _devFeeAddress = payable(newAddress);
  }

  /** @notice Update the Buy Back address, which receives the fee
  * percentage established for that purpose from the contract.
  *
  * @param newAddress New address for Buy Back.
  *
  * Requirements:
  *
  * - Must be executed by the contract owner.
  */
  function setBuybackFeeAddress(address newAddress) public onlyOwner{
    _buybackFeeAddress = payable(newAddress);
  }

  /** @notice Update the DEX router and create a new token pair.
  *
  * @param newAddress New address of router.
  *
  * Emits a {UpdateUniswapV2Router} event.
  *
  * Requirements:
  *
  * - The address of the new router cannot be the same as the old one.
  * - Must be executed by the contract owner.
  */
  function updateUniswapV2Router(address newAddress) public onlyOwner {
    require(newAddress != address(uniswapV2Router), "Error");
    emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
    uniswapV2Router = IUniswapV2Router02(newAddress);
    address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
    .createPair(address(this), uniswapV2Router.WETH());
    uniswapV2Pair = _uniswapV2Pair;
  }

  /** @notice Establishes a new automatic market pair.
  *
  * Emits a {SetAutomatedMarketMakerPair} event.
  * (From the inner function `_setAutomatedMarketMakerPair`).
  *
  * @param pair New pair address.
  * @param value New state for this automated pair `true` = Active - `false` = Disabled.
  *
  * Requirements:
  *
  * - The new pair cannot be equal to the one already set in `uniswapV2Pair`.
  * - Must be executed by the contract owner.
  */
  function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
    require(pair != uniswapV2Pair, "Error");
    _setAutomatedMarketMakerPair(pair, value);
  }

  /** @notice Set the minimum amount of LINK tokens needed for random selection with Chainlink.
  *
  * @param amount New minimum amount of LINK tokens needed to activate VRF system.
  *
  * Requirements:
  *
  * - Must be executed by the contract owner.
  */
  function updateMinLinkBalanceToUseChainlink(uint256 amount) public onlyOwner {
    _minLinkBalanceToUseChainlink = amount;
  }

  /** @notice It allows the owner to withdraw LINK (external tokens, used by the
  * Chainlink service) from the contract in case an erroneous or excessive amount is sent.
  *
  * Requirements:
  *
  * - Must be executed by the contract owner.
  */
  function recoverLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(linkAddress);
    link.transfer(msg.sender, link.balanceOf(address(this)));
  }

  /*********** (PUBLIC) GETTER FUNCTIONS ***********/

  /** @notice Returns a value of true or false, based on the
  * excluded status of an address to participate in the lottery.
  *
  * @param account The address to verify.
  *
  * @return (bool) State of account `true` = Excluded - `false` = Included.
  */
  function isExcludedFromLottery(address account) public view returns(bool) {
    return _isExcludedFromLottery[account];
  }

  /** @notice Returns a value of true or false, based on the
  * excluded status of an address for fee collection.
  *
  * @param account The address to verify.
  *
  * @return (bool) State of account `true` = Excluded - `false` = Included.
  */
  function isExcludedFromFee(address account) public view returns(bool) {
    return _isExcludedFromFee[account];
  }

  /** @notice Returns a data structure relevant to the results 
  * of a particular lottery round.
  *
  * @param lotoNumber The lottery ID to verify.
  *
  * @return (struct) Returns a data structure with the information of the 
  * indicated lottery round.
  */
  function lotteryWinnerInfo(uint256 lotoNumber) public view returns(_winnerInfoStruct memory){
    return _winnerInfo[lotoNumber];
  }

  /** @notice Returns the number of current lottery participants.
  *
  * @return (uint256) Returns the number of current lottery participants.
  */
  function lotteryParticipantsAmount() public view returns(uint256){
    return _listOfHolders.length;
  }

  /** @notice Returns dataset with the status of the request to Chainlink based on a given ID.
  *
  * @param _requestId The request ID.
  *
  * @return paid (uint256) paid ID.
  * @return fulfilled (bool) Fulfilled request.
  * @return randomWords (uint256[]) Random Words.
  *
  * Requirements:
  *
  * - The request must be as paid.
  */
  function getRequestStatus(uint256 _requestId) external view returns (uint256 paid, bool fulfilled, uint256[] memory randomWords){
    require(s_requests[_requestId].paid > 0, "Error");
    RequestStatus memory request = s_requests[_requestId];
    return (request.paid, request.fulfilled, request.randomWords);
  }

  /*********** INTERNAL FUNCTIONS ***********/

  /** @notice (INTERNAL) Establishes a new automatic market pair.
  *
  * @param pair New pair address.
  * @param value New state for this automated pair `true` = Active - `false` = Disabled.
  *
  * Emits a {SetAutomatedMarketMakerPair} event.
  *
  * Requirements:
  *
  * - The new pair cannot be equal to the one already set in `uniswapV2Pair`.
  * - It can only be executed internally by the function `setAutomatedMarketMakerPair`.
  */
  function _setAutomatedMarketMakerPair(address pair, bool value) private {
    require(automatedMarketMakerPairs[pair] != value, "Error");
    automatedMarketMakerPairs[pair] = value;
    emit SetAutomatedMarketMakerPair(pair, value);
  }

  /** @notice (INTERNAL) Add an address to the list of lottery participants.
  *
  * @param shareholder Address to be added.
  *
  * Requirements:
  *
  * - It can only be executed internally by the function `_transfer` or `excludeFromLottery`.
  */
  function addHolder(address shareholder) private {
    _holderIndexes[shareholder] = _listOfHolders.length;
    _listOfHolders.push(shareholder);
    _addedHolderList[shareholder] = true;
  }

  /** @notice (INTERNAL) Excludes an address from the lottery participant list.
  *
  * @param shareholder Address to be removed.
  *
  * Requirements:
  *
  * - It can only be executed internally by the function `_transfer` or `excludeFromLottery`.
  */
  function removeHolder(address shareholder) private {
    _listOfHolders[_holderIndexes[shareholder]] = _listOfHolders[_listOfHolders.length-1];
    _holderIndexes[_listOfHolders[_listOfHolders.length-1]] = _holderIndexes[shareholder];
    _listOfHolders.pop();
    _addedHolderList[shareholder] = false;
  }

  /** @notice (INTERNAL) Generates a pseudo-random number based on a range, timestamp
  * and dynamic salt taking the balance of the lottery subcontract.
  *
  * This is an alternative to the main Chainlink-based randomness
  * generator. If the contract does not have a minimum amount of
  * LINK token, a pseudo-random function would be executed.
  *
  * @param from Internal modifier for seed processing (from).
  * @param to Internal modifier for seed processing (to).
  * @param salt Internal modifier for seed processing (dynamic compensation for 
  * pseudo-randomness generation).
  *
  * @return (uint256) Pseudo-random number generated (raw).
  *
  * Requirements:
  *
  * - It can only be executed internally by the function `awardRandom`.
  */
  function alternativePseudoRandom(uint256 from, uint256 to, uint256 salt) private view returns (uint256) {
    uint256 seed = uint256(
      keccak256(
        abi.encodePacked(
          block.timestamp + block.difficulty +
          ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
          block.gaslimit +
          ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
          block.number +
          salt
        )
      )
    );
    return seed.mod(to - from) + from;
  }

  /** @notice (INTERNAL) handles the VRF V2 wrapper response.
  *
  * @param _requestId request ID.
  * @param _randomWords Random words input.
  */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
    require(s_requests[_requestId].paid > 0, "Error");
    s_requests[_requestId].fulfilled = true;
    s_requests[_requestId].randomWords = _randomWords;
    emit RequestFulfilled(_requestId, _randomWords, s_requests[_requestId].paid);
  }

  /** @notice (INTERNAL) Send a request to Chainlink to get a randomly
  * generated number as a response.
  *
  * @return requestId (uint256) Random number generated by Chainlink (raw).
  *
  * Requirements:
  *
  * - It can only be executed internally by the function `awardRandom`.
  */
  function requestRandomWordsInternal() internal returns (uint256 requestId){
    requestId = requestRandomness(callbackGasLimit, requestConfirmations, numWords);
    s_requests[requestId] = RequestStatus({
      paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
      randomWords: new uint256[](0),
      fulfilled: false
    });
    requestIds.push(requestId);
    lastRequestId = requestId;
    emit RequestSent(requestId, numWords);
    return requestId;
  }

  /** @notice (INTERNAL) Select a lottery winner at random (via Chainlink's VRF system). 
  * If it is not possible to use the Chainlink system due to not having funds
  * in the LINK token, it executes a pseudo-random selection of backup.
  * After obtaining the winning number, send the funds from the Lottery
  * Pot subcontract to the corresponding wallet and add the event data
  * to a registry variable.
  *
  * Emits a {LotteryWinner} event.
  *
  * Requirements:
  *
  * - The list of participating lottery holders must be greater than 0.
  * - It can only be executed internally by the function `_transfer`.
  */
  function awardRandom() private {
    if (_listOfHolders.length > 0){
      uint256 fixedSeed;
      bool chainlinkGenerated;
      uint256 contractLinkBalance = IERC20(linkAddress).balanceOf(address(this));
      if(contractLinkBalance >= _minLinkBalanceToUseChainlink){
        uint256 chainlinkRandom = requestRandomWordsInternal();
        fixedSeed = chainlinkRandom.mod(1000000 - 100) + 100;
        chainlinkGenerated = true;
      }else{
        fixedSeed = alternativePseudoRandom(100, 1000000, address(_lotteryContract).balance);
        chainlinkGenerated = false;
      }
      uint256 rndVal = fixedSeed % _listOfHolders.length;
      uint256 prizeAccumulated = address(_lotteryContract).balance;
      _lotteryContract.withdraw(_listOfHolders[rndVal]);
      _lotteryRound++;
      _winnerInfo[_lotteryRound].randomNumber = rndVal;
      _winnerInfo[_lotteryRound].wallet = _listOfHolders[rndVal];
      _winnerInfo[_lotteryRound].prizeAmount = prizeAccumulated;
      _winnerInfo[_lotteryRound].chainlink = chainlinkGenerated;
      emit LotteryWinner(rndVal, _listOfHolders[rndVal], prizeAccumulated, chainlinkGenerated);
    }
  }

  /** @notice (INTERNAL) Set up custom actions based on the standard ERC-20 _transfer function.
  *
  * First, verify that the conditions are met to swap the tokens stored in 
  * the contract for ETH/BNB to send to the different purposes defined in the fees.
  *
  * Second, check if the msg.sender must pay the fees set in the fee. If so, 
  * retain the indicated percentage and send the rest to the receiver.
  *
  * Third, analyze the token balance of the sender and receiver to verify if 
  * it is necessary to modify their participation status in the lottery.
  *
  * Finally, evaluate if the conditions are met to execute the lottery winner 
  * selection function.
  *
  * @param from Address from which tokens are sent.
  * @param to Address that receives the tokens.
  * @param amount Amount of tokens to send (in wei format).
  *
  * Requirements:
  *
  * - Sender and/or receiver must not be address 0.
  * - The amount to be sent must be greater than 0.
  * - It can only be executed internally by the function `transfer` or `transferFrom`.
  */
  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    require(from != address(0), "Error");
    require(to != address(0), "Error");
    require(amount > 0, "Error");
    uint256 contractTokenBalance = balanceOf(address(this));
    bool canSwap = contractTokenBalance >= _swapTokensAtAmount;
    bool justSwaped = false;
    if( canSwap &&
      !_swapping &&
      !automatedMarketMakerPairs[from] &&
      from != owner() &&
      to != owner() &&
      _swapState
    ) {
      _swapping = true;
      swapActualTokensAndSendDividends(contractTokenBalance);
      _swapping = false;
      justSwaped = true;
    }
    bool takeFee = !_swapping;
    uint256 context_totalFees = 0;
    // if any account belongs to _isExcludedFromFee account or fees are 
    // disabled then remove the fee
    if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
      takeFee = false;
    }
    else{
      // Buy Tax on DEX
      if(from == uniswapV2Pair){
        context_totalFees = _buy_totalFees;
      }
      // Sell Tax on DEX
      if(to == uniswapV2Pair){
        context_totalFees = _sell_totalFees;
      }
    }
    if(takeFee) {
      uint256 fees = amount.mul(context_totalFees).div(100);
      if(automatedMarketMakerPairs[to]){
        fees += amount.mul(1).div(100);
      }
      amount = amount.sub(fees);
      super._transfer(from, address(this), fees);
    }
    super._transfer(from, to, amount);
    if (!_isExcludedFromLottery[from] && balanceOf(from) < _minAmountToParticipate && _addedHolderList[from]){
      removeHolder(from);
    }
    if (!_isExcludedFromLottery[to] && balanceOf(to) >= _minAmountToParticipate && !_addedHolderList[to] && to != uniswapV2Pair){
      addHolder(to);
    }
    if (address(_lotteryContract).balance > _lotteryExecuteAmount && !_swapping && !justSwaped && !_pickingWinner){
      _pickingWinner = true;
      awardRandom();
      _pickingWinner = false; 
    }
  }

  /** @notice (INTERNAL) It swap a defined amount of tokens stored in the contract for ETH/BNB
  * and then sends it to the corresponding fee addresses.
  *
  * Lotto-Plus: Based on percentage splits, if there is a remaining balance of ETH in the
  * contract and it exceeds the set amount of "_lottoPlusExecuteAmount" in wei, it is 
  * automatically sent to the lottery address to run a lottery with an extra reward.
  *
  * Emits a {LottoPlusReleased} event if the conditions of `Lotto-Plus` are met.
  *
  * @param tokens Amount of tokens to swap (in wei format).
  *
  * Requirements:
  *
  * - It can only be executed internally by the function `_transfer`.
  */
  function swapActualTokensAndSendDividends(uint256 tokens) private  {
    uint256 initialBalance = address(this).balance;
    swapTokensForEth(tokens);
    uint256 newBalance = address(this).balance.sub(initialBalance);
    uint256 DevFee = newBalance.mul(_average_DevFee).div(_average_totalFees);
    transferToAddressETH(_devFeeAddress, DevFee);
    uint256 BuyBackFee = newBalance.mul(_average_BuyBackFee).div(_average_totalFees);
    transferToAddressETH(_buybackFeeAddress, BuyBackFee);
    uint256 LotoFee = newBalance.mul(_average_LotoFee).div(_average_totalFees);
    transferToAddressETH(payable(_lotteryContract), LotoFee);
    uint256 remainingBalance = address(this).balance;
    if(remainingBalance >= _lottoPlusExecuteAmount){
      transferToAddressETH(payable(_lotteryContract), remainingBalance);
      emit LottoPlusReleased(remainingBalance);
    }
  }

  /** @notice (INTERNAL) It swap a defined amount of tokens stored in the contract for ETH/BNB.
  *
  * @param tokenAmount Amount of tokens to swap (in wei format).
  *
  * Requirements:
  *
  * - It can only be executed internally by the function `swapActualTokensAndSendDividends`.
  */
  function swapTokensForEth(uint256 tokenAmount) private {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, //accept any amount of ETH
      path,
      address(this),
      block.timestamp
    );
  }

  /** @notice (INTERNAL) Transfer an amount of ETH/BNB from the contract to a provided address.
  *
  * @param recipient Address that will receive the ETH/BNB.
  * @param amount Amount of ETH/BNB to send (in wei).
  *
  * Requirements:
  *
  * - It can only be executed internally by the function `swapActualTokensAndSendDividends`.
  */
  function transferToAddressETH(address payable recipient, uint256 amount) private {
    recipient.transfer(amount);
  }

  /** @notice The contract can receive ETH/BNB. It is necessary to swap tokens.
  */
  receive() external payable {}

}

/*********************
*
* LOTTERY POT CONTRACT
*
********************/

//*IS16

/**
* @title Luder Protocol Lottery Pot Sub-Contract
* @author Dev Mexos
* @notice This sub-contract is managed and generated by the token contract.
* It is in charge of storing the funds for the dynamic prizes of the
* automatic lottery that executes the token contract once a certain
* amount of ETH/BNB has been reached. It also keeps track of the total rewards delivered.
* @dev This contract is initially generated by the constructor of the token. 
* In the case of needing to change the version of this subcontract, 
* it can be generated independently, then the token contract must be
* established as owner with the `setTokenAddress` function and the
* address of this new sub-contract must be updated with the
* `updateLotteryContractAddress` function in the token contract.
*/

contract LuderLotteryPot is Ownable, ReentrancyGuard {

  /*********** GENERAL VARIABLES ***********/

  //Total prizes delivered by the lottery subcontract.
  uint256 public totalRewardsGiven;

  /*********** EVENTS ***********/

  //On deposit of ETH/BNB in the subcontract
  event depositFounds (uint256 amount);

  //On send a lottery reward to a recipient
  event rewardSent (address reciever, uint256 amount);

  /*********** (OWNER - TOKEN CONTRACT) SETTER FUNCTIONS ***********/

  /** @notice If a new version of this subcontract is generated, administration of
  * the subcontract must be given to the token contract. 
  * The new address of the generated subcontract must also be set with the
  * `updateLotteryContractAddress` function of the token contract.
  *
  * @param addr Address of token (new manager).
  *
  * Requirements:
  *
  * - Must be executed by the contract owner.
  */
  function setTokenAddress (address addr) public onlyOwner {
    transferOwnership(addr);
  }

  /** @notice Deposit ETH/BNB into the Lottery Pot subcontract.
  *
  * Emits a {depositFounds} event.
  */
  function deposit() public payable {
    emit depositFounds(msg.value);
  }

  /** @notice This function must be called by the token contract when defining a
  * winner for the lottery. Send the funds in ETH/BNB to the given recipient.
  *
  * @param reciever Address that will receive the balance in ETH/BNB.
  *
  * Requirements:
  *
  * - Must be executed by the contract owner (Token contract).
  */
  function withdraw(address reciever) external onlyOwner nonReentrant {
    uint256 balance = address(this).balance;
    (bool success,) = reciever.call{value: address(this).balance, gas: 3000}("");
    if (success){
        totalRewardsGiven += balance;
        emit rewardSent(reciever, balance);    
    }
  }

  /** @notice The subcontract can receive ETH/BNB.
  */
  receive() external payable {
    deposit();
  }

}