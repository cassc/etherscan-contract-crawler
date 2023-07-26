// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title BorrowingVault
 *
 * @author Fujidao Labs
 *
 * @notice Upgradeable implementation of {BorrowingVault.sol}.
 */

import {
  IERC20Upgradeable as IERC20,
  IERC20MetadataUpgradeable as IERC20Metadata
} from
  "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {IVaultUpgradeable} from "../../interfaces/IVaultUpgradeable.sol";
import {ILendingProvider} from "../../interfaces/ILendingProvider.sol";
import {IFujiOracle} from "../../interfaces/IFujiOracle.sol";
import {SafeERC20Upgradeable as SafeERC20} from
  "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {MathUpgradeable as Math} from
  "openzeppelin-contracts-upgradeable/contracts/utils/math/MathUpgradeable.sol";
import {BaseVaultUpgradeable} from "../../abstracts/BaseVaultUpgradeable.sol";
import {VaultPermissions} from "../VaultPermissions.sol";

contract BorrowingVaultUpgradeable is BaseVaultUpgradeable {
  using Math for uint256;
  using SafeERC20 for IERC20Metadata;

  /**
   * @dev Emitted when a user is liquidated.
   *
   * @param caller of liquidation
   * @param receiver of liquidation bonus
   * @param owner whose assets are being liquidated
   * @param collateralSold `owner`'s amount of collateral sold during liquidation
   * @param debtPaid `owner`'s amount of debt paid back during liquidation
   * @param price price of collateral at which liquidation was done
   * @param liquidationFactor what % of debt was liquidated
   */
  event Liquidate(
    address indexed caller,
    address indexed receiver,
    address indexed owner,
    uint256 collateralSold,
    uint256 debtPaid,
    uint256 price,
    uint256 liquidationFactor
  );

  /// @dev Custom errors
  error BorrowingVault__borrow_invalidInput();
  error BorrowingVault__borrow_moreThanAllowed();
  error BorrowingVault__payback_invalidInput();
  error BorrowingVault__beforeTokenTransfer_moreThanMax();
  error BorrowingVault__liquidate_invalidInput();
  error BorrowingVault__liquidate_positionHealthy();
  error BorrowingVault__liquidate_moreThanAllowed();
  error BorrowingVault__rebalance_invalidProvider();
  error BorrowingVault__borrow_slippageTooHigh();
  error BorrowingVault__mintDebt_slippageTooHigh();
  error BorrowingVault__payback_slippageTooHigh();
  error BorrowingVault__burnDebt_slippageTooHigh();
  error BorrowingVault__burnDebtShares_amountExceedsBalance();
  error BorrowingVault__initializeVaultShares_assetDebtRatioExceedsMaxLtv();

  /*///////////////////
   Liquidation controls
  ////////////////////*/

  uint256 private constant PRECISION_CONSTANT = 1e18;

  /// @notice Returns default liquidation close factor: 50% of debt.
  uint256 public constant DEFAULT_LIQUIDATION_CLOSE_FACTOR = 0.5e18;

  /// @notice Returns max liquidation close factor: 100% of debt.
  uint256 public constant MAX_LIQUIDATION_CLOSE_FACTOR = PRECISION_CONSTANT;

  /// @notice Returns health factor threshold at which max liquidation can occur.
  uint256 public constant FULL_LIQUIDATION_THRESHOLD = 95e16;

  /// @notice Returns the penalty factor at which collateral is sold during liquidation: 90% below oracle price.
  uint256 public constant LIQUIDATION_PENALTY = 0.9e18;

  IERC20Metadata internal _debtAsset;
  uint8 internal _debtDecimals;

  uint256 public debtSharesSupply;

  mapping(address => uint256) internal _debtShares;

  IFujiOracle public oracle;

  /**
   * @dev Factor See: https://github.com/Fujicracy/CrossFuji/tree/main/packages/protocol#readme
   */

  /// @notice Returns the factor defining the maximum loan-to-value a user can take in this vault.
  uint256 public maxLtv;

  /// @notice Returns the factor defining the loan-to-value at which a user can be liquidated.
  uint256 public liqRatio;

  /**
   * @notice Initialize a new {BorrowingVault}.
   *
   * @param asset_ this vault will handle as main asset (collateral)
   * @param debtAsset_ this vault will handle as debt asset
   * @param chief_ that deploys and controls this vault
   * @param name_ string of the token-shares handled in this vault
   * @param symbol_ string of the token-shares handled in this vault
   * @param providers_ array that will initialize this vault
   *
   * @dev Requirements:
   * - Must be initialized with a set of providers.
   * - Must set first provider in `providers_` array as `activeProvider`.
   */
  function initialize(
    address asset_,
    address debtAsset_,
    address chief_,
    string memory name_,
    string memory symbol_,
    ILendingProvider[] memory providers_
  )
    public
    initializer
  {
    __BaseVault_initialize(asset_, chief_, name_, symbol_);
    _debtAsset = IERC20Metadata(debtAsset_);
    _debtDecimals = IERC20Metadata(debtAsset_).decimals();
    _setProviders(providers_);
    _setActiveProvider(providers_[0]);
  }

  receive() external payable {}

  /*//////////////////////////////////////////
      Asset management: overrides IERC4626
  //////////////////////////////////////////*/

  /// @inheritdoc BaseVaultUpgradeable
  function maxWithdraw(address owner) public view override returns (uint256) {
    if (paused(VaultActions.Withdraw)) {
      return 0;
    }
    return _computeFreeAssets(owner);
  }

  /// @inheritdoc BaseVaultUpgradeable
  function maxRedeem(address owner) public view override returns (uint256) {
    if (paused(VaultActions.Withdraw)) {
      return 0;
    }
    return convertToShares(maxWithdraw(owner));
  }

  /*///////////////////////////////
  /// Debt management overrides ///
  ///////////////////////////////*/

  /**
   * @dev Hook before all asset-share transfers.
   * Requirements:
   * - Must check `from` can move `amount` of shares.
   *
   * @param from address
   * @param to address
   * @param amount of shares
   */
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal view override {
    /**
     * @dev Hook check activated only when called by OZ {ERC20-_transfer}
     * User must not be able to transfer asset-shares locked as collateral
     */
    if (from != address(0) && to != address(0)) {
      if (amount > maxRedeem(from)) {
        revert BorrowingVault__beforeTokenTransfer_moreThanMax();
      }
    }
  }

  /// @inheritdoc IVaultUpgradeable
  function debtDecimals() public view override returns (uint8) {
    return _debtDecimals;
  }

  /// @inheritdoc IVaultUpgradeable
  function debtAsset() public view override returns (address) {
    return address(_debtAsset);
  }

  /// @inheritdoc IVaultUpgradeable
  function balanceOfDebt(address owner) public view override returns (uint256 debt) {
    return convertToDebt(_debtShares[owner]);
  }

  /// @inheritdoc IVaultUpgradeable
  function balanceOfDebtShares(address owner) external view override returns (uint256 debtShares) {
    return _debtShares[owner];
  }

  /// @inheritdoc IVaultUpgradeable
  function totalDebt() public view override returns (uint256) {
    return _checkProvidersBalance("getBorrowBalance");
  }

  /// @inheritdoc IVaultUpgradeable
  function convertDebtToShares(uint256 debt) public view override returns (uint256 shares) {
    return _convertDebtToShares(debt, Math.Rounding.Up);
  }

  /// @inheritdoc IVaultUpgradeable
  function convertToDebt(uint256 shares) public view override returns (uint256 debt) {
    return _convertToDebt(shares, Math.Rounding.Up);
  }

  /// @inheritdoc IVaultUpgradeable
  function maxBorrow(address borrower) public view override returns (uint256) {
    if (paused(VaultActions.Borrow)) {
      return 0;
    }
    return _computeMaxBorrow(borrower);
  }

  /// @inheritdoc IVaultUpgradeable
  function maxPayback(address borrower) public view override returns (uint256) {
    if (paused(VaultActions.Payback)) {
      return 0;
    }
    return previewBurnDebt(maxBurnDebt(borrower));
  }

  /// @inheritdoc IVaultUpgradeable
  function maxMintDebt(address borrower) public view override returns (uint256) {
    if (paused(VaultActions.Borrow)) {
      return 0;
    }
    return convertDebtToShares(maxBorrow(borrower));
  }

  /// @inheritdoc IVaultUpgradeable
  function maxBurnDebt(address borrower) public view override returns (uint256) {
    if (paused(VaultActions.Payback)) {
      return 0;
    }
    return _debtShares[borrower];
  }

  /// @inheritdoc IVaultUpgradeable
  function previewBorrow(uint256 debt) public view override returns (uint256 shares) {
    return _convertDebtToShares(debt, Math.Rounding.Up);
  }

  /// @inheritdoc IVaultUpgradeable
  function previewMintDebt(uint256 shares) public view override returns (uint256 debt) {
    return _convertToDebt(shares, Math.Rounding.Down);
  }

  /// @inheritdoc IVaultUpgradeable
  function previewPayback(uint256 debt) public view override returns (uint256 shares) {
    return _convertDebtToShares(debt, Math.Rounding.Down);
  }

  /// @inheritdoc IVaultUpgradeable
  function previewBurnDebt(uint256 shares) public view override returns (uint256 debt) {
    return _convertToDebt(shares, Math.Rounding.Up);
  }

  /// @inheritdoc BaseVaultUpgradeable
  function borrow(uint256 debt, address receiver, address owner) public override returns (uint256) {
    address caller = msg.sender;

    uint256 shares = previewBorrow(debt);
    _borrowChecks(caller, receiver, owner, debt, shares);
    _borrow(caller, receiver, owner, debt, shares);

    return shares;
  }

  /// @inheritdoc BaseVaultUpgradeable
  function mintDebt(
    uint256 shares,
    address receiver,
    address owner
  )
    public
    override
    returns (uint256)
  {
    uint256 debt = previewMintDebt(shares);
    address caller = msg.sender;

    _borrowChecks(caller, receiver, owner, debt, shares);
    _borrow(caller, receiver, owner, debt, shares);

    return debt;
  }

  /// @inheritdoc BaseVaultUpgradeable
  function payback(uint256 debt, address owner) public override returns (uint256 shares) {
    shares = previewPayback(debt);
    (shares,) = _paybackInternal(debt, shares, owner, msg.sender);
  }

  /// @inheritdoc BaseVaultUpgradeable
  function burnDebt(uint256 shares, address owner) public override returns (uint256 debt) {
    debt = previewBurnDebt(shares);
    (, debt) = _paybackInternal(debt, shares, owner, msg.sender);
  }

  /*///////////////////////
      Borrow allowances 
  ///////////////////////*/

  /// @inheritdoc BaseVaultUpgradeable
  function borrowAllowance(
    address owner,
    address operator,
    address receiver
  )
    public
    view
    virtual
    override
    returns (uint256)
  {
    return VaultPermissions.borrowAllowance(owner, operator, receiver);
  }

  /// @inheritdoc BaseVaultUpgradeable
  function increaseBorrowAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    public
    virtual
    override
    returns (bool)
  {
    return VaultPermissions.increaseBorrowAllowance(operator, receiver, byAmount);
  }

  /// @inheritdoc BaseVaultUpgradeable
  function decreaseBorrowAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    public
    virtual
    override
    returns (bool)
  {
    return VaultPermissions.decreaseBorrowAllowance(operator, receiver, byAmount);
  }

  /// @inheritdoc BaseVaultUpgradeable
  function permitBorrow(
    address owner,
    address receiver,
    uint256 value,
    uint256 deadline,
    bytes32 actionArgsHash,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    public
    override
  {
    VaultPermissions.permitBorrow(owner, receiver, value, deadline, actionArgsHash, v, r, s);
  }

  /**
   * @dev Computes max borrow amount a user can take given their 'asset'
   * (collateral) balance and price.
   * Requirements:
   * - Must read price from {FujiOracle}.
   *
   * @param borrower to whom to check max borrow amount
   */
  function _computeMaxBorrow(address borrower) internal view returns (uint256 max) {
    uint256 price = oracle.getPriceOf(debtAsset(), asset(), _debtDecimals);
    uint256 assetShares = balanceOf(borrower);
    uint256 assets = convertToAssets(assetShares);
    uint256 debtShares = _debtShares[borrower];
    uint256 debt = convertToDebt(debtShares);

    uint256 baseUserMaxBorrow = assets.mulDiv(maxLtv * price, 10 ** decimals() * PRECISION_CONSTANT);
    max = baseUserMaxBorrow > debt ? baseUserMaxBorrow - debt : 0;
  }

  /**
   * @dev Compute how much free 'assets' a user can withdraw or transfer
   * given their `balanceOfDebt()`.
   * Requirements:
   * - Must be implemented in {BorrowingVault} contract.
   * - Must not be implemented in a {YieldVault} contract.
   * - Must read price from {FujiOracle}.
   *
   * @param owner address to whom free assets is being checked
   */
  function _computeFreeAssets(address owner) internal view returns (uint256 freeAssets) {
    uint256 debtShares = _debtShares[owner];
    uint256 assets = convertToAssets(balanceOf(owner));

    // Handle no debt case.
    if (debtShares == 0) {
      freeAssets = assets;
    } else {
      uint256 debt = convertToDebt(debtShares);
      uint256 price = oracle.getPriceOf(asset(), debtAsset(), decimals());
      uint256 lockedAssets = debt.mulDiv(price * PRECISION_CONSTANT, maxLtv * 10 ** _debtDecimals);

      if (lockedAssets == 0) {
        // Handle wei level amounts in where 'lockedAssets' < 1 wei.
        lockedAssets = 1;
      }

      freeAssets = assets > lockedAssets ? assets - lockedAssets : 0;
    }
  }

  /**
   * @dev Conversion function from debt to `debtShares` with support for rounding direction.
   * Requirements:
   * - Must revert if debt > 0, debtSharesSupply > 0 and totalDebt = 0.
   *   (Corresponds to a case where you divide by zero.)
   * - Must return `debt` if `debtSharesSupply` == 0.
   *
   * @param debt amount to convert to `debtShares`
   * @param rounding direction of division remainder
   */
  function _convertDebtToShares(
    uint256 debt,
    Math.Rounding rounding
  )
    internal
    view
    returns (uint256 shares)
  {
    return debt.mulDiv(debtSharesSupply + 1, totalDebt() + 1, rounding);
  }

  /**
   * @dev Conversion function from `debtShares` to debt with support for rounding direction.
   * Requirements:
   * - Must return zero if `debtSharesSupply` == 0.
   *
   * @param shares amount to convert to `debt`
   * @param rounding direction of division remainder
   */
  function _convertToDebt(
    uint256 shares,
    Math.Rounding rounding
  )
    internal
    view
    returns (uint256 assets)
  {
    return shares.mulDiv(totalDebt() + 1, debtSharesSupply + 1, rounding);
  }

  /**
   * @dev Perform borrow action at provdier. Borrow/mintDebtShares common workflow.
   * Requirements:
   * - Must call `activeProvider` in `_executeProviderAction()`.
   * - Must emit a Borrow event.
   *
   * @param caller or operator
   * @param receiver to whom borrowed amount is transferred
   * @param owner to whom `debtShares` get minted
   * @param assets amount of debt
   * @param shares amount of `debtShares`
   */
  function _borrow(
    address caller,
    address receiver,
    address owner,
    uint256 assets,
    uint256 shares
  )
    internal
    whenNotPaused(VaultActions.Borrow)
  {
    _mintDebtShares(owner, shares);

    _executeProviderAction(assets, "borrow", activeProvider);

    _debtAsset.safeTransfer(receiver, assets);

    emit Borrow(caller, receiver, owner, assets, shares);
  }

  /**
   * @dev Runs common checks for all "borrow" or "mintDebt" actions in this vault.
   * Requirements:
   * - Must revert for all conditions not passed.
   *
   * @param caller msg.sender in this context
   * @param receiver of the borrow amount
   * @param owner of the debt accountability
   * @param debt or borrowed amount of debt asset
   * @param shares corresponding to debt
   */
  function _borrowChecks(
    address caller,
    address receiver,
    address owner,
    uint256 debt,
    uint256 shares
  )
    private
  {
    if (debt == 0 || shares == 0 || receiver == address(0) || owner == address(0)) {
      revert BorrowingVault__borrow_invalidInput();
    }
    if (debt > maxBorrow(owner)) {
      revert BorrowingVault__borrow_moreThanAllowed();
    }
    if (caller != owner) {
      _spendBorrowAllowance(owner, caller, receiver, debt);
    }
  }

  /**
   * @dev Function to handle common flow for `payback(...)` and `burnDebt(...)`
   * It returns the updated `debt` and `shares` values if applicable.
   *
   * @param debt or borrowed amount of debt asset
   * @param shares amount of `debtShares`
   * @param owner to whom `debtShares` will bet burned
   * @param caller msg.sender
   */
  function _paybackInternal(
    uint256 debt,
    uint256 shares,
    address owner,
    address caller
  )
    internal
    returns (uint256 debt_, uint256 shares_)
  {
    uint256 remainder;
    // `debt`, `shares`are updated if passing more than max amount for `owner`'s debt.
    (debt_, shares_, remainder) = _paybackChecks(owner, debt, shares);

    _payback(caller, owner, debt_, shares_);

    if (remainder > 0) {
      /**
       * @devSince the `_payback(...) only pulls (erc20) that is needed to payback
       * maxAmount, this logic handles excess amount `remainder` by pulling from
       * `msg.sender and returning to the `owner` the `remainder`.
       */
      _debtAsset.safeTransferFrom(caller, owner, remainder);
    }
  }

  /**
   * @dev Perform payback action at provider. Payback/burnDebtShares common workflow.
   * Requirements:
   * - Must call `activeProvider` in `_executeProviderAction()`.
   * - Must emit a Payback event.
   *
   * @param caller msg.sender
   * @param owner to whom `debtShares` will bet burned
   * @param assets amount of debt
   * @param shares amount of `debtShares`
   */
  function _payback(
    address caller,
    address owner,
    uint256 assets,
    uint256 shares
  )
    internal
    whenNotPaused(VaultActions.Payback)
  {
    _debtAsset.safeTransferFrom(caller, address(this), assets);

    _executeProviderAction(assets, "payback", activeProvider);

    _burnDebtShares(owner, shares);

    emit Payback(caller, owner, assets, shares);
  }

  /**
   * @dev Runs common checks for all "payback" or "burnDebt" actions in this vault.
   *  It returns maximum possible debt to payback, shares equivalent, and remainder.
   * The `remainder` will be non-zero if the passed `shares` arg exceeds
   * the debtShare balance of `owner`.
   * Requirements:
   * - Must revert for all conditions not passed.
   *
   * @param owner of the debt accountability
   * @param debt or borrowed amount of debt asset
   * @param shares of debt being burned
   */
  function _paybackChecks(
    address owner,
    uint256 debt,
    uint256 shares
  )
    private
    view
    returns (uint256 debt_, uint256 shares_, uint256 remainder)
  {
    if (owner == address(0) || debt == 0 || shares == 0) {
      revert BorrowingVault__payback_invalidInput();
    }
    // This local var helps save gas not having to call provider balances again
    // and is multiplied by debtAsset decimals to mantain precision.
    uint256 shareExchangeRatio = debt.mulDiv(10 ** _debtDecimals, shares);

    if (shares > _debtShares[owner]) {
      shares_ = _debtShares[owner];
      debt_ = shares_.mulDiv(shareExchangeRatio, 10 ** _debtDecimals);
      remainder = debt > debt_ ? debt - debt_ : 0;
    } else {
      shares_ = shares;
      debt_ = shares_.mulDiv(shareExchangeRatio, 10 ** _debtDecimals);
    }
  }

  /**
   * @dev Common workflow to update state and mint `debtShares`.
   *
   * @param owner to whom shares get minted
   * @param amount of shares
   */
  function _mintDebtShares(address owner, uint256 amount) internal {
    debtSharesSupply += amount;
    _debtShares[owner] += amount;
  }

  /**
   * @dev Common workflow to update state and burn `debtShares`.
   *
   * @param owner to whom shares get burned
   * @param amount of shares
   */
  function _burnDebtShares(address owner, uint256 amount) internal {
    uint256 balance = _debtShares[owner];
    if (balance < amount) {
      revert BorrowingVault__burnDebtShares_amountExceedsBalance();
    }
    unchecked {
      _debtShares[owner] = balance - amount;
    }
    debtSharesSupply -= amount;
  }

  /*/////////////////
      Rebalancing 
  /////////////////*/

  /// @inheritdoc IVaultUpgradeable
  function rebalance(
    uint256 assets,
    uint256 debt,
    ILendingProvider from,
    ILendingProvider to,
    uint256 fee,
    bool setToAsActiveProvider
  )
    external
    hasRole(msg.sender, REBALANCER_ROLE)
    returns (bool)
  {
    if (!_isValidProvider(address(from)) || !_isValidProvider(address(to))) {
      revert BorrowingVault__rebalance_invalidProvider();
    }
    if (debt > 0) {
      _debtAsset.safeTransferFrom(msg.sender, address(this), debt);
      _executeProviderAction(debt, "payback", from);
    }
    if (assets > 0) {
      _executeProviderAction(assets, "withdraw", from);
    }

    _checkRebalanceFee(fee, debt);

    if (assets > 0) {
      _executeProviderAction(assets, "deposit", to);
    }
    if (debt > 0) {
      _executeProviderAction(debt + fee, "borrow", to);
      _debtAsset.safeTransfer(msg.sender, debt + fee);
    }

    if (setToAsActiveProvider) {
      _setActiveProvider(to);
    }

    emit VaultRebalance(assets, debt, address(from), address(to));
    return true;
  }

  /*////////////////////
       Liquidation  
  ////////////////////*/

  /// @inheritdoc IVaultUpgradeable
  function getHealthFactor(address owner) public view returns (uint256 healthFactor) {
    uint256 debtShares = _debtShares[owner];
    uint256 debt = convertToDebt(debtShares);

    if (debt == 0) {
      healthFactor = type(uint256).max;
    } else {
      uint256 assetShares = balanceOf(owner);
      uint256 assets = convertToAssets(assetShares);
      uint256 price = oracle.getPriceOf(debtAsset(), asset(), _debtDecimals);

      healthFactor = (assets * liqRatio * price) / (debt * 10 ** decimals());
    }
  }

  /// @inheritdoc IVaultUpgradeable
  function getLiquidationFactor(address owner) public view returns (uint256 liquidationFactor) {
    uint256 healthFactor = getHealthFactor(owner);

    if (healthFactor >= PRECISION_CONSTANT) {
      liquidationFactor = 0;
    } else if (FULL_LIQUIDATION_THRESHOLD <= healthFactor) {
      liquidationFactor = DEFAULT_LIQUIDATION_CLOSE_FACTOR; // 50% of owner's debt
    } else {
      liquidationFactor = MAX_LIQUIDATION_CLOSE_FACTOR; // 100% of owner's debt
    }
  }

  /// @inheritdoc IVaultUpgradeable
  function liquidate(
    address owner,
    address receiver,
    uint256 liqCloseFactor_
  )
    external
    hasRole(msg.sender, LIQUIDATOR_ROLE)
    returns (uint256 gainedShares)
  {
    if (receiver == address(0)) {
      revert BorrowingVault__liquidate_invalidInput();
    }

    address caller = msg.sender;

    uint256 liquidationFactor = getLiquidationFactor(owner);
    if (liquidationFactor == 0) {
      revert BorrowingVault__liquidate_positionHealthy();
    }
    if (liqCloseFactor_ > liquidationFactor) {
      revert BorrowingVault__liquidate_moreThanAllowed();
    }

    // Compute debt amount that must be paid by liquidator.
    uint256 debt = convertToDebt(_debtShares[owner]);
    uint256 debtSharesToCover = Math.mulDiv(_debtShares[owner], liqCloseFactor_, PRECISION_CONSTANT);
    uint256 debtToCover = Math.mulDiv(debt, liqCloseFactor_, PRECISION_CONSTANT);

    // Compute `gainedShares` amount that the liquidator will receive.
    uint256 price = oracle.getPriceOf(debtAsset(), asset(), _debtDecimals);
    uint256 discountedPrice = Math.mulDiv(price, LIQUIDATION_PENALTY, PRECISION_CONSTANT);

    uint256 gainedAssets = Math.mulDiv(debtToCover, 10 ** _asset.decimals(), discountedPrice);
    gainedShares = convertToShares(gainedAssets);

    _payback(caller, owner, debtToCover, debtSharesToCover);

    // Ensure liquidator receives no more shares than 'owner' owns.
    uint256 existingShares = maxRedeem(owner);
    if (gainedShares > existingShares) {
      gainedShares = existingShares;
    }

    // Internal share adjusment between 'owner' and 'liquidator'.
    _burn(owner, gainedShares);
    _mint(receiver, gainedShares);

    emit Liquidate(caller, receiver, owner, gainedShares, debtToCover, price, liquidationFactor);
  }

  /*/////////////////////////
      Admin set functions 
  /////////////////////////*/

  /**
   * @notice Sets `newOracle` address as the {FujiOracle} for this vault.
   *
   * @param newOracle address
   *
   * @dev Requirements:
   * - Must not be address zero.
   * - Must emit a OracleChanged event.
   * - Must be called from a timelock.
   */
  function setOracle(IFujiOracle newOracle) external onlyTimelock {
    if (address(newOracle) == address(0)) {
      revert BaseVault__setter_invalidInput();
    }
    oracle = newOracle;
    emit OracleChanged(newOracle);
  }

  /**
   * @notice Sets the maximum loan-to-value factor and the Loan-To-Value liquidation threshold factor of this vault.
   *
   * @param maxLtv_ factor to be set
   * @param liqRatio_ factor to be set
   *
   * @dev See factor
   * https://github.com/Fujicracy/fuji-v2/tree/main/packages/protocol#readme.
   *
   * Restrictions for 'liqRatio':
   * - Must be greater than 'maxLTV'.
   * - Must be at least 2% (2e16).
   * - Must be less than 100% (PRECISION_CONSTANT).
   * Restrictions for 'maxLtv':
   * - Must be at least 1% (1e16).
   * - Must be less than 100% (PRECISION_CONSTANT).
   */
  function setLtvFactors(uint256 maxLtv_, uint256 liqRatio_) external onlyTimelock {
    if (
      liqRatio_ <= maxLtv_ || liqRatio_ <= maxLtv || liqRatio_ < 2e16
        || liqRatio_ >= PRECISION_CONSTANT || maxLtv_ < 1e16 || maxLtv_ >= PRECISION_CONSTANT
    ) {
      revert BaseVault__setter_invalidInput();
    }

    maxLtv = maxLtv_;
    liqRatio = liqRatio_;

    emit MaxLtvChanged(maxLtv);
    emit LiqRatioChanged(liqRatio);
  }

  /// @inheritdoc BaseVaultUpgradeable
  function _setProviders(ILendingProvider[] memory providers) internal override {
    uint256 len = providers.length;
    for (uint256 i = 0; i < len;) {
      if (address(providers[i]) == address(0)) {
        revert BaseVault__setter_invalidInput();
      }
      _asset.forceApprove(
        providers[i].approvedOperator(asset(), asset(), debtAsset()), type(uint256).max
      );
      _debtAsset.forceApprove(
        providers[i].approvedOperator(debtAsset(), asset(), debtAsset()), type(uint256).max
      );
      unchecked {
        ++i;
      }
    }
    _providers = providers;

    emit ProvidersChanged(providers);
  }
}