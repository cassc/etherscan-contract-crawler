// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../concentrator/interfaces/IAladdinConvexVault.sol";
import "../zap/TokenZapLogic.sol";
import "./ZapGatewayBase.sol";

contract ConcentratorGateway is ZapGatewayBase {
  using SafeERC20 for IERC20;

  constructor(address _logic) {
    logic = _logic;
  }

  /// @notice Deposit `_srcToken` into Concentrator vault with zap.
  /// @param _vault The address of vault.
  /// @param _pid The pool id to deposit.
  /// @param _srcToken The address of start token. Use zero address, if you want deposit with ETH.
  /// @param _lpToken The address of lp token of corresponding pool.
  /// @param _amountIn The amount of `_srcToken` to deposit.
  /// @param _routes The routes used to do zap.
  /// @param _minShareOut The minimum amount of pool shares should receive.
  /// @return The amount of pool shares received.
  function deposit(
    address _vault,
    uint256 _pid,
    address _srcToken,
    address _lpToken,
    uint256 _amountIn,
    uint256[] calldata _routes,
    uint256 _minShareOut
  ) external payable returns (uint256) {
    require(_amountIn > 0, "deposit zero amount");

    // 1. transfer srcToken into this contract
    _amountIn = _transferTokenIn(_srcToken, _amountIn);

    // 2. zap srcToken to lp
    uint256 _amountLP = _zap(_routes, _amountIn);
    require(IERC20(_lpToken).balanceOf(address(this)) >= _amountLP, "zap to lp token failed");

    // 3. deposit into Concentrator vault
    IERC20(_lpToken).safeApprove(_vault, 0);
    IERC20(_lpToken).safeApprove(_vault, _amountLP);
    uint256 _sharesOut = IAladdinConvexVault(_vault).deposit(_pid, msg.sender, _amountLP);

    require(_sharesOut >= _minShareOut, "insufficient share");
    return _sharesOut;
  }
}