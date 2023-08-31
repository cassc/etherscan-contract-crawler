/**
 *Submitted for verification at Etherscan.io on 2023-08-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface ITokenLockerManagerV1 {
  function tokenLockerCount() external view returns (uint40);
  function lpLockerCount() external view returns (uint40);
  function creationEnabled() external view returns (bool);
  function setCreationEnabled(bool value_) external;
  function createTokenLocker(
    address tokenAddress_,
    uint256 amount_,
    uint40 unlockTime_
  ) external payable;
  function createLpLocker(
    address tokenAddress_,
    uint256 amount_,
    uint40 unlockTime_
  ) external payable;
  function getTokenLockAddress(uint40 id_) external view returns (address);
  function getLpLockAddress(uint40 id_) external view returns (address);
  function getTokenLockData(uint40 id_) external view returns (
    bool isLpToken,
    uint40 id,
    address contractAddress,
    address lockOwner,
    address token,
    address createdBy,
    uint40 createdAt,
    uint40 blockTime,
    uint40 unlockTime,
    uint256 balance,
    uint256 totalSupply
  );
  function getLpLockData(uint40 id_) external view returns (
    bool isLpToken,
    uint40 id,
    address contractAddress,
    address lockOwner,
    address token,
    address createdBy,
    uint40 createdAt,
    uint40 blockTime,
    uint40 unlockTime,
    uint256 balance,
    uint256 totalSupply
  );
  function getLpData(uint40 id_) external view returns (
    bool hasLpData,
    uint40 id,
    address token0,
    address token1,
    uint256 balance0,
    uint256 balance1,
    uint256 price0,
    uint256 price1
  );
  function getTokenLockersForAddress(address address_) external view returns (uint40[] memory);
  function getLpLockersForAddress(address address_) external view returns (uint40[] memory);
  function notifyTokenLockerOwnerChange(uint40 id_, address newOwner_, address previousOwner_, address createdBy_) external;
  function notifyLpLockerOwnerChange(uint40 id_, address newOwner_, address previousOwner_, address createdBy_) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
  constructor(address owner_) {
    _owner_ = owner_;
    emit OwnershipTransferred(address(0), _owner());
  }

  address private _owner_;

  event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

  function _owner() internal view returns (address) {
    return _owner_;
  }

  function owner() external view returns (address) {
    return _owner();
  }

  modifier onlyOwner() {
    require(_owner() == _msgSender(), "Only the owner can execute this function");
    _;
  }

  function _transferOwnership(address newOwner_) virtual internal onlyOwner {
    // keep track of old owner for event
    address oldOwner = _owner();

    // set the new owner
    _owner_ = newOwner_;

    // emit event about ownership change
    emit OwnershipTransferred(oldOwner, _owner());
  }

  function transferOwnership(address newOwner_) external onlyOwner {
    _transferOwnership(newOwner_);
  }
}

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

interface IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Util {
  /**
   * @dev retrieves basic information about a token, including sender balance
   */
  function getTokenData(address address_) external view returns (
    string memory name,
    string memory symbol,
    uint8 decimals,
    uint256 totalSupply,
    uint256 balance
  ){
    IERC20 _token = IERC20(address_);

    name = _token.name();
    symbol = _token.symbol();
    decimals = _token.decimals();
    totalSupply = _token.totalSupply();
    balance = _token.balanceOf(msg.sender);
  }

  /**
   * @dev this throws an error on false, instead of returning false,
   * but can still be used the same way on frontend.
   */
  function isLpToken(address address_) external view returns (bool) {
    IUniswapV2Pair pair = IUniswapV2Pair(address_);

    try pair.token0() returns (address tokenAddress_) {
      // any address returned successfully should be valid?
      // but we might as well check that it's not 0
      return tokenAddress_ != address(0);
    } catch Error(string memory /* reason */) {
      return false;
    } catch (bytes memory /* lowLevelData */) {
      return false;
    }
  }

  /**
   * @dev this function will revert the transaction if it's called
   * on a token that isn't an LP token. so, it's recommended to be
   * sure that it's being called on an LP token, or expect the error.
   */
  function getLpData(address address_) external view returns (
    address token0,
    address token1,
    uint256 balance0,
    uint256 balance1,
    uint256 price0,
    uint256 price1
  ) {
    IUniswapV2Pair _pair = IUniswapV2Pair(address_);

    token0 = _pair.token0();
    token1 = _pair.token1();

    balance0 = IERC20(token0).balanceOf(address(_pair));
    balance1 = IERC20(token1).balanceOf(address(_pair));

    price0 = _pair.price0CumulativeLast();
    price1 = _pair.price1CumulativeLast();
  }
}

