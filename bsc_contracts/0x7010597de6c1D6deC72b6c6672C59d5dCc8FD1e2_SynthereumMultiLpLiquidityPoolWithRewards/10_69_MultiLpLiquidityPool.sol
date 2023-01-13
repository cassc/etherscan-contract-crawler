// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {
  ISynthereumMultiLpLiquidityPool
} from './interfaces/IMultiLpLiquidityPool.sol';
import {
  ISynthereumLendingSwitch
} from '../common/interfaces/ILendingSwitch.sol';
import {
  ISynthereumLendingTransfer
} from '../common/interfaces/ILendingTransfer.sol';
import {
  ISynthereumMultiLpLiquidityPoolEvents
} from './interfaces/IMultiLpLiquidityPoolEvents.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {
  EnumerableSet
} from '../../../@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {PreciseUnitMath} from '../../base/utils/PreciseUnitMath.sol';
import {
  SynthereumMultiLpLiquidityPoolMainLib
} from './MultiLpLiquidityPoolMainLib.sol';
import {
  SynthereumMultiLpLiquidityPoolMigrationLib
} from './MultiLpLiquidityPoolMigrationLib.sol';
import {
  SynthereumPoolMigrationFrom
} from '../common/migration/PoolMigrationFrom.sol';
import {
  SynthereumPoolMigrationTo
} from '../common/migration/PoolMigrationTo.sol';
import {ERC2771Context} from '../../common/ERC2771Context.sol';
import {
  AccessControlEnumerable,
  Context
} from '../../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import {
  ReentrancyGuard
} from '../../../@openzeppelin/contracts/security/ReentrancyGuard.sol';

/**
 * @title Multi LP Synthereum pool
 */
