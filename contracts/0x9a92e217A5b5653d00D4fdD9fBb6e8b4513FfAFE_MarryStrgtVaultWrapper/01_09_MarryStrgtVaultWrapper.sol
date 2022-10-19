// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IStrgtEthVault} from "./interfaces/IStrgtEthVault.sol";
import {IMarryStrgtVault} from "./interfaces/IMarryStrgtVault.sol";
import {IStrgtRouter} from "./interfaces/IStrgtRouter.sol";
import {IStrgtPool} from "./interfaces/IStrgtPool.sol";

import {Owned} from "solmate/src/auth/Owned.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";

/// @notice Allows to deposit and underlying token directly to vault
contract MarryStrgtVaultWrapper is Owned {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice Address of the Strgt ETH Wrapped
    IStrgtEthVault public immutable SGETH;

    /// @notice Address of the Startgate Router
    IStrgtRouter public immutable strgtRouter;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error MarryStrgtVaultWrapper__InsufficientOut();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the SGETH, Strgt Router and Owner address of this wrapper
    /// @param _SGETH Address of the Strgt ETH wrapper
    /// @param _strgtRouter Address of the Strgt Router
    /// @param _owner Address of the owner of this vault wrapper
    constructor(
        address _SGETH,
        address _strgtRouter,
        address _owner
    ) Owned(_owner) {
        SGETH = IStrgtEthVault(_SGETH);
        strgtRouter = IStrgtRouter(_strgtRouter);
    }

    /*//////////////////////////////////////////////////////////////
                          Vault Deposit & Withdraw LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows you to deposit the underlying token directly to the vault
    /// @dev Make sure that you calculate the minOut from the before, the vault can
    /// send lesser share, than expected. If you need to deposit Strgt Pool tokens,
    /// use the vault directly.
    /// @param vault Address of the vault
    /// @param minOut The minimum vault share to be received
    /// @param assets Amount of assets to be deposited
    /// @param receiver Address of the vault shares receiver
    /// @return sharesVault Returns Share in the Vault
    /// @return sharesPool Returns Share in the Strgt Pool
    function depositUnderlyingToVault(
        IMarryStrgtVault vault,
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

        strgtRouter.addLiquidity(poolId, assets, address(this));
        sharesPool = asset.balanceOf(address(this));
        sharesVault = vault.deposit(sharesPool, receiver);

        if (sharesVault < minOut)
            revert MarryStrgtVaultWrapper__InsufficientOut();
    }

    /// @notice Allows you to withdraw the underlying token directly to the vault
    /// @dev Make sure that you calculate the minOut from the before, the vault can
    /// send lesser asset, than expected, due to insufficient liquidity at Strgt
    /// If you need to withdraw Strgt Pool tokens, use the vault directly
    /// @param vault Address of the vault
    /// @param minOut The minimum asssets to be received
    /// @param shares Amount of shares to be withdrawn
    /// @param receiver Address of the assets receiver
    /// @return assetsVault Returns Asssets in the Vault
    /// @return assetsPool Returns Assets in the Strgt Pool
    function withdrawUnderlyingFromVault(
        IMarryStrgtVault vault,
        uint256 minOut,
        uint256 shares,
        address receiver
    ) external returns (uint256 assetsVault, uint256 assetsPool) {
        ERC20 underlyingAsset = ERC20(vault.underlyingAsset());
        uint256 poolId = vault.poolId();

        assetsVault = vault.redeem(shares, address(this), msg.sender);

        strgtRouter.instantRedeemLocal(
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
            revert MarryStrgtVaultWrapper__InsufficientOut();
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Approves the wrapper to vault and the router
    /// @dev Only the owner of this wrapper can call this function
    /// @param vaults Addresses of the vaults to approve
    function approveToVault(address[] calldata vaults) external onlyOwner {
        for (uint256 i; i < vaults.length; i++) {
            ERC20(IMarryStrgtVault(vaults[i]).asset()).safeApprove(
                vaults[i],
                type(uint256).max
            );
            ERC20(IMarryStrgtVault(vaults[i]).underlyingAsset())
                .safeApprove(address(strgtRouter), type(uint256).max);
        }
    }

    receive() external payable {}
}