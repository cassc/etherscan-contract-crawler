// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title YieldVaultUpgradeable
 *
 * @author Fujidao Labs
 *
 * @notice Upgradeable implementation of {YieldVault.sol}.
 */

import {
  IERC20Upgradeable as IERC20,
  IERC20MetadataUpgradeable as IERC20Metadata
} from
  "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {IVaultUpgradeable as IVault} from "../../interfaces/IVaultUpgradeable.sol";
import {ILendingProvider} from "../../interfaces/ILendingProvider.sol";
import {SafeERC20Upgradeable as SafeERC20} from
  "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {BaseVaultUpgradeable} from "../../abstracts/BaseVaultUpgradeable.sol";

contract YieldVaultUpgradeable is BaseVaultUpgradeable {
  using SafeERC20 for IERC20Metadata;

  /// @dev Custom Errors
  error YieldVault__notApplicable();
  error YieldVault__rebalance_invalidProvider();

  /**
   * @notice Initialize a new {YieldVaultUpgradeable}.
   *
   * @param asset_ this vault will handle as main asset (collateral)
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
    address chief_,
    string memory name_,
    string memory symbol_,
    ILendingProvider[] memory providers_
  )
    public
    initializer
  {
    __BaseVault_initialize(asset_, chief_, name_, symbol_);
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
    return convertToAssets(balanceOf(owner));
  }

  /// @inheritdoc BaseVaultUpgradeable
  function maxRedeem(address owner) public view override returns (uint256) {
    if (paused(VaultActions.Withdraw)) {
      return 0;
    }
    return balanceOf(owner);
  }

  /*///////////////////////////////
      Debt management overrides 
  ///////////////////////////////*/

  /// @inheritdoc BaseVaultUpgradeable
  function debtDecimals() public pure override returns (uint8) {}

  /// @inheritdoc BaseVaultUpgradeable
  function debtAsset() public pure override returns (address) {}

  /// @inheritdoc BaseVaultUpgradeable
  function balanceOfDebt(address) public pure override returns (uint256) {}

  /// @inheritdoc BaseVaultUpgradeable
  function balanceOfDebtShares(address owner) public pure override returns (uint256 debtShares) {}

  /// @inheritdoc BaseVaultUpgradeable
  function totalDebt() public pure override returns (uint256) {}

  /// @inheritdoc BaseVaultUpgradeable
  function convertDebtToShares(uint256) public pure override returns (uint256) {}

  /// @inheritdoc BaseVaultUpgradeable
  function convertToDebt(uint256) public pure override returns (uint256) {}

  /// @inheritdoc BaseVaultUpgradeable
  function maxBorrow(address) public pure override returns (uint256) {}

  /// @inheritdoc BaseVaultUpgradeable
  function maxPayback(address) public pure override returns (uint256) {}

  /// @inheritdoc BaseVaultUpgradeable
  function maxMintDebt(address) public pure override returns (uint256) {}

  /// @inheritdoc BaseVaultUpgradeable
  function maxBurnDebt(address) public pure override returns (uint256) {}

  /// @inheritdoc BaseVaultUpgradeable
  function previewBorrow(uint256) public pure override returns (uint256) {}

  /// @inheritdoc BaseVaultUpgradeable
  function previewMintDebt(uint256) public pure override returns (uint256) {}

  /// @inheritdoc BaseVaultUpgradeable
  function previewPayback(uint256) public pure override returns (uint256) {}

  /// @inheritdoc BaseVaultUpgradeable
  function previewBurnDebt(uint256) public pure override returns (uint256) {}

  /// @inheritdoc BaseVaultUpgradeable
  function borrow(uint256, address, address) public pure override returns (uint256) {
    revert YieldVault__notApplicable();
  }

  /// @inheritdoc BaseVaultUpgradeable
  function mintDebt(uint256, address, address) public pure override returns (uint256) {
    revert YieldVault__notApplicable();
  }

  /// @inheritdoc BaseVaultUpgradeable
  function payback(uint256, address) public pure override returns (uint256) {
    revert YieldVault__notApplicable();
  }

  /// @inheritdoc BaseVaultUpgradeable
  function burnDebt(uint256, address) public pure override returns (uint256) {
    revert YieldVault__notApplicable();
  }

  /*///////////////////////
      Borrow allowances
  ///////////////////////*/

  /// @inheritdoc BaseVaultUpgradeable
  function borrowAllowance(
    address,
    address,
    address
  )
    public
    view
    virtual
    override
    returns (uint256)
  {
    revert YieldVault__notApplicable();
  }

  /// @inheritdoc BaseVaultUpgradeable
  function increaseBorrowAllowance(
    address,
    address,
    uint256
  )
    public
    virtual
    override
    returns (bool)
  {
    revert YieldVault__notApplicable();
  }

  /// @inheritdoc BaseVaultUpgradeable
  function decreaseBorrowAllowance(
    address,
    address,
    uint256
  )
    public
    virtual
    override
    returns (bool)
  {
    revert YieldVault__notApplicable();
  }

  /// @inheritdoc BaseVaultUpgradeable
  function permitBorrow(
    address,
    address,
    uint256,
    uint256,
    bytes32,
    uint8,
    bytes32,
    bytes32
  )
    public
    pure
    override
  {
    revert YieldVault__notApplicable();
  }

  /*/////////////////
      Rebalancing
  /////////////////*/

  /// @inheritdoc IVault
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
      revert YieldVault__rebalance_invalidProvider();
    }

    if (debt != 0) {
      revert YieldVault__notApplicable();
    }

    _checkRebalanceFee(fee, assets);

    _executeProviderAction(assets, "withdraw", from);
    _executeProviderAction(assets, "deposit", to);

    if (setToAsActiveProvider) {
      _setActiveProvider(to);
    }

    emit VaultRebalance(assets, 0, address(from), address(to));
    return true;
  }

  /*////////////////////
       Liquidate
  ////////////////////*/

  /// @inheritdoc IVault
  function getHealthFactor(address) public pure returns (uint256) {
    revert YieldVault__notApplicable();
  }

  /// @inheritdoc IVault
  function getLiquidationFactor(address) public pure returns (uint256) {
    revert YieldVault__notApplicable();
  }

  /// @inheritdoc IVault
  function liquidate(address, address, uint256) public pure returns (uint256) {
    revert YieldVault__notApplicable();
  }

  /*/////////////////////////
      Admin set functions
  /////////////////////////*/

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
      unchecked {
        ++i;
      }
    }
    _providers = providers;

    emit ProvidersChanged(providers);
  }
}