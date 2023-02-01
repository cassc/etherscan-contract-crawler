// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "./interfaces/IStakeDAOCRVDepositor.sol";
import "./interfaces/IStakeDAOCRVVault.sol";
import "../../interfaces/ICurveFactoryPlainPool.sol";

import "./SdCRVLocker.sol";
import "./StakeDAOVaultBase.sol";

// solhint-disable not-rely-on-time

contract StakeDAOCRVVault is StakeDAOVaultBase, SdCRVLocker, IStakeDAOCRVVault {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @dev The minimum number of seconds needed to lock.
  uint256 private constant MIN_WITHDRAW_LOCK_TIME = 86400;

  /// @dev The address of CRV Token.
  address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;

  /// @dev The address of legacy sdveCRV Token.
  address private constant SD_VE_CRV = 0x478bBC744811eE8310B461514BDc29D03739084D;

  /// @dev The address of StakeDAO CRV Depositor contract.
  address private constant DEPOSITOR = 0xc1e3Ca8A3921719bE0aE3690A0e036feB4f69191;

  /// @dev The address of Curve CRV/sdCRV factory plain pool.
  address private constant CURVE_POOL = 0xf7b55C3732aD8b2c2dA7c24f30A69f55c54FB717;

  /// @notice The name of the vault.
  // solhint-disable-next-line const-name-snakecase
  string public constant name = "Concentrator sdCRV Vault";

  /// @notice The symbol of the vault.
  // solhint-disable-next-line const-name-snakecase
  string public constant symbol = "CTR-sdCRV-Vault";

  /// @notice The decimal of the vault share.
  // solhint-disable-next-line const-name-snakecase
  uint8 public constant decimals = 18;

  /// @dev The number of seconds to lock for withdrawing assets from the contract.
  uint256 private _withdrawLockTime;

  /********************************** Constructor **********************************/

  constructor(address _stakeDAOProxy, address _delegation) StakeDAOVaultBase(_stakeDAOProxy, _delegation) {}

  function initialize(address _gauge, uint256 __withdrawLockTime) external initializer {
    require(__withdrawLockTime >= MIN_WITHDRAW_LOCK_TIME, "lock time too small");

    StakeDAOVaultBase._initialize(_gauge);

    _withdrawLockTime = __withdrawLockTime;
  }

  /********************************** View Functions **********************************/

  /// @inheritdoc SdCRVLocker
  function withdrawLockTime() public view override returns (uint256) {
    return _withdrawLockTime;
  }

  /********************************** Mutated Functions **********************************/

  /// @inheritdoc IStakeDAOCRVVault
  function depositWithCRV(
    uint256 _amount,
    address _recipient,
    uint256 _minOut
  ) external override returns (uint256 _amountOut) {
    if (_amount == uint256(-1)) {
      _amount = IERC20Upgradeable(CRV).balanceOf(msg.sender);
    }
    require(_amount > 0, "deposit zero amount");

    IERC20Upgradeable(CRV).safeTransferFrom(msg.sender, address(this), _amount);

    // swap to sdCRV
    uint256 _lockReturn = _amount + IStakeDAOCRVDepositor(DEPOSITOR).incentiveToken();
    uint256 _swapReturn = ICurveFactoryPlainPool(CURVE_POOL).get_dy(0, 1, _amount);
    if (_lockReturn >= _swapReturn) {
      IERC20Upgradeable(CRV).safeApprove(DEPOSITOR, 0);
      IERC20Upgradeable(CRV).safeApprove(DEPOSITOR, _amount);
      IStakeDAOCRVDepositor(DEPOSITOR).deposit(_amount, true, false, stakeDAOProxy);
      _amountOut = _lockReturn;
    } else {
      IERC20Upgradeable(CRV).safeApprove(CURVE_POOL, 0);
      IERC20Upgradeable(CRV).safeApprove(CURVE_POOL, _amount);
      _amountOut = ICurveFactoryPlainPool(CURVE_POOL).exchange(0, 1, _amount, 0, stakeDAOProxy);
    }
    require(_amountOut >= _minOut, "insufficient amount out");

    // deposit
    _deposit(_amountOut, _recipient);
  }

  /// @inheritdoc IStakeDAOCRVVault
  function depositWithSdVeCRV(uint256 _amount, address _recipient) external override {
    if (_amount == uint256(-1)) {
      _amount = IERC20Upgradeable(SD_VE_CRV).balanceOf(msg.sender);
    }
    require(_amount > 0, "deposit zero amount");

    IERC20Upgradeable(SD_VE_CRV).safeTransferFrom(msg.sender, address(this), _amount);

    // lock to sdCRV
    IERC20Upgradeable(SD_VE_CRV).safeApprove(DEPOSITOR, 0);
    IERC20Upgradeable(SD_VE_CRV).safeApprove(DEPOSITOR, _amount);
    IStakeDAOCRVDepositor(DEPOSITOR).lockSdveCrvToSdCrv(_amount);

    // transfer to proxy
    IERC20Upgradeable(stakingToken).safeTransfer(stakeDAOProxy, _amount);

    // deposit
    _deposit(_amount, _recipient);
  }

  /// @inheritdoc IStakeDAOVault
  function withdraw(uint256 _amount, address _recipient) external override(StakeDAOVaultBase, IStakeDAOVault) {
    _checkpoint(msg.sender);

    uint256 _balance = userInfo[msg.sender].balance;
    if (_amount == uint256(-1)) {
      _amount = _balance;
    }
    require(_amount <= _balance, "insufficient staked token");
    require(_amount > 0, "withdraw zero amount");

    userInfo[msg.sender].balance = _balance - _amount;
    totalSupply -= _amount;

    // take withdraw fee here
    uint256 _withdrawFee = getFeeRate(WITHDRAW_FEE_TYPE, msg.sender);
    if (_withdrawFee > 0) {
      _withdrawFee = (_amount * _withdrawFee) / FEE_PRECISION;
      withdrawFeeAccumulated += _withdrawFee;
      _amount -= _withdrawFee;
    } else {
      _withdrawFee = 0;
    }

    _lockToken(_amount, _recipient);

    emit Withdraw(msg.sender, _recipient, _amount, _withdrawFee);
  }

  /// @inheritdoc IStakeDAOCRVVault
  function harvestBribes(IStakeDAOMultiMerkleStash.claimParam[] memory _claims) external override {
    IStakeDAOLockerProxy(stakeDAOProxy).claimBribeRewards(_claims, address(this));

    FeeInfo memory _fee = feeInfo;
    uint256[] memory _amounts = new uint256[](_claims.length);
    address[] memory _tokens = new address[](_claims.length);
    for (uint256 i = 0; i < _claims.length; i++) {
      address _token = _claims[i].token;
      uint256 _reward = _claims[i].amount;
      uint256 _platformFee = uint256(_fee.platformPercentage) * 100;
      uint256 _boostFee = uint256(_fee.boostPercentage) * 100;

      // Currently, we will only receive SDT as bribe rewards.
      // If there are other tokens, we will transfer all of them to platform contract.
      if (_token != SDT) {
        _platformFee = FEE_PRECISION;
        _boostFee = 0;
      }
      if (_platformFee > 0) {
        _platformFee = (_reward * _platformFee) / FEE_PRECISION;
        IERC20Upgradeable(_token).safeTransfer(_fee.platform, _platformFee);
      }
      if (_boostFee > 0) {
        _boostFee = (_reward * _boostFee) / FEE_PRECISION;
        IERC20Upgradeable(_token).safeTransfer(delegation, _boostFee);
      }
      emit HarvestBribe(_token, _reward, _platformFee, _boostFee);

      _amounts[i] = _reward - _platformFee - _boostFee;
      _tokens[i] = _token;
    }
    _distribute(_tokens, _amounts);
  }

  /********************************** Restricted Functions **********************************/

  /// @notice Update the withdraw lock time.
  /// @param __withdrawLockTime The new withdraw lock time in seconds.
  function updateWithdrawLockTime(uint256 __withdrawLockTime) external onlyOwner {
    require(__withdrawLockTime >= MIN_WITHDRAW_LOCK_TIME, "lock time too small");

    _withdrawLockTime = __withdrawLockTime;

    emit UpdateWithdrawLockTime(_withdrawLockTime);
  }

  /********************************** Internal Functions **********************************/

  /// @inheritdoc StakeDAOVaultBase
  function _checkpoint(address _user) internal override returns (bool) {
    bool _hasSDT = StakeDAOVaultBase._checkpoint(_user);
    if (!_hasSDT) {
      _checkpoint(SDT, userInfo[_user], userInfo[_user].balance);
    }
    return true;
  }

  /// @inheritdoc SdCRVLocker
  function _unlockToken(uint256 _amount, address _recipient) internal override {
    IStakeDAOLockerProxy(stakeDAOProxy).withdraw(gauge, stakingToken, _amount, _recipient);
  }
}