contract TokenLockerV1 is Ownable {
  event Extended(uint40 newUnlockTime);
  event Deposited(uint256 amount);
  event Withdrew();

  constructor(address manager_, uint40 id_, address owner_, address tokenAddress_, uint40 unlockTime_) Ownable(owner_) {
    require(unlockTime_ > 0, "Unlock time must be in the future");

    _manager = ITokenLockerManagerV1(manager_);
    _id = id_;
    _token = IERC20(tokenAddress_);
    _createdBy = owner_;
    _createdAt = uint40(block.timestamp);
    _unlockTime = unlockTime_;
    _isLpToken = Util.isLpToken(tokenAddress_);
  }

  ITokenLockerManagerV1 private _manager;
  bool private _isLpToken;
  uint40 private _id;
  IERC20 private _token;
  address private _createdBy;
  uint40 private _createdAt;
  uint40 private _unlockTime;

  bool private _transferLocked;

  modifier transferLocked() {
    require(!_transferLocked, "Transfering is locked. Wait for the previous transaction to complete");
    _transferLocked = true;
    _;
    _transferLocked = false;
  }

  function _balance() private view returns (uint256) {
    return _token.balanceOf(address(this));
  }

  function getIsLpToken() external view returns (bool) {
    return _isLpToken;
  }

  function getLockData() external view returns (
    bool isLpToken,
    uint40 id,
    address contractAddress,
    address lockOwner,
    address token,
    address createdBy,
    uint40 createdAt,
    uint40 blockTime,
    uint40 unlockTime,
    uint256 balance,
    uint256 totalSupply
  ){
    isLpToken = _isLpToken;
    id = _id;
    contractAddress = address(this);
    lockOwner = _owner();
    token = address(_token);
    createdBy = _createdBy;
    createdAt = _createdAt;
    blockTime = uint40(block.timestamp);
    unlockTime = _unlockTime;
    balance = _balance();
    totalSupply = _token.totalSupply();
  }

  function getLpData() external view returns (
    bool hasLpData,
    uint40 id,
    address token0,
    address token1,
    uint256 balance0,
    uint256 balance1,
    uint256 price0,
    uint256 price1
  ) {
    // always return the id
    id = _id;

    if (!_isLpToken) {
      // if this isn't an lp token, don't even bother calling getLpData
      hasLpData = false;
    } else {
      // this is an lp token, so let's get some data
      try Util.getLpData(address(_token)) returns (
        address token0_,
        address token1_,
        uint256 balance0_,
        uint256 balance1_,
        uint256 price0_,
        uint256 price1_
      ){
        hasLpData = true;
        token0 = token0_;
        token1 = token1_;
        balance0 = balance0_;
        balance1 = balance1_;
        price0 = price0_;
        price1 = price1_;
      } catch Error(string memory /* reason */) {
        hasLpData = false;
      } catch (bytes memory /* lowLevelData */) {
        hasLpData = false;
      }
    }
  }

  /**
   * @dev deposit and extend duration in one call
   */
  function deposit(uint256 amount_, uint40 newUnlockTime_) external onlyOwner transferLocked {
    if (newUnlockTime_ != 0) {
      require(
        newUnlockTime_ >= _unlockTime && newUnlockTime_ >= uint40(block.timestamp),
        "New unlock time must be a future time beyond the previous value"
      );
      _unlockTime = newUnlockTime_;
      emit Extended(_unlockTime);
    }

    if (amount_ != 0) {
      uint256 oldBalance = _balance();
      _token.transferFrom(_msgSender(), address(this), amount_);
      emit Deposited(_balance() - oldBalance);
    }
  }

  /**
   * @dev withdraw all of the deposited token
   */
  function withdraw() external onlyOwner transferLocked {
    require(uint40(block.timestamp) >= _unlockTime, "Wait until unlockTime to withdraw ");

    _token.transfer(_owner(), _balance());

    emit Withdrew();
  }

  /**
   * @dev recovery function -
   * just in case this contract winds up with additional tokens (from dividends, etc).
   * attempting to withdraw the locked token will revert.
   */
  function withdrawToken(address address_) external onlyOwner transferLocked {
    require(address_ != address(_token), "Use 'withdraw' to withdraw the primary locked token");

    IERC20 theToken = IERC20(address_);
    theToken.transfer(_owner(), theToken.balanceOf(address(this)));
  }

  /**
   * @dev recovery function -
   * just in case this contract winds up with eth in it (from dividends etc)
   */
  function withdrawEth() external onlyOwner transferLocked {
    address payable receiver = payable(_owner());
    receiver.transfer(address(this).balance);
  }

  function _transferOwnership(address newOwner_) override internal onlyOwner {
    address previousOwner = _owner();
    super._transferOwnership(newOwner_);

    // we need to notify the manager contract that we transferred
    // ownership, so that the new owner is searchable.
    if (_isLpToken)
      _manager.notifyLpLockerOwnerChange(_id, newOwner_, previousOwner, _createdBy);
    else
      _manager.notifyTokenLockerOwnerChange(_id, newOwner_, previousOwner, _createdBy);
  }

  receive() external payable {
    // we need this function to receive eth,
    // which might happen from dividend tokens.
    // use `withdrawEth` to remove eth from the contract.
  }
}