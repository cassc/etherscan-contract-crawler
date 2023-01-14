// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ILendingModule} from '../interfaces/ILendingModule.sol';
import {ILendingStorageManager} from '../interfaces/ILendingStorageManager.sol';
import {IPool} from '../interfaces/IAaveV3.sol';
import {IRewardsController} from '../interfaces/IRewardsController.sol';
import {Address} from '../../../@openzeppelin/contracts/utils/Address.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {PreciseUnitMath} from '../../base/utils/PreciseUnitMath.sol';
import {
  SynthereumPoolMigrationFrom
} from '../../synthereum-pool/common/migration/PoolMigrationFrom.sol';

contract AaveV3Module is ILendingModule {
  using SafeERC20 for IERC20;

  function deposit(
    ILendingStorageManager.PoolStorage calldata _poolData,
    bytes calldata _lendingArgs,
    uint256 _amount
  )
    external
    override
    returns (
      uint256 totalInterest,
      uint256 tokensOut,
      uint256 tokensTransferred
    )
  {
    // calculate accrued interest since last operation
    (uint256 interest, uint256 poolBalance) =
      calculateGeneratedInterest(msg.sender, _poolData, _amount, true);

    // proxy should have received collateral from the pool
    IERC20 collateral = IERC20(_poolData.collateral);
    require(collateral.balanceOf(address(this)) >= _amount, 'Wrong balance');

    // aave deposit - approve
    (address moneyMarket, ) = abi.decode(_lendingArgs, (address, address));

    collateral.safeIncreaseAllowance(moneyMarket, _amount);
    IPool(moneyMarket).supply(
      address(collateral),
      _amount,
      msg.sender,
      uint16(0)
    );

    // aave tokens are usually 1:1 (but in some case there is dust-wei of rounding)
    uint256 netDeposit =
      IERC20(_poolData.interestBearingToken).balanceOf(msg.sender) -
        poolBalance;

    totalInterest = interest;
    tokensOut = netDeposit;
    tokensTransferred = netDeposit;
  }

  function withdraw(
    ILendingStorageManager.PoolStorage calldata _poolData,
    address _pool,
    bytes calldata _lendingArgs,
    uint256 _aTokensAmount,
    address _recipient
  )
    external
    override
    returns (
      uint256 totalInterest,
      uint256 tokensOut,
      uint256 tokensTransferred
    )
  {
    // proxy should have received interest tokens from the pool
    IERC20 interestToken = IERC20(_poolData.interestBearingToken);

    uint256 withdrawAmount =
      PreciseUnitMath.min(
        interestToken.balanceOf(address(this)),
        _aTokensAmount + 1
      );

    // calculate accrued interest since last operation
    (totalInterest, ) = calculateGeneratedInterest(
      _pool,
      _poolData,
      _aTokensAmount,
      false
    );

    uint256 initialBalance = IERC20(_poolData.collateral).balanceOf(_recipient);

    // aave withdraw - approve
    (address moneyMarket, ) = abi.decode(_lendingArgs, (address, address));

    interestToken.safeIncreaseAllowance(moneyMarket, withdrawAmount);
    IPool(moneyMarket).withdraw(
      _poolData.collateral,
      withdrawAmount,
      _recipient
    );

    // aave tokens are usually 1:1 (but in some case there is dust-wei of rounding)
    uint256 netWithdrawal =
      IERC20(_poolData.collateral).balanceOf(_recipient) - initialBalance;

    tokensOut = _aTokensAmount;
    tokensTransferred = netWithdrawal;
  }

  function totalTransfer(
    address _oldPool,
    address _newPool,
    address _collateral,
    address _interestToken,
    bytes calldata _extraArgs
  )
    external
    returns (uint256 prevTotalCollateral, uint256 actualTotalCollateral)
  {
    prevTotalCollateral = SynthereumPoolMigrationFrom(_oldPool)
      .migrateTotalFunds(_newPool);
    actualTotalCollateral = IERC20(_interestToken).balanceOf(_newPool);
  }

  /**
   * @notice Claim the rewards associated to the bearing tokens of the caller(pool)
   * @param _lendingArgs encoded args needed by the specific implementation
   * @param _collateral Address of the collateral of the pool
   * @param _bearingToken Address of the bearing token of the pool
   * @param _recipient address to which send rewards
   */
  function claimRewards(
    bytes calldata _lendingArgs,
    address _collateral,
    address _bearingToken,
    address _recipient
  ) external {
    (, address rewardsController) =
      abi.decode(_lendingArgs, (address, address));
    address[] memory assets = new address[](1);
    assets[0] = _bearingToken;
    IRewardsController(rewardsController).claimAllRewards(assets, _recipient);
  }

  function getUpdatedInterest(
    address _poolAddress,
    ILendingStorageManager.PoolStorage calldata _poolData,
    bytes calldata _extraArgs
  ) external view override returns (uint256 totalInterest) {
    (totalInterest, ) = calculateGeneratedInterest(
      _poolAddress,
      _poolData,
      0,
      true
    );
  }

  function getAccumulatedInterest(
    address _poolAddress,
    ILendingStorageManager.PoolStorage calldata _poolData,
    bytes calldata _extraArgs
  ) external view override returns (uint256 totalInterest) {
    (totalInterest, ) = calculateGeneratedInterest(
      _poolAddress,
      _poolData,
      0,
      true
    );
  }

  function getInterestBearingToken(address _collateral, bytes calldata _args)
    external
    view
    override
    returns (address token)
  {
    (address moneyMarket, ) = abi.decode(_args, (address, address));
    token = IPool(moneyMarket).getReserveData(_collateral).aTokenAddress;
    require(token != address(0), 'Interest token not found');
  }

  function collateralToInterestToken(
    uint256 _collateralAmount,
    address _collateral,
    address _interestToken,
    bytes calldata _extraArgs
  ) external pure override returns (uint256 interestTokenAmount) {
    interestTokenAmount = _collateralAmount;
  }

  function interestTokenToCollateral(
    uint256 _interestTokenAmount,
    address _collateral,
    address _interestToken,
    bytes calldata _extraArgs
  ) external pure override returns (uint256 collateralAmount) {
    collateralAmount = _interestTokenAmount;
  }

  function calculateGeneratedInterest(
    address _poolAddress,
    ILendingStorageManager.PoolStorage calldata _pool,
    uint256 _amount,
    bool _isDeposit
  )
    internal
    view
    returns (uint256 totalInterestGenerated, uint256 poolBalance)
  {
    // get current pool total amount of collateral
    poolBalance = IERC20(_pool.interestBearingToken).balanceOf(_poolAddress);

    // the total interest is delta between current balance and lastBalance
    totalInterestGenerated = _isDeposit
      ? poolBalance -
        _pool.collateralDeposited -
        _pool.unclaimedDaoCommission -
        _pool.unclaimedDaoJRT
      : poolBalance +
        _amount -
        _pool.collateralDeposited -
        _pool.unclaimedDaoCommission -
        _pool.unclaimedDaoJRT;
  }
}