contract SynthereumMultiLpLiquidityPool is
  ISynthereumMultiLpLiquidityPoolEvents,
  ISynthereumLendingTransfer,
  ISynthereumLendingSwitch,
  ISynthereumMultiLpLiquidityPool,
  ReentrancyGuard,
  AccessControlEnumerable,
  ERC2771Context,
  SynthereumPoolMigrationTo,
  SynthereumPoolMigrationFrom
{
  using EnumerableSet for EnumerableSet.AddressSet;
  using SynthereumMultiLpLiquidityPoolMainLib for Storage;
  using SynthereumMultiLpLiquidityPoolMigrationLib for Storage;

  //----------------------------------------
  // Constants
  //----------------------------------------

  string public constant override typology = 'POOL';

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //----------------------------------------
  // Storage
  //----------------------------------------

  Storage internal storageParams;

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  modifier isNotExpired(uint256 expirationTime) {
    require(block.timestamp <= expirationTime, 'Transaction expired');
    _;
  }

  modifier isNotInitialized() {
    require(!storageParams.isInitialized, 'Pool already initialized');
    _;
    storageParams.isInitialized = true;
  }

  /**
   * @notice Initialize pool
   * @param _params Params used for initialization (see InitializationParams struct)
   */
  function initialize(InitializationParams calldata _params)
    external
    override
    isNotInitialized
    nonReentrant
  {
    finder = _params.finder;
    storageParams.initialize(_params);
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _params.roles.admin);
    _setupRole(MAINTAINER_ROLE, _params.roles.maintainer);
  }

  /**
   * @notice Register a liquidity provider to the LP's whitelist
   * @notice This can be called only by the maintainer
   * @param _lp Address of the LP
   */
  function registerLP(address _lp)
    external
    override
    nonReentrant
    onlyMaintainer
  {
    storageParams.registerLP(_lp);
  }

  /**
   * @notice Add the Lp to the active list of the LPs and initialize collateral and overcollateralization
   * @notice Only a registered and inactive LP can call this function to add himself
   * @param _collateralAmount Collateral amount to deposit by the LP
   * @param _overCollateralization Overcollateralization to set by the LP
   * @return collateralDeposited Net collateral deposited in the LP position
   */
  function activateLP(uint256 _collateralAmount, uint128 _overCollateralization)
    external
    override
    nonReentrant
    returns (uint256 collateralDeposited)
  {
    return
      storageParams.activateLP(
        _collateralAmount,
        _overCollateralization,
        finder,
        _msgSender()
      );
  }

  /**
   * @notice Add collateral to an active LP position
   * @notice Only an active LP can call this function to add collateral to his position
   * @param _collateralAmount Collateral amount to deposit by the LP
   * @return collateralDeposited Net collateral deposited in the LP position
   * @return newLpCollateralAmount Amount of collateral of the LP after the increase
   */
  function addLiquidity(uint256 _collateralAmount)
    external
    override
    nonReentrant
    returns (uint256 collateralDeposited, uint256 newLpCollateralAmount)
  {
    return storageParams.addLiquidity(_collateralAmount, finder, _msgSender());
  }

  /**
   * @notice Withdraw collateral from an active LP position
   * @notice Only an active LP can call this function to withdraw collateral from his position
   * @param _collateralAmount Collateral amount to withdraw by the LP
   * @return collateralRemoved Net collateral decreased form the position
   * @return collateralReceived Collateral received from the withdrawal
   * @return newLpCollateralAmount Amount of collateral of the LP after the decrease
   */
  function removeLiquidity(uint256 _collateralAmount)
    external
    override
    nonReentrant
    returns (
      uint256 collateralRemoved,
      uint256 collateralReceived,
      uint256 newLpCollateralAmount
    )
  {
    return
      storageParams.removeLiquidity(_collateralAmount, finder, _msgSender());
  }

  /**
   * @notice Set the overCollateralization by an active LP
   * @notice This can be called only by an active LP
   * @param _overCollateralization New overCollateralizations
   */
  function setOvercollateralization(uint128 _overCollateralization)
    external
    override
    nonReentrant
  {
    storageParams.setOvercollateralization(
      _overCollateralization,
      finder,
      _msgSender()
    );
  }

  /**
   * @notice Mint synthetic tokens using fixed amount of collateral
   * @notice This calculate the price using on chain price feed
   * @notice User must approve collateral transfer for the mint request to succeed
   * @param _mintParams Input parameters for minting (see MintParams struct)
   * @return Amount of synthetic tokens minted by a user
   * @return Amount of collateral paid by the user as fee
   */
  function mint(MintParams calldata _mintParams)
    external
    override
    nonReentrant
    isNotExpired(_mintParams.expiration)
    returns (uint256, uint256)
  {
    return storageParams.mint(_mintParams, finder, _msgSender());
  }

  /**
   * @notice Redeem amount of collateral using fixed number of synthetic token
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param _redeemParams Input parameters for redeeming (see RedeemParams struct)
   * @return Amount of collateral redeemed by user
   * @return Amount of collateral paid by user as fee
   */
  function redeem(RedeemParams calldata _redeemParams)
    external
    override
    nonReentrant
    isNotExpired(_redeemParams.expiration)
    returns (uint256, uint256)
  {
    return storageParams.redeem(_redeemParams, finder, _msgSender());
  }

  /**
   * @notice Liquidate Lp position for an amount of synthetic tokens undercollateralized
   * @notice Revert if position is not undercollateralized
   * @param _lp LP that the the user wants to liquidate
   * @param _numSynthTokens Number of synthetic tokens that user wants to liquidate
   * @return Amount of collateral received (Amount of collateral + bonus)
   */
  function liquidate(address _lp, uint256 _numSynthTokens)
    external
    override
    nonReentrant
    returns (uint256)
  {
    return storageParams.liquidate(_lp, _numSynthTokens, finder, _msgSender());
  }

  /**
   * @notice Update interests and positions ov every LP
   * @notice Everyone can call this function
   */
  function updatePositions() external override nonReentrant {
    storageParams.updatePositions(finder);
  }

  /**
   * @notice Transfer a bearing amount to the lending manager
   * @notice Only the lending manager can call the function
   * @param _bearingAmount Amount of bearing token to transfer
   * @return bearingAmountOut Real bearing amount transferred to the lending manager
   */
  function transferToLendingManager(uint256 _bearingAmount)
    external
    override
    nonReentrant
    returns (uint256 bearingAmountOut)
  {
    return storageParams.transferToLendingManager(_bearingAmount, finder);
  }

  /**
   * @notice Transfer all bearing tokens to another address
   * @notice Only the lending manager can call the function
   * @param _recipient Address receving bearing amount
   * @return migrationAmount Total balance of the pool in bearing tokens before migration
   */
  function migrateTotalFunds(address _recipient)
    external
    override
    nonReentrant
    returns (uint256 migrationAmount)
  {
    return
      SynthereumMultiLpLiquidityPoolMigrationLib.migrateTotalFunds(
        _recipient,
        finder
      );
  }

  /**
   * @notice Set new liquidation reward percentage
   * @notice This can be called only by the maintainer
   * @param _newLiquidationReward New liquidation reward percentage
   */
  function setLiquidationReward(uint64 _newLiquidationReward)
    external
    override
    nonReentrant
    onlyMaintainer
  {
    storageParams.setLiquidationReward(_newLiquidationReward);
  }

  /**
   * @notice Set new fee percentage
   * @notice This can be called only by the maintainer
   * @param _newFee New fee percentage
   */
  function setFee(uint64 _newFee)
    external
    override
    nonReentrant
    onlyMaintainer
  {
    storageParams.setFee(_newFee);
  }

  /**
   * @notice Set new lending protocol for this pool
   * @notice This can be called only by the synthereum manager
   * @param _lendingId Name of the new lending module
   * @param _bearingToken Token of the lending mosule to be used for intersts accrual
            (used only if the lending manager doesn't automatically find the one associated to the collateral fo this pool)
   */
  function switchLendingModule(
    string calldata _lendingId,
    address _bearingToken
  ) external override nonReentrant {
    storageParams.switchLendingModule(_lendingId, _bearingToken, finder);
  }

  /**
   * @notice Get all the registered LPs of this pool
   * @return The list of addresses of all the registered LPs in the pool.
   */
  function getRegisteredLPs()
    external
    view
    override
    returns (address[] memory)
  {
    return storageParams.getRegisteredLPs();
  }

  /**
   * @notice Get all the active LPs of this pool
   * @return The list of addresses of all the active LPs in the pool.
   */
  function getActiveLPs() external view override returns (address[] memory) {
    return storageParams.getActiveLPs();
  }

  /**
   * @notice Check if the input LP is registered
   * @param _lp Address of the LP
   * @return Return true if the LP is regitered, otherwise false
   */
  function isRegisteredLP(address _lp) external view override returns (bool) {
    return storageParams.registeredLPs.contains(_lp);
  }

  /**
   * @notice Check if the input LP is active
   * @param _lp Address of the LP
   * @return Return true if the LP is active, otherwise false
   */
  function isActiveLP(address _lp) external view override returns (bool) {
    return storageParams.activeLPs.contains(_lp);
  }

  /**
   * @notice Get Synthereum finder of the pool
   * @return Finder contract
   */
  function synthereumFinder()
    external
    view
    override
    returns (ISynthereumFinder)
  {
    return finder;
  }

  /**
   * @notice Get Synthereum version
   * @return The version of this pool
   */
  function version() external view override returns (uint8) {
    return storageParams.poolVersion;
  }

  /**
   * @notice Get the collateral token of this pool
   * @return The ERC20 collateral token
   */
  function collateralToken() external view override returns (IERC20) {
    return storageParams.collateralAsset;
  }

  /**
   * @notice Get the decimals of the collateral
   * @return Number of decimals of the collateral
   */
  function collateralTokenDecimals() external view override returns (uint8) {
    return storageParams.collateralDecimals;
  }

  /**
   * @notice Get the synthetic token associated to this pool
   * @return The ERC20 synthetic token
   */
  function syntheticToken() external view override returns (IERC20) {
    return storageParams.syntheticAsset;
  }

  /**
   * @notice Get the synthetic token symbol associated to this pool
   * @return The ERC20 synthetic token symbol
   */
  function syntheticTokenSymbol()
    external
    view
    override
    returns (string memory)
  {
    return IStandardERC20(address(storageParams.syntheticAsset)).symbol();
  }

  /**
   * @notice Returns the percentage of overcollateralization to which a liquidation can triggered
   * @return Thresold percentage on a liquidation can be triggered
   */
  function collateralRequirement() external view override returns (uint256) {
    return
      PreciseUnitMath.PRECISE_UNIT + storageParams.overCollateralRequirement;
  }

  /**
   * @notice Returns the percentage of reward for correct liquidation by a liquidator
   * @return Percentage of reward
   */
  function liquidationReward() external view override returns (uint256) {
    return storageParams.liquidationBonus;
  }

  /**
   * @notice Returns price identifier of the pool
   * @return Price identifier
   */
  function priceFeedIdentifier() external view override returns (bytes32) {
    return storageParams.priceIdentifier;
  }

  /**
   * @notice Returns fee percentage of the pool
   * @return Fee percentage
   */
  function feePercentage() external view override returns (uint256) {
    return storageParams.fee;
  }

  /**
   * @notice Returns total number of synthetic tokens generated by this pool
   * @return Number of synthetic tokens
   */
  function totalSyntheticTokens() external view override returns (uint256) {
    return storageParams.totalSyntheticAsset;
  }

  /**
   * @notice Returns the total amounts of collateral
   * @return usersCollateral Total collateral amount currently holded by users
   * @return lpsCollateral Total collateral amount currently holded by LPs
   * @return totalCollateral Total collateral amount currently holded by users + LPs
   */
  function totalCollateralAmount()
    external
    view
    override
    returns (
      uint256 usersCollateral,
      uint256 lpsCollateral,
      uint256 totalCollateral
    )
  {
    return storageParams.totalCollateralAmount(finder);
  }

  /**
   * @notice Returns the max capacity in synth assets of all the LPs
   * @return maxCapacity Total max capacity of the pool
   */
  function maxTokensCapacity()
    external
    view
    override
    returns (uint256 maxCapacity)
  {
    return storageParams.maxTokensCapacity(finder);
  }

  /**
   * @notice Returns the LP parametrs info
   * @notice Mint, redeem and intreest shares are round down (division dust not included)
   * @param _lp Address of the LP
   * @return info Info of the input LP (see LPInfo struct)
   */
  function positionLPInfo(address _lp)
    external
    view
    override
    returns (LPInfo memory info)
  {
    return storageParams.positionLPInfo(_lp, finder);
  }

  /**
   * @notice Returns the lending protocol info
   * @return lendingId Name of the lending module
   * @return bearingToken Address of the bearing token held by the pool for interest accrual
   */
  function lendingProtocolInfo()
    external
    view
    returns (string memory lendingId, address bearingToken)
  {
    return storageParams.lendingProtocolInfo(finder);
  }

  /**
   * @notice Returns the synthetic tokens will be received and fees will be paid in exchange for an input collateral amount
   * @notice This function is only trading-informative, it doesn't check edge case conditions like lending manager dust and reverting due to dust splitting
   * @param _collateralAmount Input collateral amount to be exchanged
   * @return synthTokensReceived Synthetic tokens will be minted
   * @return feePaid Collateral fee will be paid
   */
  function getMintTradeInfo(uint256 _collateralAmount)
    external
    view
    override
    returns (uint256 synthTokensReceived, uint256 feePaid)
  {
    (synthTokensReceived, feePaid) = storageParams.getMintTradeInfo(
      _collateralAmount,
      finder
    );
  }

  /**
   * @notice Returns the collateral amount will be received and fees will be paid in exchange for an input amount of synthetic tokens
   * @notice This function is only trading-informative, it doesn't check edge case conditions like lending manager dust and undercap of one or more LPs
   * @param  _syntTokensAmount Amount of synthetic tokens to be exchanged
   * @return collateralAmountReceived Collateral amount will be received by the user
   * @return feePaid Collateral fee will be paid
   */
  function getRedeemTradeInfo(uint256 _syntTokensAmount)
    external
    view
    override
    returns (uint256 collateralAmountReceived, uint256 feePaid)
  {
    (collateralAmountReceived, feePaid) = storageParams.getRedeemTradeInfo(
      _syntTokensAmount,
      finder
    );
  }

  /**
   * @notice Check if an address is the trusted forwarder
   * @param  forwarder Address to check
   * @return True is the input address is the trusted forwarder, otherwise false
   */
  function isTrustedForwarder(address forwarder)
    public
    view
    override
    returns (bool)
  {
    try
      finder.getImplementationAddress(SynthereumInterfaces.TrustedForwarder)
    returns (address trustedForwarder) {
      if (forwarder == trustedForwarder) {
        return true;
      } else {
        return false;
      }
    } catch {
      return false;
    }
  }

  /**
   * @notice Return sender of the transaction
   */
  function _msgSender()
    internal
    view
    override(ERC2771Context, Context)
    returns (address sender)
  {
    return ERC2771Context._msgSender();
  }

  /**
   * @notice Return data of the transaction
   */
  function _msgData()
    internal
    view
    override(ERC2771Context, Context)
    returns (bytes calldata)
  {
    return ERC2771Context._msgData();
  }

  /**
   * @notice Clean and reset the storage to the initial state during migration
   */
  function _cleanStorage() internal override {
    address[] memory registeredLPsList = storageParams.getRegisteredLPs();

    address[] memory activeLPsList = storageParams.getActiveLPs();

    storageParams.cleanStorage(registeredLPsList, activeLPsList);
  }

  /**
   * @notice Set the storage to the new pool during migration
   * @param _oldVersion Version of the migrated pool
   * @param _storageBytes Pool storage encoded in bytes
   * @param _newVersion Version of the new deployed pool
   * @param _extraInputParams Additive input pool params encoded for the new pool, that are not part of the migrationPool
   */
  function _setStorage(
    uint8 _oldVersion,
    bytes calldata _storageBytes,
    uint8 _newVersion,
    bytes calldata _extraInputParams
  ) internal override isNotInitialized {
    (address[] memory admins, address[] memory maintainers) =
      storageParams.setStorage(
        _oldVersion,
        _storageBytes,
        _newVersion,
        _extraInputParams
      );

    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    for (uint256 j = 0; j < admins.length; j++) {
      _setupRole(DEFAULT_ADMIN_ROLE, admins[j]);
    }
    for (uint256 j = 0; j < maintainers.length; j++) {
      _setupRole(MAINTAINER_ROLE, maintainers[j]);
    }
  }

  /**
   * @notice Update positions during migration
   */
  function _modifyStorageFrom() internal override {
    storageParams.updatePositions(finder);
  }

  /**
   * @notice Update the storage of the new pool after the migration
   * @param _sourceCollateralAmount Collateral amount from the source pool
   * @param _actualCollateralAmount Collateral amount of the new pool
   * @param _price Actual price of the pair
   */
  function _modifyStorageTo(
    uint256 _sourceCollateralAmount,
    uint256 _actualCollateralAmount,
    uint256 _price
  ) internal override {
    storageParams.updateMigrationStorage(
      _sourceCollateralAmount,
      _actualCollateralAmount,
      _price
    );
  }

  /**
   * @notice Encode storage in bytes during migration
   * @return poolVersion Version of the pool
   * @return price Actual price of the pair
   * @return storageBytes Pool storage encoded in bytes
   */
  function _encodeStorage()
    internal
    view
    override
    returns (
      uint8 poolVersion,
      uint256 price,
      bytes memory storageBytes
    )
  {
    uint256 numberOfRoles = getRoleMemberCount(DEFAULT_ADMIN_ROLE);
    address[] memory admins = new address[](numberOfRoles);
    for (uint256 j = 0; j < numberOfRoles; j++) {
      address newMember = getRoleMember(DEFAULT_ADMIN_ROLE, j);
      admins[j] = newMember;
    }
    numberOfRoles = getRoleMemberCount(MAINTAINER_ROLE);
    address[] memory maintainers = new address[](numberOfRoles);
    for (uint256 j = 0; j < numberOfRoles; j++) {
      address newMember = getRoleMember(MAINTAINER_ROLE, j);
      maintainers[j] = newMember;
    }

    address[] memory registeredLPsList = storageParams.getRegisteredLPs();

    address[] memory activeLPsList = storageParams.getActiveLPs();

    (poolVersion, price, storageBytes) = storageParams.encodeStorage(
      SynthereumMultiLpLiquidityPoolMigrationLib.TempListArgs(
        admins,
        maintainers,
        registeredLPsList,
        activeLPsList
      ),
      finder
    );
  }
}