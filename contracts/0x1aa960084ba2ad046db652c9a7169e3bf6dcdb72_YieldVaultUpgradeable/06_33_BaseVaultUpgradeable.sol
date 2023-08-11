// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title BaseVaultUpgradeable
 *
 * @author Fujidao Labs
 *
 * @notice Upgradeable version of {BaseVault}.
 */
import {
  ERC20Upgradeable,
  IERC20Upgradeable
} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {Initializable} from
  "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {IERC20MetadataUpgradeable as IERC20Metadata} from
  "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {SafeERC20Upgradeable} from
  "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {MathUpgradeable} from
  "openzeppelin-contracts-upgradeable/contracts/utils/math/MathUpgradeable.sol";
import {AddressUpgradeable} from
  "openzeppelin-contracts-upgradeable/contracts/utils/AddressUpgradeable.sol";
import {IVaultUpgradeable} from "../interfaces/IVaultUpgradeable.sol";
import {ILendingProvider} from "../interfaces/ILendingProvider.sol";
import {IERC4626Upgradeable} from
  "openzeppelin-contracts-upgradeable/contracts/interfaces/IERC4626Upgradeable.sol";
import {VaultPermissions} from "../vaults/VaultPermissions.sol";
import {SystemAccessControl} from "../access/SystemAccessControl.sol";
import {PausableVault} from "./PausableVault.sol";

