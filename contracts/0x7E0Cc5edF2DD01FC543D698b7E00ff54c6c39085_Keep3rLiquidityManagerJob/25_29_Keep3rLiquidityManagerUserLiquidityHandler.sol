// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import './Keep3rLiquidityManagerParameters.sol';

interface IKeep3rLiquidityManagerUserLiquidityHandler {
  event LiquidityFeeSet(uint256 _liquidityFee);

  event FeeReceiverSet(address _feeReceiver);

  event DepositedLiquidity(address indexed _depositor, address _recipient, address _lp, uint256 _amount, uint256 _fee);

  event WithdrewLiquidity(address indexed _withdrawer, address _recipient, address _lp, uint256 _amount);

  function liquidityFee() external view returns (uint256 _liquidityFee);

  function feeReceiver() external view returns (address _feeReceiver);

  function liquidityTotalAmount(address _liquidity) external view returns (uint256 _amount);

  function userLiquidityTotalAmount(address _user, address _lp) external view returns (uint256 _amount);

  function userLiquidityIdleAmount(address _user, address _lp) external view returns (uint256 _amount);

  function depositLiquidity(address _lp, uint256 _amount) external;

  function depositLiquidityTo(
    address _liquidityRecipient,
    address _lp,
    uint256 _amount
  ) external;

  function withdrawLiquidity(address _lp, uint256 _amount) external;

  function withdrawLiquidityTo(
    address _liquidityRecipient,
    address _lp,
    uint256 _amount
  ) external;

  function setLiquidityFee(uint256 _liquidityFee) external;

  function setFeeReceiver(address _feeReceiver) external;
}

abstract contract Keep3rLiquidityManagerUserLiquidityHandler is Keep3rLiquidityManagerParameters, IKeep3rLiquidityManagerUserLiquidityHandler {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // liquidity fee precision
  uint256 public constant PRECISION = 1_000;
  // max liquidity fee
  uint256 public constant MAX_LIQUIDITY_FEE = PRECISION / 10; // 10%
  // liquidity fee
  uint256 public override liquidityFee;
  // feeReceiver address
  address public override feeReceiver;
  // lp => amount (helps safely collect extra dust)
  mapping(address => uint256) public override liquidityTotalAmount;
  // user => lp => amount
  mapping(address => mapping(address => uint256)) public override userLiquidityTotalAmount;
  // user => lp => amount
  mapping(address => mapping(address => uint256)) public override userLiquidityIdleAmount;

  constructor() public {
    _setFeeReceiver(msg.sender);
  }

  // user
  function depositLiquidity(address _lp, uint256 _amount) public virtual override {
    depositLiquidityTo(msg.sender, _lp, _amount);
  }

  function depositLiquidityTo(
    address _liquidityRecipient,
    address _lp,
    uint256 _amount
  ) public virtual override {
    _depositLiquidity(msg.sender, _liquidityRecipient, _lp, _amount);
  }

  function withdrawLiquidity(address _lp, uint256 _amount) public virtual override {
    withdrawLiquidityTo(msg.sender, _lp, _amount);
  }

  function withdrawLiquidityTo(
    address _liquidityRecipient,
    address _lp,
    uint256 _amount
  ) public virtual override {
    _withdrawLiquidity(msg.sender, _liquidityRecipient, _lp, _amount);
  }

  function _depositLiquidity(
    address _liquidityDepositor,
    address _liquidityRecipient,
    address _lp,
    uint256 _amount
  ) internal {
    require(IKeep3rV1(keep3rV1).liquidityAccepted(_lp), 'Keep3rLiquidityManager::liquidity-not-accepted-on-keep3r');
    IERC20(_lp).safeTransferFrom(_liquidityDepositor, address(this), _amount);
    uint256 _fee = _amount.mul(liquidityFee).div(PRECISION);
    if (_fee > 0) IERC20(_lp).safeTransfer(feeReceiver, _fee);
    _addLiquidity(_liquidityRecipient, _lp, _amount.sub(_fee));
    emit DepositedLiquidity(_liquidityDepositor, _liquidityRecipient, _lp, _amount.sub(_fee), _fee);
  }

  function _withdrawLiquidity(
    address _liquidityWithdrawer,
    address _liquidityRecipient,
    address _lp,
    uint256 _amount
  ) internal {
    require(userLiquidityIdleAmount[_liquidityWithdrawer][_lp] >= _amount, 'Keep3rLiquidityManager::user-insufficient-idle-balance');
    _subLiquidity(_liquidityWithdrawer, _lp, _amount);
    IERC20(_lp).safeTransfer(_liquidityRecipient, _amount);
    emit WithdrewLiquidity(_liquidityWithdrawer, _liquidityRecipient, _lp, _amount);
  }

  function _addLiquidity(
    address _user,
    address _lp,
    uint256 _amount
  ) internal {
    require(_user != address(0), 'Keep3rLiquidityManager::zero-user');
    require(_amount > 0, 'Keep3rLiquidityManager::amount-bigger-than-zero');
    liquidityTotalAmount[_lp] = liquidityTotalAmount[_lp].add(_amount);
    userLiquidityTotalAmount[_user][_lp] = userLiquidityTotalAmount[_user][_lp].add(_amount);
    userLiquidityIdleAmount[_user][_lp] = userLiquidityIdleAmount[_user][_lp].add(_amount);
  }

  function _subLiquidity(
    address _user,
    address _lp,
    uint256 _amount
  ) internal {
    require(userLiquidityTotalAmount[_user][_lp] >= _amount, 'Keep3rLiquidityManager::amount-bigger-than-total');
    liquidityTotalAmount[_lp] = liquidityTotalAmount[_lp].sub(_amount);
    userLiquidityTotalAmount[_user][_lp] = userLiquidityTotalAmount[_user][_lp].sub(_amount);
    userLiquidityIdleAmount[_user][_lp] = userLiquidityIdleAmount[_user][_lp].sub(_amount);
  }

  function _setLiquidityFee(uint256 _liquidityFee) internal {
    // TODO better revert messages
    require(_liquidityFee <= MAX_LIQUIDITY_FEE, 'Keep3rLiquidityManager::fee-exceeds-max-liquidity-fee');
    liquidityFee = _liquidityFee;
    emit LiquidityFeeSet(_liquidityFee);
  }

  function _setFeeReceiver(address _feeReceiver) internal {
    require(_feeReceiver != address(0), 'Keep3rLiquidityManager::zero-address');
    feeReceiver = _feeReceiver;
    emit FeeReceiverSet(_feeReceiver);
  }
}