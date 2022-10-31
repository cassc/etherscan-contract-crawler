// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IStargateEthVault} from "./interfaces/IStargateEthVault.sol";
import {IYoSifuStargateVault} from "./interfaces/IYoSifuStargateVault.sol";
import {IStargateRouter} from "./interfaces/IStargateRouter.sol";
import {IStargatePool} from "./interfaces/IStargatePool.sol";

import {Owned} from "solmate/src/auth/Owned.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";

/// @notice Allows to deposit and underlying token directly to vault
contract YoSifuStargateVaultWrapper is Owned {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice Address of the Stargate ETH Wrapped
    IStargateEthVault public immutable SGETH;

    /// @notice Address of the Startgate Router
    IStargateRouter public immutable stargateRouter;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error YoSifuStargateVaultWrapper__InsufficientOut();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the SGETH, Stargate Router and Owner address of this wrapper
    /// @param _SGETH Address of the Stargate ETH wrapper
    /// @param _stargateRouter Address of the Stargate Router
    /// @param _owner Address of the owner of this vault wrapper
    constructor(
        address _SGETH,
        address _stargateRouter,
        address _owner
    ) Owned(_owner) {
        SGETH = IStargateEthVault(_SGETH);
        stargateRouter = IStargateRouter(_stargateRouter);
    }

    /*//////////////////////////////////////////////////////////////
                    VAULT DEPOSIT AND WITHDRAW
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows you to deposit the asset token to the vault
    /// @param vault Address of the vault
    /// @param minOut The minimum vault share to be received
    /// @param assets Amount of assets to be deposited
    /// @param receiver Address of the vault shares receiver
    /// @return shares Returns Share in the Vault
    function depositToVault(
        IYoSifuStargateVault vault,
        uint256 minOut,
        uint256 assets,
        address receiver
    ) external returns (uint256 shares) {
        ERC20 asset = ERC20(vault.asset());

        asset.safeTransferFrom(msg.sender, address(this), assets);

        shares = vault.deposit(assets, receiver);

        if (shares < minOut)
            revert YoSifuStargateVaultWrapper__InsufficientOut();
    }

    /// @notice Allows you to withdraw the asset token from the vault
    /// @param vault Address of the vault
    /// @param minOut The minimum asssets to be received
    /// @param shares Amount of shares to be withdrawn
    /// @param receiver Address of the assets receiver
    /// @return assets Returns Asssets in the Vault
    function withdrawFromVault(
        IYoSifuStargateVault vault,
        uint256 minOut,
        uint256 shares,
        address receiver
    ) external returns (uint256 assets) {
        assets = vault.redeem(shares, address(this), receiver);
        if (assets < minOut)
            revert YoSifuStargateVaultWrapper__InsufficientOut();
    }

    /*//////////////////////////////////////////////////////////////
                    WRAPPER DEPOSIT AND WITHDRAW
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows you to deposit the underlying token directly to the vault
    /// @dev Make sure that you calculate the minOut from the before, the vault can
    /// send lesser share, than expected. If you need to deposit Stargate Pool tokens,
    /// use the vault directly.
    /// @param vault Address of the vault
    /// @param minOut The minimum vault share to be received
    /// @param assets Amount of assets to be deposited
    /// @param receiver Address of the vault shares receiver
    /// @return sharesVault Returns Share in the Vault
    /// @return sharesPool Returns Share in the Stargate Pool
    function depositUnderlyingToVault(
        IYoSifuStargateVault vault,
        uint256 minOut,
        uint256 assets,
        address receiver
    ) external payable returns (uint256 sharesVault, uint256 sharesPool) {
        ERC20 underlyingAsset = ERC20(vault.underlyingAsset());
        ERC20 asset = ERC20(vault.asset());

        uint256 poolId = vault.poolId();

        if (address(underlyingAsset) == address(SGETH)) {
            SGETH.deposit{value: assets}();
        } else {
            underlyingAsset.safeTransferFrom(msg.sender, address(this), assets);
        }

        stargateRouter.addLiquidity(poolId, assets, address(this));
        sharesPool = asset.balanceOf(address(this));
        sharesVault = vault.deposit(sharesPool, receiver);

        if (sharesVault < minOut)
            revert YoSifuStargateVaultWrapper__InsufficientOut();
    }

    /// @notice Allows you to withdraw the underlying token directly from the vault
    /// @dev Make sure that you calculate the minOut from the before, the vault can
    /// send lesser asset, than expected, due to insufficient liquidity at Stargate
    /// If you need to withdraw Stargate Pool tokens, use the vault directly
    /// @param vault Address of the vault
    /// @param minOut The minimum asssets to be received
    /// @param shares Amount of shares to be withdrawn
    /// @param receiver Address of the assets receiver
    /// @return assetsVault Returns Asssets in the Vault
    /// @return assetsPool Returns Assets in the Stargate Pool
    function withdrawUnderlyingFromVault(
        IYoSifuStargateVault vault,
        uint256 minOut,
        uint256 shares,
        address receiver
    ) external returns (uint256 assetsVault, uint256 assetsPool) {
        ERC20 underlyingAsset = ERC20(vault.underlyingAsset());
        uint256 poolId = vault.poolId();

        assetsVault = vault.redeem(shares, address(this), msg.sender);

        stargateRouter.instantRedeemLocal(
            uint16(poolId),
            assetsVault,
            address(this)
        );

        if (address(underlyingAsset) == address(SGETH)) {
            assetsPool = address(this).balance;
            SafeTransferLib.safeTransferETH(receiver, assetsPool);
        } else {
            assetsPool = underlyingAsset.balanceOf(address(this));
            underlyingAsset.safeTransfer(receiver, assetsPool);
        }

        if (assetsPool < minOut)
            revert YoSifuStargateVaultWrapper__InsufficientOut();
    }

    /*//////////////////////////////////////////////////////////////
                          WRAPPER PREVIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice Preview of the deposit of the vault asset
    /// @param vault Address of the vault
    /// @param assets Amount of assets to be deposited
    /// @return shares Returns Share in the vault
    function previewDeposit(IYoSifuStargateVault vault, uint256 assets)
        public
        view
        returns (uint256 shares)
    {
        shares = vault.previewDeposit(assets);
    }

    /// @notice Preview of the deposit of the underlying to vault
    /// @param vault Address of the vault
    /// @param assets Amount of assets to be deposited
    /// @return sharesVault Returns Share in the Vault
    /// @return sharesPool Returns Share in the Stargate Pool
    function previewDepositUnderlyingToVault(
        IYoSifuStargateVault vault,
        uint256 assets
    ) public view returns (uint256 sharesVault, uint256 sharesPool) {
        IStargatePool pool = IStargatePool(address(vault.asset()));

        uint256 convertRate = pool.convertRate();
        sharesPool = (assets / (convertRate)) * (convertRate);
        sharesPool -=
            ((sharesPool / convertRate) * pool.mintFeeBP()) /
            pool.BP_DENOMINATOR();

        sharesPool = (sharesPool * pool.totalSupply()) / pool.totalLiquidity();

        sharesVault = vault.previewDeposit(sharesPool);
    }

    /// @notice Preview of the withdraw of the vault asset
    /// @param vault Address of the vault
    /// @param shares Amount of shares to be withdrawn
    /// @return assets Returns Asssets in the Vault
    function previewWithdraw(IYoSifuStargateVault vault, uint256 shares)
        public
        view
        returns (uint256 assets)
    {
        assets = vault.previewRedeem(shares);
    }

    /// @notice Preview of the withdraw of the vault asset to underlying
    /// @param vault Address of the vault
    /// @param shares Amount of shares to be withdrawn
    /// @return assetsVault Returns Asssets in the Vault
    /// @return assetsPool Returns Assets in the Stargate Pool
    function previewWithdrawUnderlyingFromVault(
        IYoSifuStargateVault vault,
        uint256 shares
    ) public view returns (uint256 assetsVault, uint256 assetsPool) {
        IStargatePool pool = IStargatePool(address(vault.asset()));

        assetsVault = vault.previewRedeem(shares);

        assetsPool = assetsVault;

        uint256 convertRate = pool.convertRate();
        uint256 _deltaCredit = pool.deltaCredit(); // sload optimization.
        uint256 _capAmountLP = (_deltaCredit * pool.totalSupply()) /
            pool.totalLiquidity();

        if (assetsPool > _capAmountLP) assetsPool = _capAmountLP;

        assetsPool =
            ((assetsPool * pool.totalLiquidity()) / pool.totalSupply()) *
            convertRate;
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Approves the wrapper to vault and the router
    /// @dev Only the owner of this wrapper can call this function
    /// @param vaults Addresses of the vaults to approve
    function approveToVault(address[] calldata vaults) external onlyOwner {
        for (uint256 i; i < vaults.length; i++) {
            ERC20(IYoSifuStargateVault(vaults[i]).asset()).safeApprove(
                vaults[i],
                type(uint256).max
            );
            ERC20(IYoSifuStargateVault(vaults[i]).underlyingAsset())
                .safeApprove(address(stargateRouter), type(uint256).max);
        }
    }

    receive() external payable {}
}