abstract contract BaseVaultUpgradeable is
  Initializable,
  ERC20Upgradeable,
  SystemAccessControl,
  PausableVault,
  VaultPermissions,
  IVaultUpgradeable
{
  using MathUpgradeable for uint256;
  using AddressUpgradeable for address;
  using SafeERC20Upgradeable for IERC20Metadata;

  /// @dev Custom Errors
  error BaseVault__initialize_invalidInput();
  error BaseVault__initializeVaultShares_alreadyInitialized();
  error BaseVault__initialize_lessThanMin();
  error BaseVault__deposit_invalidInput();
  error BaseVault__deposit_moreThanMax();
  error BaseVault__deposit_lessThanMin();
  error BaseVault__withdraw_invalidInput();
  error BaseVault__setter_invalidInput();
  error BaseVault__checkRebalanceFee_excessFee();
  error BaseVault__deposit_slippageTooHigh();
  error BaseVault__mint_slippageTooHigh();
  error BaseVault__withdraw_slippageTooHigh();
  error BaseVault__redeem_slippageTooHigh();
  error BaseVault__useIncreaseWithdrawAllowance();
  error BaseVault__useDecreaseWithdrawAllowance();

  /**
   *  @dev `VERSION` of this vault.
   * Software versioning rules are followed: v-0.0.0 (v-MAJOR.MINOR.PATCH)
   * Major version when you make incompatible ABI changes
   * Minor version when you add functionality in a backwards compatible manner.
   * Patch version when you make backwards compatible fixes.
   */
  string public constant VERSION = string("0.2.0");

  IERC20Metadata internal _asset;

  uint8 private _decimals;

  ILendingProvider[] internal _providers;
  ILendingProvider public activeProvider;

  uint256 public minAmount;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Initialize the BaseVault params.
   *
   * @param asset_ this vault will handle as main asset (collateral)
   * @param chief_ that deploys and controls this vault
   * @param name_ string of the token-shares handled in this vault
   * @param symbol_ string of the token-shares handled in this vault
   *
   * @dev Requirements:
   * - Must be called by children contract initialize function
   *
   * NOTE: Initialization of shares to protect against inflation
   * is done at {BorrowingVaultFactoryProxy}.
   * Proxies cannot initialize shares from within factory via the
   * Create2 library due to the delegate call required to provider.
   */
  function __BaseVault_initialize(
    address asset_,
    address chief_,
    string memory name_,
    string memory symbol_
  )
    internal
  {
    if (asset_ == address(0) || chief_ == address(0)) {
      revert BaseVault__initialize_invalidInput();
    }
    _asset = IERC20Metadata(asset_);
    _decimals = IERC20Metadata(asset_).decimals();
    minAmount = 1e6;

    __ERC20_init(name_, symbol_);
    __SystemAccessControl_init(chief_);
    __EIP712_initialize(name_, VERSION);

    emit VaultInitialized(msg.sender);
  }

  /*////////////////////////////////////////////////////
      Asset management: allowance {IERC20} overrides 
      Overrides to handle as `withdrawAllowance`
  ///////////////////////////////////////////////////*/

  /**
   * @notice Returns the shares amount allowed to transfer from
   *  `owner` to `receiver`.
   *
   * @param owner of the shares
   * @param receiver that can receive the shares
   *
   * @dev Requirements:
   * - Must be overriden to call {VaultPermissions-withdrawAllowance}.
   */
  function allowance(
    address owner,
    address receiver
  )
    public
    view
    override(ERC20Upgradeable, IERC20Upgradeable)
    returns (uint256)
  {
    /// @dev operator = receiver
    return convertToShares(withdrawAllowance(owner, receiver, receiver));
  }

  /**
   * @notice Approve allowance of `shares` to `receiver`.
   *
   * @param receiver to whom share allowance is being set
   * @param shares amount of allowance
   *
   * @dev Recommend to use increase/decrease WithdrawAllowance methods.
   * - Must be overriden to call {VaultPermissions-_setWithdrawAllowance}.
   * - Must convert `shares` into `assets` amount before calling internal functions.
   */
  function approve(
    address receiver,
    uint256 shares
  )
    public
    override(ERC20Upgradeable, IERC20Upgradeable)
    returns (bool)
  {
    /// @dev operator = receiver and owner = msg.sender
    _setWithdrawAllowance(msg.sender, receiver, receiver, convertToAssets(shares));
    emit Approval(msg.sender, receiver, shares);
    return true;
  }

  /**
   * @notice This method in OZ erc20-implementation has been disabled in favor of
   * {VaultPermissions-increaseWithdrawAllowance()}.
   */
  function increaseAllowance(address, uint256) public pure override returns (bool) {
    revert BaseVault__useIncreaseWithdrawAllowance();
  }

  /**
   * @notice This method in OZ erc20-implementation has been disabled in favor of
   * {VaultPermissions-decreaseWithdrawAllowance()}.
   */
  function decreaseAllowance(address, uint256) public pure override returns (bool) {
    revert BaseVault__useDecreaseWithdrawAllowance();
  }

  /**
   * @dev Called during {ERC20-transferFrom} to decrease allowance.
   * Requirements:
   * - Must be overriden to call {VaultPermissions-_spendWithdrawAllowance}.
   * - Must convert `shares` to `assets` before calling internal functions.
   * - Must assume msg.sender as the operator.
   *
   * @param owner of `shares`
   * @param spender to whom `shares` will be spent
   * @param shares amount to spend
   */
  function _spendAllowance(address owner, address spender, uint256 shares) internal override {
    _spendWithdrawAllowance(owner, msg.sender, spender, convertToAssets(shares));
  }

  /*//////////////////////////////////////////
      Asset management: overrides IERC4626Upgradeable
  //////////////////////////////////////////*/

  /**
   * @notice Returns the number of decimals used to get number representation.
   */
  function decimals()
    public
    view
    virtual
    override(ERC20Upgradeable, IERC20Metadata)
    returns (uint8)
  {
    return _decimals;
  }

  /// @inheritdoc IERC4626Upgradeable
  function asset() public view virtual override returns (address) {
    return address(_asset);
  }

  /// @inheritdoc IVaultUpgradeable
  function balanceOfAsset(address owner) external view virtual override returns (uint256 assets) {
    return convertToAssets(balanceOf(owner));
  }

  /// @inheritdoc IERC4626Upgradeable
  function totalAssets() public view virtual override returns (uint256 assets) {
    return _checkProvidersBalance("getDepositBalance");
  }

  /// @inheritdoc IERC4626Upgradeable
  function convertToShares(uint256 assets) public view virtual override returns (uint256 shares) {
    return _convertToShares(assets, MathUpgradeable.Rounding.Down);
  }

  /// @inheritdoc IERC4626Upgradeable
  function convertToAssets(uint256 shares) public view virtual override returns (uint256 assets) {
    return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
  }

  /// @inheritdoc IERC4626Upgradeable
  function maxDeposit(address) public view virtual override returns (uint256) {
    if (paused(VaultActions.Deposit)) {
      return 0;
    }
    return type(uint256).max;
  }

  /// @inheritdoc IERC4626Upgradeable
  function maxMint(address) public view virtual override returns (uint256) {
    if (paused(VaultActions.Deposit)) {
      return 0;
    }
    return type(uint256).max;
  }

  /// @inheritdoc IERC4626Upgradeable
  function maxWithdraw(address owner) public view virtual override returns (uint256);

  /// @inheritdoc IERC4626Upgradeable
  function maxRedeem(address owner) public view virtual override returns (uint256);

  /// @inheritdoc IERC4626Upgradeable
  function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
    return _convertToShares(assets, MathUpgradeable.Rounding.Down);
  }

  /// @inheritdoc IERC4626Upgradeable
  function previewMint(uint256 shares) public view virtual override returns (uint256) {
    return _convertToAssets(shares, MathUpgradeable.Rounding.Up);
  }

  /// @inheritdoc IERC4626Upgradeable
  function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
    return _convertToShares(assets, MathUpgradeable.Rounding.Up);
  }

  /// @inheritdoc IERC4626Upgradeable
  function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
    return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
  }

  /// @inheritdoc IERC4626Upgradeable
  function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
    uint256 shares = previewDeposit(assets);

    _depositChecks(receiver, assets, shares);
    _deposit(msg.sender, receiver, assets, shares);

    return shares;
  }

  /// @inheritdoc IERC4626Upgradeable
  function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
    uint256 assets = previewMint(shares);

    _depositChecks(receiver, assets, shares);
    _deposit(msg.sender, receiver, assets, shares);

    return assets;
  }

  /// @inheritdoc IERC4626Upgradeable
  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  )
    public
    override
    returns (uint256)
  {
    uint256 shares = previewWithdraw(assets);
    (, shares) = _withdrawInternal(assets, shares, msg.sender, receiver, owner);
    return shares;
  }

  /// @inheritdoc IERC4626Upgradeable
  function redeem(
    uint256 shares,
    address receiver,
    address owner
  )
    public
    override
    returns (uint256)
  {
    uint256 assets = previewRedeem(shares);
    (assets,) = _withdrawInternal(assets, shares, msg.sender, receiver, owner);
    return assets;
  }

  /**
   * @dev Conversion function from `assets` to shares equivalent with support for rounding direction.
   * Requirements:
   * - Must return zero if `assets` or `totalSupply()` == 0.
   * - Must revert if `totalAssets()` is not > 0.
   *   (Corresponds to a case where you divide by zero.)
   *
   * @param assets amount to convert to shares
   * @param rounding direction of division remainder
   */
  function _convertToShares(
    uint256 assets,
    MathUpgradeable.Rounding rounding
  )
    internal
    view
    virtual
    returns (uint256 shares)
  {
    uint256 supply = totalSupply();
    return (assets == 0 || supply == 0) ? assets : assets.mulDiv(supply, totalAssets(), rounding);
  }

  /**
   * @dev Conversion function from `shares` to asset type with support for rounding direction.
   * Requirements:
   * - Must return zero if `totalSupply()` == 0.
   *
   * @param shares amount to convert to assets
   * @param rounding direction of division remainder
   */
  function _convertToAssets(
    uint256 shares,
    MathUpgradeable.Rounding rounding
  )
    internal
    view
    virtual
    returns (uint256 assets)
  {
    uint256 supply = totalSupply();
    return (supply == 0) ? shares : shares.mulDiv(totalAssets(), supply, rounding);
  }

  /**
   * @dev Perform `_deposit()` at provider {IERC4626Upgradeable-deposit}.
   * Requirements:
   * - Must call `activeProvider` in `_executeProviderAction()`.
   * - Must emit a Deposit event.
   *
   * @param caller or {msg.sender}
   * @param receiver to whom `assets` are credited by `shares` amount
   * @param assets amount transferred during this deposit
   * @param shares amount credited to `receiver` during this deposit
   */
  function _deposit(
    address caller,
    address receiver,
    uint256 assets,
    uint256 shares
  )
    internal
    whenNotPaused(VaultActions.Deposit)
  {
    _asset.safeTransferFrom(caller, address(this), assets);
    _executeProviderAction(assets, "deposit", activeProvider);
    _mint(receiver, shares);

    emit Deposit(caller, receiver, assets, shares);
  }

  /**
   * @dev Runs common checks for all "deposit" or "mint" actions in this vault.
   * Requirements:
   * - Must revert for all conditions not passed.
   *
   * @param receiver of the deposit
   * @param assets being deposited
   * @param shares being minted for `receiver`
   */
  function _depositChecks(address receiver, uint256 assets, uint256 shares) private view {
    if (receiver == address(0) || assets == 0 || shares == 0) {
      revert BaseVault__deposit_invalidInput();
    }
    if (assets < minAmount) {
      revert BaseVault__deposit_lessThanMin();
    }
  }

  /**
   * @dev Function to handle common flow for `withdraw(...)` and `reddem(...)`
   * It returns the updated `assets_` and `shares_` values if applicable.
   *
   * @param assets amount transferred during this withraw
   * @param shares amount burned to `owner` during this withdraw
   * @param caller or {msg.sender}
   * @param receiver to whom `assets` amount will be transferred to
   * @param owner to whom `shares` will be burned
   */
  function _withdrawInternal(
    uint256 assets,
    uint256 shares,
    address caller,
    address receiver,
    address owner
  )
    internal
    returns (uint256 assets_, uint256 shares_)
  {
    /**
     * @dev If passed `assets` argument is greater than the max amount `owner` can withdraw
     * the maximum amount withdrawable will be withdrawn and returned from `withdrawChecks(...)`.
     */
    (assets_, shares_) = _withdrawChecks(caller, receiver, owner, assets, shares);
    _withdraw(caller, receiver, owner, assets_, shares_);
  }

  /**
   * @dev Perform `_withdraw()` at provider {IERC4626Upgradeable-withdraw}.
   * Requirements:
   * - Must call `activeProvider` in `_executeProviderAction()`.
   * - Must emit a Withdraw event.
   *
   * @param caller or {msg.sender}
   * @param receiver to whom `assets` amount will be transferred to
   * @param owner to whom `shares` will be burned
   * @param assets amount transferred during this withraw
   * @param shares amount burned to `owner` during this withdraw
   */
  function _withdraw(
    address caller,
    address receiver,
    address owner,
    uint256 assets,
    uint256 shares
  )
    internal
    virtual
    whenNotPaused(VaultActions.Withdraw)
  {
    _burn(owner, shares);
    _executeProviderAction(assets, "withdraw", activeProvider);
    _asset.safeTransfer(receiver, assets);

    emit Withdraw(caller, receiver, owner, assets, shares);
  }

  /**
   * @dev Runs common checks for all "withdraw" or "redeem" actions in this vault and returns maximum
   * `assets_` and `shares_` to withdraw if passed amounts exceed `owner's` debtShares/debt balance.
   * Requirements:
   * - Must revert for all conditions not passed.
   *
   * @param caller in msg.sender context
   * @param receiver of the withdrawn assets
   * @param owner of the withdrawn assets
   * @param assets being withdrawn
   * @param shares being burned for `owner`
   */
  function _withdrawChecks(
    address caller,
    address receiver,
    address owner,
    uint256 assets,
    uint256 shares
  )
    private
    returns (uint256 assets_, uint256 shares_)
  {
    if (receiver == address(0) || owner == address(0) || assets == 0 || shares == 0) {
      revert BaseVault__withdraw_invalidInput();
    }

    uint256 maxWithdraw_ = maxWithdraw(owner);
    if (assets > maxWithdraw_) {
      assets_ = maxWithdraw_;
      shares_ = assets_.mulDiv(shares, assets);
    } else {
      assets_ = assets;
      shares_ = shares;
    }
    if (caller != owner) {
      _spendWithdrawAllowance(owner, caller, receiver, assets_);
    }
  }

  /*//////////////////////////////////////////////////
      Debt management: based on IERC4626Upgradeable semantics
  //////////////////////////////////////////////////*/

  /// @inheritdoc IVaultUpgradeable
  function debtDecimals() public view virtual override returns (uint8);

  /// @inheritdoc IVaultUpgradeable
  function debtAsset() public view virtual returns (address);

  /// @inheritdoc IVaultUpgradeable
  function balanceOfDebt(address account) public view virtual override returns (uint256 debt);

  /// @inheritdoc IVaultUpgradeable
  function balanceOfDebtShares(address owner)
    external
    view
    virtual
    override
    returns (uint256 debtShares);

  /// @inheritdoc IVaultUpgradeable
  function totalDebt() public view virtual returns (uint256);

  /// @inheritdoc IVaultUpgradeable
  function convertDebtToShares(uint256 debt) public view virtual returns (uint256 shares);

  /// @inheritdoc IVaultUpgradeable
  function convertToDebt(uint256 shares) public view virtual returns (uint256 debt);

  /// @inheritdoc IVaultUpgradeable
  function maxBorrow(address borrower) public view virtual returns (uint256);

  /// @inheritdoc IVaultUpgradeable
  function maxPayback(address borrower) public view virtual returns (uint256);

  /// @inheritdoc IVaultUpgradeable
  function maxMintDebt(address borrower) public view virtual returns (uint256);

  /// @inheritdoc IVaultUpgradeable
  function maxBurnDebt(address borrower) public view virtual returns (uint256);

  /// @inheritdoc IVaultUpgradeable
  function previewBorrow(uint256 debt) public view virtual returns (uint256 shares);

  /// @inheritdoc IVaultUpgradeable
  function previewMintDebt(uint256 shares) public view virtual returns (uint256 debt);

  /// @inheritdoc IVaultUpgradeable
  function previewPayback(uint256 debt) public view virtual returns (uint256 shares);

  /// @inheritdoc IVaultUpgradeable
  function previewBurnDebt(uint256 shares) public view virtual returns (uint256 debt);

  /// @inheritdoc IVaultUpgradeable
  function borrow(
    uint256 debt,
    address receiver,
    address owner
  )
    public
    virtual
    returns (uint256 shares);

  /// @inheritdoc IVaultUpgradeable
  function mintDebt(
    uint256 shares,
    address receiver,
    address owner
  )
    public
    virtual
    returns (uint256 debt);

  /// @inheritdoc IVaultUpgradeable
  function payback(uint256 debt, address owner) public virtual returns (uint256 shares);

  /// @inheritdoc IVaultUpgradeable
  function burnDebt(uint256 shares, address owner) public virtual returns (uint256 debt);

  /**
   * @notice Returns borrow allowance. See {IVaultPermissions-borrowAllowance}.
   *
   * @param owner that provides borrow allowance
   * @param operator who can process borrow allowance on owner's behalf
   * @param receiver who can spend borrow allowance
   *
   * @dev Requirements:
   * - Must be implemented in a {BorrowingVault}, and revert in a {YieldVault}.
   */
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
  {}

  /**
   * @notice Increase borrow allowance. See {IVaultPermissions-decreaseborrowAllowance}.
   *
   * @param operator who can process borrow allowance on owner's behalf
   * @param receiver whom spending borrow allowance is increasing
   *
   * @dev Requirements:
   * - Must be immplemented in a {BorrowingVault}, and revert in a {YieldVault}.
   */
  function increaseBorrowAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    public
    virtual
    override
    returns (bool)
  {}

  /**
   * @notice Decrease borrow allowance. See {IVaultPermissions-decreaseborrowAllowance}.
   *
   * @param operator address who can process borrow allowance on owner's behalf
   * @param receiver address whom spending borrow allowance is decreasing
   *
   * @dev Requirements:
   * - Must be implemented in a {BorrowingVault}, revert in a {YieldVault}.
   */
  function decreaseBorrowAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    public
    virtual
    override
    returns (bool)
  {}

  /**
   * @notice Process signed permit for borrow allowance. See {IVaultPermissions-permitBorrow}.
   *
   * @param owner address who signed this permit
   * @param receiver address whom spending borrow allowance will be set
   * @param value amount of borrow allowance
   * @param deadline timestamp at when this permit expires
   * @param actionArgsHash keccak256 of the abi.encoded(args,actions) to be performed in {BaseRouter._internalBundle}
   * @param v signature value
   * @param r signature value
   * @param s signature value
   *
   * @dev Requirements:
   * - Must be implemented in a {BorrowingVault}, revert in a {YieldVault}.
   */
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
    virtual
    override
  {}

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
  // function _computeFreeAssets(address owner) internal view virtual returns (uint256);

  /*//////////////////////////
      Fuji Vault functions
  //////////////////////////*/

  /**
   * @dev Execute an action at provider.
   *
   * @param assets amount handled in this action
   * @param name string of the method to call
   * @param provider to whom action is being called
   */
  function _executeProviderAction(
    uint256 assets,
    string memory name,
    ILendingProvider provider
  )
    internal
  {
    bytes memory data = abi.encodeWithSignature(
      string(abi.encodePacked(name, "(uint256,address)")), assets, address(this)
    );
    address(provider).functionDelegateCall(
      data, string(abi.encodePacked(name, ": delegate call failed"))
    );
  }

  /**
   * @dev Returns balance of `asset` or `debtAsset` of this vault at all
   * listed providers in `_providers` array.
   *
   * @param method string method to call: "getDepositBalance" or "getBorrowBalance".
   */
  function _checkProvidersBalance(string memory method) internal view returns (uint256 assets) {
    uint256 len = _providers.length;
    bytes memory callData = abi.encodeWithSignature(
      string(abi.encodePacked(method, "(address,address)")), address(this), address(this)
    );
    bytes memory returnedBytes;
    for (uint256 i = 0; i < len;) {
      returnedBytes = address(_providers[i]).functionStaticCall(callData, ": balance call failed");
      assets += uint256(bytes32(returnedBytes));
      unchecked {
        ++i;
      }
    }
  }

  /*////////////////////
      Public getters
  /////////////////////*/

  /**
   * @notice Returns the array of providers of this vault.
   */
  function getProviders() external view returns (ILendingProvider[] memory list) {
    list = _providers;
  }

  /*/////////////////////////
       Admin set functions
  /////////////////////////*/

  /// @inheritdoc IVaultUpgradeable
  function setProviders(ILendingProvider[] memory providers) external onlyTimelock {
    _setProviders(providers);
  }

  /// @inheritdoc IVaultUpgradeable
  function setActiveProvider(ILendingProvider activeProvider_) external override onlyTimelock {
    _setActiveProvider(activeProvider_);
  }

  /// @inheritdoc IVaultUpgradeable
  function setMinAmount(uint256 amount) external override onlyTimelock {
    minAmount = amount;
    emit MinAmountChanged(amount);
  }

  /// @inheritdoc PausableVault
  function pauseForceAll() external override hasRole(msg.sender, PAUSER_ROLE) {
    _pauseForceAllActions();
  }

  /// @inheritdoc PausableVault
  function unpauseForceAll() external override hasRole(msg.sender, UNPAUSER_ROLE) {
    _unpauseForceAllActions();
  }

  /// @inheritdoc PausableVault
  function pause(VaultActions action) external virtual override hasRole(msg.sender, PAUSER_ROLE) {
    _pause(action);
  }

  /// @inheritdoc PausableVault
  function unpause(VaultActions action)
    external
    virtual
    override
    hasRole(msg.sender, UNPAUSER_ROLE)
  {
    _unpause(action);
  }

  /**
   * @dev Sets the providers of this vault.
   * Requirements:
   * - Must be implemented at {BorrowingVault} or {YieldVault} level.
   * - Must infinite approve erc20 transfers of `asset` or `debtAsset` accordingly.
   * - Must emit a ProvidersChanged event.
   *
   * @param providers array of addresses
   */
  function _setProviders(ILendingProvider[] memory providers) internal virtual;

  /**
   * @dev Sets the `activeProvider` of this vault.
   * Requirements:
   * - Must emit an ActiveProviderChanged event.
   *
   * @param activeProvider_ address to be set
   */
  function _setActiveProvider(ILendingProvider activeProvider_) internal {
    // @dev skip validity check when setting it for the 1st time
    if (!_isValidProvider(address(activeProvider_)) && address(activeProvider) != address(0)) {
      revert BaseVault__setter_invalidInput();
    }
    activeProvider = activeProvider_;
    emit ActiveProviderChanged(activeProvider_);
  }

  /**
   * @dev Returns true if `provider` is in `_providers` array.
   *
   * @param provider address
   */
  function _isValidProvider(address provider) internal view returns (bool check) {
    uint256 len = _providers.length;
    for (uint256 i = 0; i < len;) {
      if (provider == address(_providers[i])) {
        check = true;
        break;
      }
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Check rebalance fee is within 10 basis points.
   * Requirements:
   * - Must be equal to or less than %0.10 (max 10 basis points) of `amount`.
   *
   * @param fee amount to be checked
   * @param amount being rebalanced to check against
   */
  function _checkRebalanceFee(uint256 fee, uint256 amount) internal pure {
    uint256 reasonableFee = (amount * 10) / 10000;
    if (fee > reasonableFee) {
      revert BaseVault__checkRebalanceFee_excessFee();
    }
  }
}