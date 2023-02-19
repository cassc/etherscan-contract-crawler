// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// openzeppelin contracts
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Uniswap V2
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IUniswapV2Factory.sol";

// interface and library
import "../interfaces/IKochiLock.sol";
import "../libraries/LTransfers.sol";

// hardhat tools
// DEV ENVIRONMENT ONLY
import "hardhat/console.sol";

// this contract allows to lock liquidity cheaply and on multiple DEXs
contract KochiLock is ContextUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, IKochiLock {
  // constants
  address private constant DEAD = 0x0000000000000000000000000000000000000000;

  // using enums allows for no memory initializaton, it is more efficient, and less error prone
  // is also allows for complex mappings, as nesting structs is not allowed in solidity and upgradable contracts
  // Beneficiary -> Metadata
  mapping(address => SLPLockMetadata[]) public lpUserLocks;
  mapping(address => uint256) public lpAmountLocked;

  mapping(address => SLockMetadata[]) public userLocks;
  mapping(address => uint256) public amountLocked;

  mapping(string => SDEX) public DEXs;

  // upgradable gap
  uint256[50] private _gap;

  // constructor
  function initialize(string[] calldata names, address[] calldata routers) external initializer {
    for (uint256 i = 0; i < names.length; i++) {
      _addDEX(names[i], routers[i]);
    }

    __Context_init();
    __Ownable_init();
    __Pausable_init();
    __ReentrancyGuard_init();
  }

  //////////////////////////////////////////////////////////////////////////////
  // LP locking functions
  //////////////////////////////////////////////////////////////////////////////

  // to burn, simply set the beneficiary to address(0)
  function lpLock(
    address token0,
    address token1,
    uint256 amount0,
    uint256 amount1,
    uint256 lock_per_mille,
    address beneficiary,
    string memory dex,
    uint256 deadline
  ) external override nonReentrant whenNotPaused {
    // no need to check the tokens, as this is done below with (internalTransferFrom)
    require(amount0 > 0 && amount1 > 0, "ERROR: amount is zero");
    require(lock_per_mille <= 1000, "ERROR: invalid lock percentage");
    require(_isDexSupported(dex), "ERROR: DEX does not exist");

    // send the tokens to this address, revert if it fails
    LTransfers.internalTransferFrom(_msgSender(), address(this), amount0, IERC20(token0));
    LTransfers.internalTransferFrom(_msgSender(), address(this), amount1, IERC20(token1));

    // no need to check if the pair exists as the addLiquidity creates it if it doesn't exist
    // approve the router & add the liquidity.
    require(IERC20(token0).approve(DEXs[dex].router, amount0), "ERROR: approve failed");
    require(IERC20(token1).approve(DEXs[dex].router, amount1), "ERROR: approve failed");

    // context for stack size
    SLPLockMetadata memory metadata = SLPLockMetadata(token0, token1, 0, 0, address(0x0), 0, deadline);

    {
      (uint256 _amount0, uint256 _amount1, uint256 liquidity) = IUniswapV2Router02(DEXs[dex].router).addLiquidity(token0, token1, amount0, amount1, 0, 0, address(this), block.timestamp);

      metadata.amount0 = _amount0;
      metadata.amount1 = _amount1;
      metadata.liquidity = liquidity;
      metadata.pair = IUniswapV2Factory(DEXs[dex].factory).getPair(token0, token1);

      // CKL-02
      if (_amount0 < amount0) LTransfers.internalTransferTo(_msgSender(), amount0 - _amount0, IERC20(token0));
      if (_amount1 < amount1) LTransfers.internalTransferTo(_msgSender(), amount1 - _amount1, IERC20(token1));
    }

    uint256 remaining_liquidity = _setMetadataAndGetRemainingLiquidity(beneficiary, lock_per_mille, metadata);

    // setting the lock_per_mille to 0 will send all the liquidity to the beneficiary instead of locking it. Useless for customers, useful for the contract interactions.
    if (remaining_liquidity > 0) {
      LTransfers.internalTransferTo(beneficiary, remaining_liquidity, IERC20(metadata.pair));
    }

    console.log("test 4");
  }

  function lpLockETH(address token, uint256 amount, uint256 lock_per_mille, address beneficiary, string memory dex, uint256 deadline) external payable override nonReentrant whenNotPaused {
    // no need to check the tokens, as this is done below with (internalTransferFrom)
    require(amount > 0 && msg.value > 0, "ERROR: amount is zero");
    require(lock_per_mille <= 1000, "ERROR: invalid lock percentage");
    require(_isDexSupported(dex), "ERROR: DEX does not exist");

    // send the tokens to this address, revert if it fails
    LTransfers.internalTransferFrom(_msgSender(), address(this), amount, IERC20(token));

    // no need to check if the pair exists as the addLiquidity creates it if it doesn't exist
    // approve the router & add the liquidity.
    require(IERC20(token).approve(DEXs[dex].router, amount), "ERROR: approve failed");

    // empty metadata, as the liqudity has not yet been added.
    SLPLockMetadata memory metadata = SLPLockMetadata(DEXs[dex].WETH, token, 0, 0, address(0), 0, deadline);

    // context for stack size
    {
      (uint256 amount_token, uint256 amount_eth, uint256 liquidity) = IUniswapV2Router02(DEXs[dex].router).addLiquidityETH{value: msg.value}(token, amount, 0, 0, address(this), block.timestamp);

      metadata.amount0 = amount_eth;
      metadata.amount1 = amount_token;
      metadata.liquidity = liquidity;
      metadata.pair = IUniswapV2Factory(DEXs[dex].factory).getPair(DEXs[dex].WETH, token);

      // CKL-02
      if (amount_eth < msg.value) LTransfers.internalTransferToETH(_msgSender(), msg.value - amount_eth);
      if (amount_token < amount) LTransfers.internalTransferTo(_msgSender(), amount - amount_token, IERC20(token));
    }

    uint256 remaining_liquidity = _setMetadataAndGetRemainingLiquidity(beneficiary, lock_per_mille, metadata);

    // setting the lock_per_mille to 0 will send all the liquidity to the beneficiary instead of locking it. Useless for customers, useful for the contract interactions.
    if (remaining_liquidity > 0) {
      LTransfers.internalTransferTo(beneficiary, remaining_liquidity, IERC20(metadata.pair));
    }
  }

  function _setMetadataAndGetRemainingLiquidity(address beneficiary, uint256 lock_per_mille, SLPLockMetadata memory metadata) private returns (uint256 remaining_liquidity) {
    if (lock_per_mille != 0) {
      // change token metadata
      // lock per mille allows to add all Liquidity in a single call (even the one that isn't locked)
      // allowing the amount_min to be exactly the same as amount on pair creation.

      uint256 lock_liquidity = (metadata.liquidity * lock_per_mille) / 1000;
      remaining_liquidity = metadata.liquidity - lock_liquidity;

      {
        metadata.amount0 = (metadata.amount0 * lock_per_mille) / 1000;
        metadata.amount1 = (metadata.amount1 * lock_per_mille) / 1000;
        metadata.liquidity = lock_liquidity;

        lpUserLocks[beneficiary].push(metadata);
        lpAmountLocked[metadata.token0] += metadata.amount0;
        lpAmountLocked[metadata.token1] += metadata.amount1;

        uint256 uid = lpUserLocks[beneficiary].length - 1;

        emit LockedLiquidity(beneficiary, uid, metadata.token0, metadata.token1, metadata.amount0, metadata.amount1, metadata.pair, metadata.liquidity, metadata.deadline);
      }

      // send back the remaining LP tokens
      return remaining_liquidity;
    } else {
      return metadata.liquidity;
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // token locking functions
  //////////////////////////////////////////////////////////////////////////////

  function lock(address token, uint256 amount, address beneficiary, uint256 deadline) external override nonReentrant whenNotPaused {
    require(token != address(0), "ERROR: token is zero address");
    require(amount > 0, "ERROR: amount is zero");

    LTransfers.internalTransferFrom(_msgSender(), address(this), amount, IERC20(token));

    _setMetadata(beneficiary, token, amount, deadline);
  }

  function lockETH(address beneficiary, uint256 deadline) external payable override nonReentrant whenNotPaused {
    require(msg.value > 0, "ERROR: amount is zero");
    _setMetadata(beneficiary, address(0), msg.value, deadline);
  }

  function _setMetadata(address beneficiary, address token, uint256 amount, uint256 deadline) private {
    SLockMetadata memory metadata = SLockMetadata(token, amount, deadline);
    userLocks[beneficiary].push(metadata);
    amountLocked[token] += amount;

    emit LockedTokens(beneficiary, userLocks[beneficiary].length - 1, metadata.token, metadata.amount, metadata.deadline);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Unlocking functions
  //////////////////////////////////////////////////////////////////////////////

  function getUnlockedLiquidity(address beneficiary, address pair) external view override returns (uint256 liquidity) {
    liquidity = 0; // just to be sure

    for (uint256 i = 0; i < lpUserLocks[beneficiary].length; i++) {
      SLPLockMetadata memory metadata = lpUserLocks[beneficiary][i];

      // "can retreive" checks
      if (metadata.deadline < block.timestamp && metadata.liquidity > 0 && metadata.pair == pair) liquidity += metadata.liquidity;
    }

    return liquidity;
  }

  function unlock(uint256 uid) external override nonReentrant returns (uint256 amount) {
    amount = 0; // just to be sure

    // check if the liquidity at uid exists
    require(userLocks[_msgSender()].length > uid, "ERROR: no amount to unlock");
    SLockMetadata memory locked = userLocks[_msgSender()][uid];

    if (userLocks[_msgSender()][uid].deadline < block.timestamp) {
      amountLocked[locked.token] -= userLocks[_msgSender()][uid].amount;
      amount += userLocks[_msgSender()][uid].amount;
      userLocks[_msgSender()][uid].amount = 0;

      emit UnlockedTokens(_msgSender(), locked.token, uid, amount, block.timestamp);
    }

    require(amount > 0, "ERROR: no amount to unlock");
    if (locked.token == address(0)) LTransfers.internalTransferToETH(_msgSender(), amount);
    else LTransfers.internalTransferTo(_msgSender(), amount, IERC20(locked.token));

    return amount;
  }

  function lpUnlock(uint256 uid) external override nonReentrant returns (uint256 liquidity) {
    liquidity = 0; // just to be sure

    // check if the liquidity at uid exists
    require(lpUserLocks[_msgSender()].length > uid, "ERROR: no amount to unlock");
    SLPLockMetadata memory metadata = lpUserLocks[_msgSender()][uid];

    // "can retreive" checks
    if (metadata.deadline < block.timestamp && metadata.liquidity > 0) {
      lpAmountLocked[metadata.token0] -= metadata.amount0;
      lpAmountLocked[metadata.token1] -= metadata.amount1;
      liquidity += metadata.liquidity;

      // this makes it impossible to unlock the same pair twice
      lpUserLocks[_msgSender()][uid].liquidity = 0;

      emit UnlockedLiquidity(_msgSender(), metadata.pair, uid, metadata.token0, metadata.token1, metadata.amount0, metadata.amount1, metadata.liquidity, block.timestamp);
    }

    require(liquidity > 0, "ERROR: no amount to unlock");

    // transfer the LP Tokens
    LTransfers.internalTransferTo(_msgSender(), liquidity, IERC20(metadata.pair));

    return liquidity;
  }

  //////////////////////////////////////////////////////////////////////////////
  // GETTERS
  //////////////////////////////////////////////////////////////////////////////

  function getUnlockedTokens(address beneficiary, address token) external view override returns (uint256 tokens) {
    tokens = 0;

    for (uint256 i = 0; i < userLocks[beneficiary].length; i++) {
      if (userLocks[beneficiary][i].token == token && userLocks[beneficiary][i].deadline < block.timestamp) {
        tokens += userLocks[beneficiary][i].amount;
      }
    }

    return tokens;
  }

  function _isDexSupported(string memory dex) private view returns (bool) {
    return DEXs[dex].factory != DEAD && DEXs[dex].router != DEAD;
  }

  function isDexSupported(string memory dex) external view override returns (bool) {
    return _isDexSupported(dex);
  }

  //////////////////////////////////////////////////////////////////////////////
  // KOCHI SUPPORT
  //////////////////////////////////////////////////////////////////////////////

  // Kochi reserves itself the right to pause the contract is case of extreme emergency to stop further purchases. Users can still unlock their tokens, but cannot lock any more.
  function setPaused(bool pause) external onlyOwner {
    if (pause) _pause();
    else _unpause();
  }

  function _addDEX(string memory name, address router) private {
    DEXs[name] = SDEX(IUniswapV2Router02(router).factory(), router, IUniswapV2Router02(router).WETH());
  }

  function addDEX(string calldata name, address router) external onlyOwner {
    _addDEX(name, router);
  }

  receive() external payable {}

  fallback() external payable {}
}