// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

import { IERC20 } from "oz410/token/ERC20/IERC20.sol";
import { SafeERC20 } from "oz410/token/ERC20/SafeERC20.sol";
import { ICurvePool } from "../interfaces/ICurvePool.sol";
import { CurveLib } from "../libraries/CurveLib.sol";
import { SafeMath } from "oz410/math/SafeMath.sol";

contract ZeroCurveWrapper {
  bool public immutable underlying;
  uint256 public immutable tokenInIndex;
  uint256 public immutable tokenOutIndex;
  address public immutable tokenInAddress;
  address public immutable tokenOutAddress;
  address public immutable pool;
  bytes4 public immutable coinsUnderlyingSelector;
  bytes4 public immutable coinsSelector;
  bytes4 public immutable getDySelector;
  bytes4 public immutable exchangeSelector;

  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using CurveLib for CurveLib.ICurve;

  function getPool() internal view returns (CurveLib.ICurve memory result) {
    result = CurveLib.fromSelectors(
      pool,
      underlying,
      coinsSelector,
      coinsUnderlyingSelector,
      exchangeSelector,
      getDySelector
    );
  }

  constructor(
    uint256 _tokenInIndex,
    uint256 _tokenOutIndex,
    address _pool,
    bool _underlying
  ) {
    underlying = _underlying;
    tokenInIndex = _tokenInIndex;
    tokenOutIndex = _tokenOutIndex;
    pool = _pool;
    CurveLib.ICurve memory curve = CurveLib.duckPool(_pool, _underlying);
    coinsUnderlyingSelector = curve.coinsUnderlyingSelector;
    coinsSelector = curve.coinsSelector;
    exchangeSelector = curve.exchangeSelector;
    getDySelector = curve.getDySelector;
    address _tokenInAddress = tokenInAddress = curve.coins(_tokenInIndex);
    address _tokenOutAddress = tokenOutAddress = curve.coins(_tokenOutIndex);
    IERC20(_tokenInAddress).safeApprove(_pool, type(uint256).max / 2);
  }

  function estimate(uint256 _amount) public returns (uint256 result) {
    result = getPool().get_dy(tokenInIndex, tokenOutIndex, _amount);
  }

  function convert(address _module) external payable returns (uint256 _actualOut) {
    uint256 _balance = IERC20(tokenInAddress).balanceOf(address(this));
    uint256 _startOut = IERC20(tokenOutAddress).balanceOf(address(this));
    getPool().exchange(tokenInIndex, tokenOutIndex, _balance, _balance / 0x10);
    _actualOut = IERC20(tokenOutAddress).balanceOf(address(this)) - _startOut;
    IERC20(tokenOutAddress).safeTransfer(msg.sender, _actualOut);
  }

  receive() external payable {
    /* noop */
  }

  fallback() external payable {
    /* noop */
  }
}