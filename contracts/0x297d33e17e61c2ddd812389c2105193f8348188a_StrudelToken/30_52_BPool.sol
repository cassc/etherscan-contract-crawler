// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "../balancer/BMath.sol";
import "../balancer/IBPool.sol";

contract BPool is ERC20UpgradeSafe, BMath, IBPool {
  struct Record {
    bool bound; // is token bound to pool
    uint256 index; // private
    uint256 denorm; // denormalized weight
    uint256 balance;
  }

  event LOG_SWAP(
    address indexed caller,
    address indexed tokenIn,
    address indexed tokenOut,
    uint256 tokenAmountIn,
    uint256 tokenAmountOut
  );

  event LOG_JOIN(address indexed caller, address indexed tokenIn, uint256 tokenAmountIn);

  event LOG_EXIT(address indexed caller, address indexed tokenOut, uint256 tokenAmountOut);

  event LOG_CALL(bytes4 indexed sig, address indexed caller, bytes data);

  modifier _logs_() {
    emit LOG_CALL(msg.sig, msg.sender, msg.data);
    _;
  }

  modifier _lock_() {
    require(!_mutex, "ERR_REENTRY");
    _mutex = true;
    _;
    _mutex = false;
  }

  modifier _viewlock_() {
    require(!_mutex, "ERR_REENTRY");
    _;
  }

  bool private _mutex;

  address private _factory; // BFactory address to push token exitFee to
  address private _controller; // has CONTROL role
  bool private _publicSwap; // true if PUBLIC can call SWAP functions

  // `setSwapFee` and `finalize` require CONTROL
  // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
  uint256 private _swapFee;
  bool private _finalized;

  address[] private _tokens;
  mapping(address => Record) private _records;
  uint256 private _totalWeight;

  constructor(address controller) public {
    _controller = controller;
    _factory = msg.sender;
    _swapFee = MIN_FEE;
    _publicSwap = false;
    _finalized = false;
    __ERC20_init("poolName", "POS");
  }

  /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                ( bI / wI )         1                                  //
    // bO = tokenBalanceOut         sP =  -----------  *  ----------                             //
    // wI = tokenWeightIn                 ( bO / wO )     ( 1 - sF )                             //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
  function calcSpotPrice(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 swapFee
  ) internal pure returns (uint256 spotPrice) {
    uint256 numer = bdiv(tokenBalanceIn, tokenWeightIn);
    uint256 denom = bdiv(tokenBalanceOut, tokenWeightOut);
    uint256 ratio = bdiv(numer, denom);
    uint256 scale = bdiv(BONE, bsub(BONE, swapFee));
    return (spotPrice = bmul(ratio, scale));
  }

  /**********************************************************************************************
    // calcOutGivenIn                                                                            //
    // aO = tokenAmountOut                                                                       //
    // bO = tokenBalanceOut                                                                      //
    // bI = tokenBalanceIn              /      /            bI             \    (wI / wO) \      //
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  | ^            |     //
    // wI = tokenWeightIn               \      \ ( bI + ( aI * ( 1 - sF )) /              /      //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
  function calcOutGivenIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) internal pure returns (uint256 tokenAmountOut) {
    uint256 weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
    uint256 adjustedIn = bsub(BONE, swapFee);
    adjustedIn = bmul(tokenAmountIn, adjustedIn);
    uint256 y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
    uint256 foo = bpow(y, weightRatio);
    uint256 bar = bsub(BONE, foo);
    tokenAmountOut = bmul(tokenBalanceOut, bar);
    return tokenAmountOut;
  }

  function isPublicSwap() external override view returns (bool) {
    return _publicSwap;
  }

  function isFinalized() external view returns (bool) {
    return _finalized;
  }

  function isBound(address t) external override view returns (bool) {
    return _records[t].bound;
  }

  function getNumTokens() external view returns (uint256) {
    return _tokens.length;
  }

  function getCurrentTokens() external override view _viewlock_ returns (address[] memory tokens) {
    return _tokens;
  }

  function getFinalTokens() external view _viewlock_ returns (address[] memory tokens) {
    require(_finalized, "ERR_NOT_FINALIZED");
    return _tokens;
  }

  function getDenormalizedWeight(address token)
    external
    override
    view
    _viewlock_
    returns (uint256)
  {
    require(_records[token].bound, "ERR_NOT_BOUND");
    return _records[token].denorm;
  }

  function getTotalDenormalizedWeight() external override view _viewlock_ returns (uint256) {
    return _totalWeight;
  }

  function getNormalizedWeight(address token) external view _viewlock_ returns (uint256) {
    require(_records[token].bound, "ERR_NOT_BOUND");
    uint256 denorm = _records[token].denorm;
    return bdiv(denorm, _totalWeight);
  }

  function getBalance(address token) external override view _viewlock_ returns (uint256) {
    require(_records[token].bound, "ERR_NOT_BOUND");
    return _records[token].balance;
  }

  function getSwapFee() external override view _viewlock_ returns (uint256) {
    return _swapFee;
  }

  function getController() external view _viewlock_ returns (address) {
    return _controller;
  }

  function setSwapFee(uint256 swapFee) external override _logs_ _lock_ {
    require(!_finalized, "ERR_IS_FINALIZED");
    require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
    require(swapFee >= MIN_FEE, "ERR_MIN_FEE");
    require(swapFee <= MAX_FEE, "ERR_MAX_FEE");
    _swapFee = swapFee;
  }

  function setController(address manager) external _logs_ _lock_ {
    require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
    _controller = manager;
  }

  function setPublicSwap(bool public_) external override _logs_ _lock_ {
    require(!_finalized, "ERR_IS_FINALIZED");
    require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
    _publicSwap = public_;
  }

  function finalize() external _logs_ _lock_ {
    require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
    require(!_finalized, "ERR_IS_FINALIZED");
    require(_tokens.length >= MIN_ASSET_LIMIT, "ERR_MIN_TOKENS");

    _finalized = true;
    _publicSwap = true;

    _mintPoolShare(MIN_POOL_SUPPLY);
    _pushPoolShare(msg.sender, MIN_POOL_SUPPLY);
  }

  function bind(
    address token,
    uint256 balance,
    uint256 denorm
  )
    external
    override
    _logs_ // _lock_  Bind does not lock because it jumps to `rebind`, which does
  {
    require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
    require(!_records[token].bound, "ERR_IS_BOUND");
    require(!_finalized, "ERR_IS_FINALIZED");

    require(_tokens.length < MAX_ASSET_LIMIT, "ERR_MAX_TOKENS");

    _records[token] = Record({
      bound: true,
      index: _tokens.length,
      denorm: 0, // balance and denorm will be validated
      balance: 0 // and set by `rebind`
    });
    _tokens.push(token);
    rebind(token, balance, denorm);
  }

  function rebind(
    address token,
    uint256 balance,
    uint256 denorm
  ) public override _logs_ _lock_ {
    require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
    require(_records[token].bound, "ERR_NOT_BOUND");
    require(!_finalized, "ERR_IS_FINALIZED");

    require(denorm >= MIN_WEIGHT, "ERR_MIN_WEIGHT");
    require(denorm <= MAX_WEIGHT, "ERR_MAX_WEIGHT");
    require(balance >= MIN_BALANCE, "ERR_MIN_BALANCE");

    // Adjust the denorm and totalWeight
    uint256 oldWeight = _records[token].denorm;
    if (denorm > oldWeight) {
      _totalWeight = badd(_totalWeight, bsub(denorm, oldWeight));
      require(_totalWeight <= MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");
    } else if (denorm < oldWeight) {
      _totalWeight = bsub(_totalWeight, bsub(oldWeight, denorm));
    }
    _records[token].denorm = denorm;

    // Adjust the balance record and actual token balance
    uint256 oldBalance = _records[token].balance;
    _records[token].balance = balance;
    if (balance > oldBalance) {
      _pullUnderlying(token, msg.sender, bsub(balance, oldBalance));
    } else if (balance < oldBalance) {
      // In this case liquidity is being withdrawn, so charge EXIT_FEE
      uint256 tokenBalanceWithdrawn = bsub(oldBalance, balance);
      uint256 tokenExitFee = bmul(tokenBalanceWithdrawn, EXIT_FEE);
      _pushUnderlying(token, msg.sender, bsub(tokenBalanceWithdrawn, tokenExitFee));
      _pushUnderlying(token, _factory, tokenExitFee);
    }
  }

  function unbind(address token) external override _logs_ _lock_ {
    require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
    require(_records[token].bound, "ERR_NOT_BOUND");
    require(!_finalized, "ERR_IS_FINALIZED");

    uint256 tokenBalance = _records[token].balance;
    uint256 tokenExitFee = bmul(tokenBalance, EXIT_FEE);

    _totalWeight = bsub(_totalWeight, _records[token].denorm);

    // Swap the token-to-unbind with the last token,
    // then delete the last token
    uint256 index = _records[token].index;
    uint256 last = _tokens.length - 1;
    _tokens[index] = _tokens[last];
    _records[_tokens[index]].index = index;
    _tokens.pop();
    _records[token] = Record({bound: false, index: 0, denorm: 0, balance: 0});

    _pushUnderlying(token, msg.sender, bsub(tokenBalance, tokenExitFee));
    _pushUnderlying(token, _factory, tokenExitFee);
  }

  // Absorb any tokens that have been sent to this contract into the pool
  function gulp(address token) external override _logs_ _lock_ {
    require(_records[token].bound, "ERR_NOT_BOUND");
    _records[token].balance = IERC20(token).balanceOf(address(this));
  }

  function getSpotPrice(address tokenIn, address tokenOut)
    external
    view
    _viewlock_
    returns (uint256 spotPrice)
  {
    require(_records[tokenIn].bound, "ERR_NOT_BOUND");
    require(_records[tokenOut].bound, "ERR_NOT_BOUND");
    Record storage inRecord = _records[tokenIn];
    Record storage outRecord = _records[tokenOut];
    return
      calcSpotPrice(
        inRecord.balance,
        inRecord.denorm,
        outRecord.balance,
        outRecord.denorm,
        _swapFee
      );
  }

  function getSpotPriceSansFee(address tokenIn, address tokenOut)
    external
    view
    _viewlock_
    returns (uint256 spotPrice)
  {
    require(_records[tokenIn].bound, "ERR_NOT_BOUND");
    require(_records[tokenOut].bound, "ERR_NOT_BOUND");
    Record storage inRecord = _records[tokenIn];
    Record storage outRecord = _records[tokenOut];
    return calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, 0);
  }

  function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external _logs_ _lock_ {
    require(_finalized, "ERR_NOT_FINALIZED");

    uint256 poolTotal = totalSupply();
    uint256 ratio = bdiv(poolAmountOut, poolTotal);
    require(ratio != 0, "ERR_MATH_APPROX");

    for (uint256 i = 0; i < _tokens.length; i++) {
      address t = _tokens[i];
      uint256 bal = _records[t].balance;
      uint256 tokenAmountIn = bmul(ratio, bal);
      require(tokenAmountIn != 0, "ERR_MATH_APPROX");
      require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");
      _records[t].balance = badd(_records[t].balance, tokenAmountIn);
      emit LOG_JOIN(msg.sender, t, tokenAmountIn);
      _pullUnderlying(t, msg.sender, tokenAmountIn);
    }
    _mintPoolShare(poolAmountOut);
    _pushPoolShare(msg.sender, poolAmountOut);
  }

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external _logs_ _lock_ {
    require(_finalized, "ERR_NOT_FINALIZED");

    uint256 poolTotal = totalSupply();
    uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);
    uint256 pAiAfterExitFee = bsub(poolAmountIn, exitFee);
    uint256 ratio = bdiv(pAiAfterExitFee, poolTotal);
    require(ratio != 0, "ERR_MATH_APPROX");

    _pullPoolShare(msg.sender, poolAmountIn);
    _pushPoolShare(_factory, exitFee);
    _burnPoolShare(pAiAfterExitFee);

    for (uint256 i = 0; i < _tokens.length; i++) {
      address t = _tokens[i];
      uint256 bal = _records[t].balance;
      uint256 tokenAmountOut = bmul(ratio, bal);
      require(tokenAmountOut != 0, "ERR_MATH_APPROX");
      require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");
      _records[t].balance = bsub(_records[t].balance, tokenAmountOut);
      emit LOG_EXIT(msg.sender, t, tokenAmountOut);
      _pushUnderlying(t, msg.sender, tokenAmountOut);
    }
  }

  function swapExactAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    address tokenOut,
    uint256 minAmountOut,
    uint256 maxPrice
  ) external override _logs_ _lock_ returns (uint256 tokenAmountOut, uint256 spotPriceAfter) {
    require(_records[tokenIn].bound, "ERR_NOT_BOUND");
    require(_records[tokenOut].bound, "ERR_NOT_BOUND");
    require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

    Record storage inRecord = _records[address(tokenIn)];
    Record storage outRecord = _records[address(tokenOut)];

    require(tokenAmountIn <= bmul(inRecord.balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

    uint256 spotPriceBefore = calcSpotPrice(
      inRecord.balance,
      inRecord.denorm,
      outRecord.balance,
      outRecord.denorm,
      _swapFee
    );
    require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

    tokenAmountOut = calcOutGivenIn(
      inRecord.balance,
      inRecord.denorm,
      outRecord.balance,
      outRecord.denorm,
      tokenAmountIn,
      _swapFee
    );
    require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

    inRecord.balance = badd(inRecord.balance, tokenAmountIn);
    outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

    spotPriceAfter = calcSpotPrice(
      inRecord.balance,
      inRecord.denorm,
      outRecord.balance,
      outRecord.denorm,
      _swapFee
    );
    require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
    require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
    require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");

    emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

    _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
    _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

    return (tokenAmountOut, spotPriceAfter);
  }

  function swapExactAmountOut(
    address tokenIn,
    uint256 maxAmountIn,
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPrice
  ) external _logs_ _lock_ returns (uint256 tokenAmountIn, uint256 spotPriceAfter) {
    require(_records[tokenIn].bound, "ERR_NOT_BOUND");
    require(_records[tokenOut].bound, "ERR_NOT_BOUND");
    require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

    Record storage inRecord = _records[address(tokenIn)];
    Record storage outRecord = _records[address(tokenOut)];

    require(tokenAmountOut <= bmul(outRecord.balance, MAX_OUT_RATIO), "ERR_MAX_OUT_RATIO");

    uint256 spotPriceBefore = calcSpotPrice(
      inRecord.balance,
      inRecord.denorm,
      outRecord.balance,
      outRecord.denorm,
      _swapFee
    );
    require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

    tokenAmountIn = calcInGivenOut(
      inRecord.balance,
      inRecord.denorm,
      outRecord.balance,
      outRecord.denorm,
      tokenAmountOut,
      _swapFee
    );
    require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

    inRecord.balance = badd(inRecord.balance, tokenAmountIn);
    outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

    spotPriceAfter = calcSpotPrice(
      inRecord.balance,
      inRecord.denorm,
      outRecord.balance,
      outRecord.denorm,
      _swapFee
    );
    require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
    require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
    require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");

    emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

    _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
    _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

    return (tokenAmountIn, spotPriceAfter);
  }

  // ==
  // 'Underlying' token-manipulation functions make external calls but are NOT locked
  // You must `_lock_` or otherwise ensure reentry-safety

  function _pullUnderlying(
    address erc20,
    address from,
    uint256 amount
  ) internal {
    bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
    require(xfer, "ERR_ERC20_FALSE");
  }

  function _pushUnderlying(
    address erc20,
    address to,
    uint256 amount
  ) internal {
    bool xfer = IERC20(erc20).transfer(to, amount);
    require(xfer, "ERR_ERC20_FALSE");
  }

  function _pullPoolShare(address from, uint256 amount) internal {
    _transfer(from, address(this), amount);
  }

  function _pushPoolShare(address to, uint256 amount) internal {
    _transfer(address(this), to, amount);
  }

  function _mintPoolShare(uint256 amount) internal {
    _mint(address(this), amount);
  }

  function _burnPoolShare(uint256 amount) internal {
    _burn(address(this), amount);
  }
}