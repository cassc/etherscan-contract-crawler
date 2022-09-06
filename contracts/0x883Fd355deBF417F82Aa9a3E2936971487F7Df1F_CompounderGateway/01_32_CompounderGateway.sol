// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../concentrator/interfaces/IAladdinCompounder.sol";
import "../zap/TokenZapLogic.sol";
import "./ZapGatewayBase.sol";

contract CompounderGateway is ZapGatewayBase {
  using SafeERC20 for IERC20;

  constructor(address _logic) {
    logic = _logic;
  }

  /// @notice Deposit `_srcToken` into Compounder with zap.
  /// @param _compounder The address of Compounder.
  /// @param _srcToken The address of start token. Use zero address, if you want deposit with ETH.
  /// @param _amountIn The amount of `_srcToken` to deposit.
  /// @param _routes The routes used to do zap.
  /// @param _minShareOut The minimum amount of pool shares should receive.
  /// @return The amount of pool shares received.
  function deposit(
    address _compounder,
    address _srcToken,
    uint256 _amountIn,
    uint256[] calldata _routes,
    uint256 _minShareOut
  ) external payable returns (uint256) {
    require(_amountIn > 0, "deposit zero amount");
    address _lpToken = IAladdinCompounder(_compounder).asset();

    // 1. transfer srcToken into this contract
    _amountIn = _transferTokenIn(_srcToken, _amountIn);

    // 2. zap srcToken to lp
    uint256 _amountLP = _zap(_routes, _amountIn);
    require(IERC20(_lpToken).balanceOf(address(this)) >= _amountLP, "zap to lp token failed");

    // 3. deposit into Concentrator vault
    IERC20(_lpToken).safeApprove(_compounder, 0);
    IERC20(_lpToken).safeApprove(_compounder, _amountLP);
    uint256 _sharesOut = IAladdinCompounder(_compounder).deposit(_amountLP, msg.sender);

    require(_sharesOut >= _minShareOut, "insufficient share");
    return _sharesOut;
  }

  /// @notice Withdraw asset from Compounder and zap to `_dstToken`.
  /// @param _compounder The address of Compounder.
  /// @param _dstToken The address of destination token. Use zero address, if you want withdraw as ETH.
  /// @param _sharesIn The amount of pool share to withdraw.
  /// @param _routes The routes used to do zap.
  /// @param _minAmountOut The minimum amount of assets should receive.
  /// @return The amount of assets received.
  function withdraw(
    address _compounder,
    address _dstToken,
    uint256 _sharesIn,
    uint256[] calldata _routes,
    uint256 _minAmountOut
  ) external returns (uint256) {
    if (_sharesIn == uint256(-1)) {
      _sharesIn = IERC20(_compounder).balanceOf(msg.sender);
    }

    require(_sharesIn > 0, "withdraw zero amount");

    // 1. withdraw from Compounder
    uint256 _amountLP = IAladdinCompounder(_compounder).redeem(_sharesIn, address(this), msg.sender);

    // 2. zap to dstToken
    uint256 _amountOut = _zap(_routes, _amountLP);
    require(_amountOut >= _minAmountOut, "insufficient output");

    // 3. transfer to caller.
    _transferTokenOut(_dstToken, _amountOut);

    return _amountOut;
  }
}