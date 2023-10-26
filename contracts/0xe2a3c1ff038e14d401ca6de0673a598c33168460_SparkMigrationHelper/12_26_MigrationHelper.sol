// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20WithPermit} from 'solidity-utils/contracts/oz-common/interfaces/IERC20WithPermit.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {DataTypes, ILendingPool as IV2Pool} from 'aave-address-book/AaveV2.sol';
import {IPool as IV3Pool} from 'aave-address-book/AaveV3.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';

import {IMigrationHelper} from '../interfaces/IMigrationHelper.sol';

/**
 * @title MigrationHelper
 * @author BGD Labs
 * @dev Contract to migrate positions from Aave v2 to Aave v3 pool
 */
contract MigrationHelper is Ownable, IMigrationHelper {
  using SafeERC20 for IERC20WithPermit;

  /// @inheritdoc IMigrationHelper
  IV2Pool public immutable V2_POOL;

  /// @inheritdoc IMigrationHelper
  IV3Pool public immutable V3_POOL;

  mapping(address => IERC20WithPermit) public aTokens;
  mapping(address => IERC20WithPermit) public vTokens;
  mapping(address => IERC20WithPermit) public sTokens;

  /**
   * @notice Constructor.
   * @param v3Pool The v3 pool
   * @param v2Pool The v2 pool
   */
  constructor(IV3Pool v3Pool, IV2Pool v2Pool) {
    V3_POOL = v3Pool;
    V2_POOL = v2Pool;
    cacheATokens();
  }

  /// @inheritdoc IMigrationHelper
  function cacheATokens() public {
    DataTypes.ReserveData memory reserveData;
    address[] memory reserves = V2_POOL.getReservesList();
    for (uint256 i = 0; i < reserves.length; i++) {
      if (address(aTokens[reserves[i]]) == address(0)) {
        reserveData = V2_POOL.getReserveData(reserves[i]);
        aTokens[reserves[i]] = IERC20WithPermit(reserveData.aTokenAddress);
        vTokens[reserves[i]] = IERC20WithPermit(reserveData.variableDebtTokenAddress);
        sTokens[reserves[i]] = IERC20WithPermit(reserveData.stableDebtTokenAddress);

        IERC20WithPermit(reserves[i]).safeApprove(address(V2_POOL), type(uint256).max);
        IERC20WithPermit(reserves[i]).safeApprove(address(V3_POOL), type(uint256).max);
      }
    }
  }

  /// @inheritdoc IMigrationHelper
  function migrate(
    address[] memory assetsToMigrate,
    RepaySimpleInput[] memory positionsToRepay,
    PermitInput[] memory permits,
    CreditDelegationInput[] memory creditDelegationPermits
  ) external {
    for (uint256 i = 0; i < permits.length; i++) {
      permits[i].aToken.permit(
        msg.sender,
        address(this),
        permits[i].value,
        permits[i].deadline,
        permits[i].v,
        permits[i].r,
        permits[i].s
      );
    }

    if (positionsToRepay.length == 0) {
      _migrationNoBorrow(msg.sender, assetsToMigrate);
    } else {
      for (uint256 i = 0; i < creditDelegationPermits.length; i++) {
        creditDelegationPermits[i].debtToken.delegationWithSig(
          msg.sender,
          address(this),
          creditDelegationPermits[i].value,
          creditDelegationPermits[i].deadline,
          creditDelegationPermits[i].v,
          creditDelegationPermits[i].r,
          creditDelegationPermits[i].s
        );
      }

      (
        RepayInput[] memory positionsToRepayWithAmounts,
        address[] memory assetsToFlash,
        uint256[] memory amountsToFlash,
        uint256[] memory interestRatesToFlash
      ) = _getFlashloanParams(positionsToRepay);

      // Apply any conversions
      for (uint256 i = 0; i < assetsToFlash.length; i++) {
        (assetsToFlash[i], amountsToFlash[i]) = _preFlashLoan(
          assetsToFlash[i],
          amountsToFlash[i]
        );
      }

      V3_POOL.flashLoan(
        address(this),
        assetsToFlash,
        amountsToFlash,
        interestRatesToFlash,
        msg.sender,
        abi.encode(assetsToMigrate, positionsToRepayWithAmounts, msg.sender),
        6671
      );
    }
  }

  /**
   * @dev expected structure of the params:
   *    assetsToMigrate - the list of supplied assets to migrate
   *    positionsToRepay - the list of borrowed positions, asset address, amount and debt type should be provided
   *    beneficiary - the user who requested the migration
    @inheritdoc IMigrationHelper
   */
  function executeOperation(
    address[] memory assetsToFlash,
    uint256[] memory amountsToFlash,
    uint256[] calldata,
    address initiator,
    bytes calldata params
  ) external returns (bool) {
    require(msg.sender == address(V3_POOL), 'ONLY_V3_POOL_ALLOWED');
    require(initiator == address(this), 'ONLY_INITIATED_BY_MIGRATION_HELPER');

    (address[] memory assetsToMigrate, RepayInput[] memory positionsToRepay, address user) = abi
      .decode(params, (address[], RepayInput[], address));

    // Apply any reverse conversions
    for (uint256 i = 0; i < assetsToFlash.length; i++) {
      _postFlashLoan(
        assetsToFlash[i],
        amountsToFlash[i],
        positionsToRepay[i].asset,
        positionsToRepay[i].amount
      );
    }

    for (uint256 i = 0; i < positionsToRepay.length; i++) {
      V2_POOL.repay(
        positionsToRepay[i].asset,
        positionsToRepay[i].amount,
        positionsToRepay[i].rateMode,
        user
      );
    }

    _migrationNoBorrow(user, assetsToMigrate);

    return true;
  }

  /// @inheritdoc IMigrationHelper
  function getMigrationSupply(
    address asset,
    uint256 amount
  ) external view virtual returns (address, uint256) {
    return (asset, amount);
  }

  function _preFlashLoan(
    address asset,
    uint256 amount
  ) internal view virtual returns (address, uint256) {
    return (asset, amount);
  }

  function _postFlashLoan(
    address,
    uint256,
    address,
    uint256
  ) internal virtual {
  }

  function _migrationNoBorrow(address user, address[] memory assets) internal {
    address asset;
    IERC20WithPermit aToken;
    uint256 aTokenAmountToMigrate;
    uint256 aTokenBalanceAfterReceiving;

    for (uint256 i = 0; i < assets.length; i++) {
      asset = assets[i];
      aToken = aTokens[asset];

      require(asset != address(0) && address(aToken) != address(0), 'INVALID_OR_NOT_CACHED_ASSET');

      aTokenAmountToMigrate = aToken.balanceOf(user);
      aToken.safeTransferFrom(user, address(this), aTokenAmountToMigrate);

      // this part of logic needed because of the possible 1-3 wei imprecision after aToken transfer, for example on stETH
      aTokenBalanceAfterReceiving = aToken.balanceOf(address(this));
      if (
        aTokenAmountToMigrate != aTokenBalanceAfterReceiving &&
        aTokenBalanceAfterReceiving <= aTokenAmountToMigrate + 2
      ) {
        aTokenAmountToMigrate = aTokenBalanceAfterReceiving;
      }

      uint256 withdrawn = V2_POOL.withdraw(asset, aTokenAmountToMigrate, address(this));

      // there are cases when we transform asset before supplying it to v3
      (address assetToSupply, uint256 amountToSupply) = _preSupply(asset, withdrawn);

      V3_POOL.supply(assetToSupply, amountToSupply, user, 6671);
    }
  }

  function _preSupply(address asset, uint256 amount) internal virtual returns (address, uint256) {
    return (asset, amount);
  }

  function _getFlashloanParams(
    RepaySimpleInput[] memory positionsToRepay
  )
    internal
    view
    returns (RepayInput[] memory, address[] memory, uint256[] memory, uint256[] memory)
  {
    RepayInput[] memory positionsToRepayWithAmounts = new RepayInput[](positionsToRepay.length);

    uint256 numberOfAssetsToFlash;
    address[] memory assetsToFlash = new address[](positionsToRepay.length);
    uint256[] memory amountsToFlash = new uint256[](positionsToRepay.length);
    uint256[] memory interestRatesToFlash = new uint256[](positionsToRepay.length);

    for (uint256 i = 0; i < positionsToRepay.length; i++) {
      IERC20WithPermit debtToken = positionsToRepay[i].rateMode == 2
        ? vTokens[positionsToRepay[i].asset]
        : sTokens[positionsToRepay[i].asset];
      require(address(debtToken) != address(0), 'THIS_TYPE_OF_DEBT_NOT_SET');

      positionsToRepayWithAmounts[i] = RepayInput({
        asset: positionsToRepay[i].asset,
        amount: debtToken.balanceOf(msg.sender),
        rateMode: positionsToRepay[i].rateMode
      });

      bool amountIncludedIntoFlash;

      // if asset was also borrowed in another mode - add values
      for (uint256 j = 0; j < numberOfAssetsToFlash; j++) {
        if (assetsToFlash[j] == positionsToRepay[i].asset) {
          amountsToFlash[j] += positionsToRepayWithAmounts[i].amount;
          amountIncludedIntoFlash = true;
          break;
        }
      }

      // if this is the first ocurance of the asset add it
      if (!amountIncludedIntoFlash) {
        assetsToFlash[numberOfAssetsToFlash] = positionsToRepayWithAmounts[i].asset;
        amountsToFlash[numberOfAssetsToFlash] = positionsToRepayWithAmounts[i].amount;
        interestRatesToFlash[numberOfAssetsToFlash] = 2; // @dev variable debt

        ++numberOfAssetsToFlash;
      }
    }

    // we do not know the length in advance, so we init arrays with the maximum possible length
    // and then squeeze the array using mstore
    assembly {
      mstore(assetsToFlash, numberOfAssetsToFlash)
      mstore(amountsToFlash, numberOfAssetsToFlash)
      mstore(interestRatesToFlash, numberOfAssetsToFlash)
    }

    return (positionsToRepayWithAmounts, assetsToFlash, amountsToFlash, interestRatesToFlash);
  }

  /// @inheritdoc IMigrationHelper
  function rescueFunds(EmergencyTransferInput[] calldata emergencyInput) external onlyOwner {
    for (uint256 i = 0; i < emergencyInput.length; i++) {
      emergencyInput[i].asset.safeTransfer(emergencyInput[i].to, emergencyInput[i].amount);
    }
  }
}