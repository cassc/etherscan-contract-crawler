// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {Clone} from "create2-clones-with-immutable-args/Clone.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC20Cloned} from "gpl/ERC20-Cloned.sol";
import {IERC4626} from "core/interfaces/IERC4626.sol";

abstract contract ERC4626Cloned is IERC4626, ERC20Cloned {
  using SafeTransferLib for ERC20;
  using FixedPointMathLib for uint256;

  function minDepositAmount() public view virtual returns (uint256);

  function asset() public view virtual returns (address);

  function deposit(
    uint256 assets,
    address receiver
  ) public virtual returns (uint256 shares) {
    // Check for rounding error since we round down in previewDeposit.
    require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

    require(shares > minDepositAmount(), "VALUE_TOO_SMALL");
    // Need to transfer before minting or ERC777s could reenter.
    ERC20(asset()).safeTransferFrom(msg.sender, address(this), assets);

    _mint(receiver, shares);

    emit Deposit(msg.sender, receiver, assets, shares);

    afterDeposit(assets, shares);
  }

  function mint(
    uint256 shares,
    address receiver
  ) public virtual returns (uint256 assets) {
    assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.
    require(assets > minDepositAmount(), "VALUE_TOO_SMALL");
    // Need to transfer before minting or ERC777s could reenter.
    ERC20(asset()).safeTransferFrom(msg.sender, address(this), assets);

    _mint(receiver, shares);

    emit Deposit(msg.sender, receiver, assets, shares);

    afterDeposit(assets, shares);
  }

  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) public virtual returns (uint256 shares) {
    shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

    ERC20Data storage s = _loadERC20Slot();
    if (msg.sender != owner) {
      uint256 allowed = s.allowance[owner][msg.sender]; // Saves gas for limited approvals.

      if (allowed != type(uint256).max) {
        s.allowance[owner][msg.sender] = allowed - shares;
      }
    }

    beforeWithdraw(assets, shares);

    _burn(owner, shares);

    emit Withdraw(msg.sender, receiver, owner, assets, shares);

    ERC20(asset()).safeTransfer(receiver, assets);
  }

  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) public virtual returns (uint256 assets) {
    ERC20Data storage s = _loadERC20Slot();
    if (msg.sender != owner) {
      uint256 allowed = s.allowance[owner][msg.sender]; // Saves gas for limited approvals.

      if (allowed != type(uint256).max) {
        s.allowance[owner][msg.sender] = allowed - shares;
      }
    }

    // Check for rounding error since we round down in previewRedeem.
    require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

    beforeWithdraw(assets, shares);

    _burn(owner, shares);

    emit Withdraw(msg.sender, receiver, owner, assets, shares);

    ERC20(asset()).safeTransfer(receiver, assets);
  }

  function totalAssets() public view virtual returns (uint256);

  function convertToShares(
    uint256 assets
  ) public view virtual returns (uint256) {
    uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

    return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
  }

  function convertToAssets(
    uint256 shares
  ) public view virtual returns (uint256) {
    uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

    return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
  }

  function previewDeposit(
    uint256 assets
  ) public view virtual returns (uint256) {
    return convertToShares(assets);
  }

  function previewMint(uint256 shares) public view virtual returns (uint256) {
    uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

    return supply == 0 ? 10e18 : shares.mulDivUp(totalAssets(), supply);
  }

  function previewWithdraw(
    uint256 assets
  ) public view virtual returns (uint256) {
    uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

    return supply == 0 ? 10e18 : assets.mulDivUp(supply, totalAssets());
  }

  function previewRedeem(uint256 shares) public view virtual returns (uint256) {
    return convertToAssets(shares);
  }

  function maxDeposit(address) public view virtual returns (uint256) {
    return type(uint256).max;
  }

  function maxMint(address) public view virtual returns (uint256) {
    return type(uint256).max;
  }

  function maxWithdraw(address owner) public view virtual returns (uint256) {
    ERC20Data storage s = _loadERC20Slot();
    return convertToAssets(s.balanceOf[owner]);
  }

  function maxRedeem(address owner) public view virtual returns (uint256) {
    ERC20Data storage s = _loadERC20Slot();
    return s.balanceOf[owner];
  }

  function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

  function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}