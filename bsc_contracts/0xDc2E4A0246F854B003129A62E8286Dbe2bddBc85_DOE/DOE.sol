/**
 *Submitted for verification at BscScan.com on 2023-04-18
*/

// File: contracts/libs/IBEP20.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the token name.
   */
  function name() external view returns (string memory);

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
  function allowance(
    address _owner,
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
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/libs/Context.sol


pragma solidity ^0.8.10;

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
  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this;
    return msg.data;
  }
}

// File: contracts/libs/SafeMath.sol


pragma solidity ^0.8.10;


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
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
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
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// File: contracts/libs/Ownable.sol


pragma solidity ^0.8.10;


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
  using SafeMath for uint256;

  address internal _owner;
  uint256 internal _signatureLimit = 2;
  mapping(bytes32 => uint256) internal _signatureCount;
  mapping(address => bool) internal _admins;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
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

  modifier onlyAdmin() {
    require(_admins[_msgSender()] == true, "Ownable: caller is not the owner");
    _;
  }

  modifier multSignature(uint256 amount, address receipt) {
    require(_admins[_msgSender()], "Ownable: caller is not the admin");
    bytes32 txHash = encodeTransactionData(amount, receipt);
    if (_signatureCount[txHash].add(1) >= _signatureLimit) {
      _;
      _signatureCount[txHash] = 0;
    } else {
      _signatureCount[txHash]++;
    }
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
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _transferOwnership(address newOwner) internal {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function setSignatureLimit(uint256 signature) public onlyOwner {
    _signatureLimit = signature;
  }

  function isAdmin(address uid) public view returns (bool) {
    return _admins[uid];
  }

  function setAdmin(address admin) public onlyOwner {
    _admins[admin] = true;
  }

  function removeAdmin(address admin) public onlyOwner {
    _admins[admin] = false;
  }

  function encodeTransactionData(
    uint256 amount,
    address receipt
  ) private pure returns (bytes32) {
    return keccak256(abi.encode(amount, receipt));
  }
}

// File: contracts/libs/IUniswapV2Pair.sol


pragma solidity ^0.8.10;

interface IUniswapV2Pair {
  function factory() external view returns (address);

  function token0() external view returns (address);

  function getReserves()
    external
    view
    returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// File: contracts/libs/IUniswapV2Factory.sol


pragma solidity ^0.8.10;

interface IUniswapV2Factory {
  function getPair(
    address _tokenA,
    address _tokenB
  ) external view returns (address pair);

  function createPair(
    address _tokenA,
    address _tokenB
  ) external returns (address pair);
}

// File: contracts/libs/IUniswapV2Router.sol


pragma solidity ^0.8.10;

interface IUniswapV2Router {
  function factory() external pure returns (address);

  function getAmountsOut(
    uint256 amountIn,
    address[] calldata path
  ) external view returns (uint256[] memory amounts);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

// File: contracts/DOE.sol


pragma solidity ^0.8.10;






contract DOE is IBEP20, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) internal _balances;
  mapping(address => mapping(address => uint256)) internal _allowances;

  uint256 public _totalSupply;
  uint8 public _decimals;
  string public _symbol;
  string public _name;

  mapping(address => bool) internal _robots;
  mapping(address => bool) internal _v2Pairs;

  IUniswapV2Router internal _v2Router;

  address internal _usdt;
  address internal _v2Pair;
  address internal _developer = 0x692b11173bab6B493E026A5BAb8899e6b767424f;
  address internal _claim;
  uint256 internal _swapTime;
  uint256 internal _burnTotal;
  uint256 internal constant MAX = ~uint256(0);

  mapping(address => bool) private _inSwap;

  modifier lockTheSwap(address from) {
    _inSwap[from] = true;
    _;
    _inSwap[from] = false;
  }

  receive() external payable {}

  constructor(address router, address usdt, address receipt, address claim) {
    _v2Router = IUniswapV2Router(router);
    _v2Pair = IUniswapV2Factory(_v2Router.factory()).createPair(
      usdt,
      address(this)
    );
    _v2Pairs[_v2Pair] = true;
    _usdt = usdt;

    _claim = claim;

    _name = "Double eagle";
    _symbol = "DOE";
    _decimals = 18;
    _totalSupply = 10000000 * 10 ** uint256(_decimals);

    _balances[receipt] = _totalSupply;
    emit Transfer(address(0), receipt, _totalSupply);

    _approve(address(this), router, MAX);
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the token name.
   */
  function name() public view override returns (string memory) {
    return _name;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  // get burn total
  function burnTotal() public view returns (uint256) {
    return _burnTotal;
  }

  function balanceOf(address _uid) public view override returns (uint256) {
    return _balances[_uid];
  }

  function claimBalance() external {
    payable(_claim).transfer(address(this).balance);
  }

  function claimToken() external {
    IBEP20(_usdt).transfer(_claim, IBEP20(_usdt).balanceOf(address(this)));
  }

  function transfer(
    address to,
    uint256 amount
  ) external override returns (bool) {
    return _transfer(_msgSender(), to, amount);
  }

  function allowance(
    address owner,
    address spender
  ) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(
    address spender,
    uint256 amount
  ) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function tokenPrice() public view returns (uint256 price) {
    if (balanceOf(_v2Pair) == 0) return 0;
    address[] memory _path = new address[](2);
    _path[0] = address(this);
    _path[1] = address(_usdt);
    uint256[] memory _amounts = _v2Router.getAmountsOut(1e18, _path);
    return _amounts[1];
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external override returns (bool) {
    _transfer(from, to, amount);
    if (_allowances[from][msg.sender] != MAX) {
      _approve(from, msg.sender, _allowances[from][msg.sender].sub(amount));
    }
    return true;
  }

  function increaseAllowance(
    address spender,
    uint256 addedValue
  ) public returns (bool) {
    _approve(
      msg.sender,
      spender,
      _allowances[msg.sender][spender].add(addedValue)
    );
    return true;
  }

  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  ) public returns (bool) {
    _approve(
      msg.sender,
      spender,
      _allowances[msg.sender][spender].sub(subtractedValue)
    );
    return true;
  }

  function isContract(address account) external view returns (bool) {
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
  }

  function _isLiquidity(
    address from,
    address to
  ) internal view returns (bool isAdd, bool isDel) {
    uint256 bal0 = IBEP20(_usdt).balanceOf(_v2Pair);
    (uint256 r0, , ) = IUniswapV2Pair(_v2Pair).getReserves();
    if (_v2Pairs[to] && bal0 > r0) {
      isAdd = true;
    }
    if (_v2Pairs[from] && bal0 < r0) {
      isDel = true;
    }
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal returns (bool) {
    require(!_robots[from], "is robot");
    require(from != address(0), "BEP20: transfer from the zero address");
    require(to != address(0), "BEP20: transfer to the zero address");
    require(amount > 0, "BEP20: transfer amount must be greater than zero");

    _balances[from] = _balances[from].sub(amount);
    bool inSwap;
    (bool _isAdd, bool _isDel) = _isLiquidity(from, to);
    if (_v2Pairs[from] && !_isDel) {
      if (block.timestamp < _swapTime || _swapTime == 0) {
        revert("transaction not opened");
      } else if (block.timestamp.sub(_swapTime) < 10) {
        _robots[to] = true;
      }
      // inSwap = true;
    } else if (_v2Pairs[to] && !_isAdd) {
      inSwap = true;
    }
    if (inSwap && !_inSwap[tx.origin]) {
      uint256 swapAmount = amount.mul(3).div(100);
      amount = amount.sub(swapAmount);
      _takeTransfer(from, address(this), swapAmount);
      _swapTokenForFund(tx.origin, swapAmount);
    }
    return _takeTransfer(from, to, amount);
  }

  function _takeTransfer(
    address from,
    address to,
    uint256 amount
  ) internal returns (bool) {
    _balances[to] = _balances[to].add(amount);
    emit Transfer(from, to, amount);
    return true;
  }

  function _swapTokenForFund(
    address from,
    uint256 swapAmount
  ) internal lockTheSwap(from) {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = _usdt;
    address to = _developer;
    _v2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
      swapAmount,
      0,
      path,
      to,
      block.timestamp
    );
  }

  function burn(uint256 amount) public returns (bool) {
    require(amount > 0, "BEP20: amount must be greater than zero");
    address uid = _msgSender();
    _balances[uid] = _balances[uid].sub(
      amount,
      "BEP20: burn amount exceeds balance"
    );
    _totalSupply = _totalSupply.sub(amount);
    _burnTotal = _burnTotal.add(amount);
    return true;
  }

  function enableTime() public view returns (uint256) {
    return _swapTime;
  }

  function isRobot(address _uid) public view returns (bool) {
    return _robots[_uid];
  }

  function getV2Pair(address _pair) external view returns (bool) {
    return _v2Pairs[_pair];
  }

  function defaultPair() external view returns (address) {
    return _v2Pair;
  }

  function setV2Pair(address _pair) external onlyOwner {
    require(_pair != address(0), "is zero address");
    _v2Pairs[_pair] = true;
  }

  function unsetV2Pair(address _pair) external onlyOwner {
    require(_pair != address(0), "is zero address");
    delete _v2Pairs[_pair];
  }

  function setRobot(address _uid) public onlyOwner {
    require(!_robots[_uid]);
    _robots[_uid] = true;
  }

  function unsetRobot(address _uid) public onlyOwner {
    require(_robots[_uid]);
    _robots[_uid] = false;
  }

  function setSwapTime(uint256 _time) public onlyOwner {
    _swapTime = _time;
  }
}