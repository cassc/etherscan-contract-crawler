// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IERC4626Vault } from "../interfaces/IERC4626Vault.sol";
import { VaultManagerRole } from "../shared/VaultManagerRole.sol";
import { InitializableToken } from "../tokens/InitializableToken.sol";

/**
 * @title   Abstract ERC-4626 Vault.
 * @author  mStable
 * @notice  See the following for the full EIP-4626 specification https://eips.ethereum.org/EIPS/eip-4626.
 * Connects to the mStable Nexus to get modules and roles like the `Governor` and `Liquidator`.
 * Creates the `VaultManager` role.
 *
 * The `totalAssets`, `_beforeWithdrawHook` and `_afterDepositHook` functions need to be implemented.
 *
 * @dev     VERSION: 1.0
 *          DATE:    2022-02-10
 *
 * The constructor of implementing contracts need to call the following:
 * - VaultManagerRole(_nexus)
 * - AbstractVault(_assetArg)
 *
 * The `initialize` function of implementing contracts need to call the following:
 * - InitializableToken._initialize(_name, _symbol, decimals)
 * - VaultManagerRole._initialize(_vaultManager)
 */
abstract contract AbstractVault is IERC4626Vault, InitializableToken, VaultManagerRole {
    using SafeERC20 for IERC20;

    /// @notice Address of the vault's underlying asset token.
    IERC20 internal immutable _asset;

    /**
     * @param _assetArg         Address of the vault's underlying asset.
     */
    constructor(address _assetArg) {
        require(_assetArg != address(0), "Asset is zero");
        _asset = IERC20(_assetArg);
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/MINT
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver)
        external
        virtual
        override
        whenNotPaused
        returns (uint256 shares)
    {
        shares = _deposit(assets, receiver);
    }

    function _deposit(uint256 assets, address receiver) internal virtual returns (uint256 shares) {
        shares = _previewDeposit(assets);

        _transferAndMint(assets, shares, receiver, true);
    }

    function previewDeposit(uint256 assets) external view override returns (uint256 shares) {
        shares = _previewDeposit(assets);
    }

    function _previewDeposit(uint256 assets) internal view virtual returns (uint256 shares) {
        shares = _convertToShares(assets);
    }

    function maxDeposit(address caller) external view override returns (uint256 maxAssets) {
        maxAssets = _maxDeposit(caller);
    }

    function _maxDeposit(address) internal view virtual returns (uint256 maxAssets) {
        if (paused()) {
            return 0;
        }

        maxAssets = type(uint256).max;
    }

    function mint(uint256 shares, address receiver)
        external
        virtual
        override
        whenNotPaused
        returns (uint256 assets)
    {
        assets = _mint(shares, receiver);
    }

    function _mint(uint256 shares, address receiver) internal virtual returns (uint256 assets) {
        assets = _previewMint(shares);
        _transferAndMint(assets, shares, receiver, false);
    }

    function previewMint(uint256 shares) external view override returns (uint256 assets) {
        assets = _previewMint(shares);
    }

    function _previewMint(uint256 shares) internal view virtual returns (uint256 assets) {
        assets = _convertToAssets(shares);
    }

    function maxMint(address owner) external view override returns (uint256 maxShares) {
        maxShares = _maxMint(owner);
    }

    function _maxMint(address) internal view virtual returns (uint256 maxShares) {
        if (paused()) {
            return 0;
        }

        maxShares = type(uint256).max;
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL DEPSOIT/MINT
    //////////////////////////////////////////////////////////////*/

    function _transferAndMint(
        uint256 assets,
        uint256 shares,
        address receiver,
        bool fromDeposit
    ) internal virtual {
        _asset.safeTransferFrom(msg.sender, address(this), assets);

        _afterDepositHook(assets, shares, receiver, fromDeposit);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /*///////////////////////////////////////////////////////////////
                        WITHDRAW/REDEEM
    //////////////////////////////////////////////////////////////*/

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external virtual override whenNotPaused returns (uint256 shares) {
        shares = _withdraw(assets, receiver, owner);
    }

    function _withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) internal virtual returns (uint256 shares) {
        shares = _previewWithdraw(assets);

        _burnTransfer(assets, shares, receiver, owner, false);
    }

    function previewWithdraw(uint256 assets) external view override returns (uint256 shares) {
        shares = _previewWithdraw(assets);
    }

    function _previewWithdraw(uint256 assets) internal view virtual returns (uint256 shares) {
        shares = _convertToShares(assets);
    }

    function maxWithdraw(address owner) external view override returns (uint256 maxAssets) {
        maxAssets = _maxWithdraw(owner);
    }

    function _maxWithdraw(address owner) internal view virtual returns (uint256 maxAssets) {
        if (paused()) {
            return 0;
        }

        maxAssets = _previewRedeem(balanceOf(owner));
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external virtual override whenNotPaused returns (uint256 assets) {
        assets = _redeem(shares, receiver, owner);
    }

    function _redeem(
        uint256 shares,
        address receiver,
        address owner
    ) internal virtual returns (uint256 assets) {
        assets = _previewRedeem(shares);
        _burnTransfer(assets, shares, receiver, owner, true);
    }

    function previewRedeem(uint256 shares) external view override returns (uint256 assets) {
        assets = _previewRedeem(shares);
    }

    function _previewRedeem(uint256 shares) internal view virtual returns (uint256 assets) {
        assets = _convertToAssets(shares);
    }

    function maxRedeem(address owner) external view override returns (uint256 maxShares) {
        maxShares = _maxRedeem(owner);
    }

    function _maxRedeem(address owner) internal view virtual returns (uint256 maxShares) {
        if (paused()) {
            return 0;
        }
        
        maxShares = balanceOf(owner);
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL WITHDRAW/REDEEM
    //////////////////////////////////////////////////////////////*/

    function _burnTransfer(
        uint256 assets,
        uint256 shares,
        address receiver,
        address owner,
        bool fromRedeem
    ) internal virtual {
        // If caller is not the owner of the shares
        uint256 allowed = allowance(owner, msg.sender);
        if (msg.sender != owner && allowed != type(uint256).max) {
            require(shares <= allowed, "Amount exceeds allowance");
            _approve(owner, msg.sender, allowed - shares);
        }
        _beforeWithdrawHook(assets, shares, owner, fromRedeem);

        _burn(owner, shares);

        _asset.safeTransfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /*///////////////////////////////////////////////////////////////
                            EXTENRAL ASSETS
    //////////////////////////////////////////////////////////////*/

    function asset() external view virtual override returns (address assetTokenAddress) {
        assetTokenAddress = address(_asset);
    }

    /**
     * @notice It should include any compounding that occurs from yield. It must be inclusive of any fees that are charged against assets in the Vault. It must not revert.
     *
     * Returns the total amount of the underlying asset that is “managed” by vault.
     */
    function totalAssets() public view virtual override returns (uint256 totalManagedAssets);

    /*///////////////////////////////////////////////////////////////
                            CONVERTIONS
    //////////////////////////////////////////////////////////////*/

    function convertToAssets(uint256 shares)
        external
        view
        virtual
        override
        returns (uint256 assets)
    {
        assets = _convertToAssets(shares);
    }

    function _convertToAssets(uint256 shares) internal view virtual returns (uint256 assets) {
        uint256 totalShares = totalSupply();

        if (totalShares == 0) {
            assets = shares; // 1:1 value of shares and assets
        } else {
            assets = (shares * totalAssets()) / totalShares;
        }
    }

    function convertToShares(uint256 assets)
        external
        view
        virtual
        override
        returns (uint256 shares)
    {
        shares = _convertToShares(assets);
    }

    function _convertToShares(uint256 assets) internal view virtual returns (uint256 shares) {
        uint256 totalShares = totalSupply();

        if (totalShares == 0) {
            shares = assets; // 1:1 value of shares and assets
        } else {
            shares = (assets * totalShares) / totalAssets();
        }
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * Called be the `deposit` and `mint` functions after the assets have been transferred into the vault
     * but before shares are minted.
     * Typically, the hook implementation deposits the assets into the underlying vaults or platforms.
     *
     * @dev the shares returned from `totalSupply` and `balanceOf` have not yet been updated with the minted shares.
     * The assets returned from `totalAssets` and `assetsOf` are typically updated as part of the `_afterDepositHook` hook but it depends on the implementation.
     *
     * If an vault is implementing multiple vault capabilities, the `_afterDepositHook` function that updates the assets amounts should be executed last.
     *
     * @param assets the amount of underlying assets to be transferred to the vault.
     * @param shares the amount of vault shares to be minted.
     * @param receiver the account that is receiving the minted shares.
     */
    function _afterDepositHook(
        uint256 assets,
        uint256 shares,
        address receiver,
        bool fromDeposit
    ) internal virtual {}

    /**
     * Called be the `withdraw` and `redeem` functions before
     * the assets have been transferred from the vault to the receiver
     * and before the owner's shares are burnt.
     * Typically, the hook implementation withdraws the assets from the underlying vaults or platforms.
     *
     * @param assets the amount of underlying assets to be withdrawn from the vault.
     * @param shares the amount of vault shares to be burnt.
     * @param owner the account that owns the shares that are being burnt.
     */
    function _beforeWithdrawHook(
        uint256 assets,
        uint256 shares,
        address owner,
        bool fromRedeem
    ) internal virtual {}
}