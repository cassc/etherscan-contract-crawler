// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { ERC4626 } from "solmate/src/mixins/ERC4626.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "solmate/src/utils/FixedPointMathLib.sol";

import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";

import { AutoRoller } from "./AutoRoller.sol";

interface AdapterLike {
    function scale() external view returns (uint256);
    function underlying() external view returns (address);
    function wrapUnderlying(uint256) external returns (uint256);
    function unwrapTarget(uint256) external returns (uint256);
}

// Inspired by https://github.com/fei-protocol/ERC4626/blob/main/src/ERC4626Router.sol
contract RollerPeriphery is Trust {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /// @notice thrown when amount of assets received is below the min set by caller.
    error MinAssetError();

    /// @notice thrown when amount of underlying received is below the min set by caller.
    error MinUnderlyingError();

    /// @notice thrown when amount of shares received is below the min set by caller.
    error MinSharesError();

    /// @notice thrown when amount of assets received is above the max set by caller.
    error MaxAssetError();

    /// @notice thrown when amount of underlying received is above the max set by caller.
    error MaxUnderlyingError();

    /// @notice thrown when amount of shares received is above the max set by caller.
    error MaxSharesError();

    /// @notice thrown when amount of assets or excess received is below the max set by caller.
    error MinAssetsOrExcessError();

    constructor() Trust(msg.sender) {}

    /// @notice Redeem vault shares with slippage protection 
    /// @param roller ERC4626 vault
    /// @param shares Number of shares to redeem
    /// @param receiver Destination address for the returned assets
    /// @param minAmountOut Minimum amount of assets returned
    /// @return assets Amount of asset redeemable by the given number of shares
    function redeem(AutoRoller roller, uint256 shares, address receiver, uint256 minAmountOut) external returns (uint256 assets) {
        if ((assets = roller.redeem(shares, receiver, msg.sender)) < minAmountOut) {
            revert MinAssetError();
        }
    }

    /// @notice Redeem vault shares and convert to underlying, with slippage protection
    /// @param roller AutoRoller vault
    /// @param shares Number of shares to redeem
    /// @param receiver Destination address for the returned assets
    /// @param minAmountOut Minimum amount of underlying returned
    /// @return underlyingOut Amount of underlying converted from Target redeemable by the given number of shares
    function redeemForUnderlying(AutoRoller roller, uint256 shares, address receiver, uint256 minAmountOut) external returns (uint256 underlyingOut) {
        AdapterLike adapter = AdapterLike(address(roller.adapter()));

        if ((underlyingOut = adapter.unwrapTarget(roller.redeem(shares, address(this), msg.sender))) < minAmountOut) {
            revert MinUnderlyingError();
        }

        ERC20(adapter.underlying()).safeTransfer(receiver, underlyingOut);
    }

    /// @notice Withdraw asset from vault with slippage protection
    /// @param roller AutoRoller vault
    /// @param assets Amount of asset requested for withdrawal
    /// @param receiver Destination address for the returned assets
    /// @param maxSharesOut Maximum amount of shares burned
    /// @return shares Number of shares to redeem
    function withdraw(AutoRoller roller, uint256 assets, address receiver, uint256 maxSharesOut) external returns (uint256 shares) {
        if ((shares = roller.withdraw(assets, receiver, msg.sender)) > maxSharesOut) {
            revert MaxSharesError();
        }
    }

    /// @notice Withdraw asset from vault and convert to underlying, with slippage protection
    /// @param roller AutoRoller vault
    /// @param underlyingOut Amount of underlying requested for withdrawal
    /// @param receiver Destination address for the returned underlying
    /// @param maxSharesOut Maximum amount of shared burned
    /// @return shares Number of shares to redeem
    function withdrawUnderlying(AutoRoller roller, uint256 underlyingOut, address receiver, uint256 maxSharesOut) external returns (uint256 shares) {
        AdapterLike adapter = AdapterLike(address(roller.adapter()));

        // asset converted from underlying (round down)
        uint256 assetOut = underlyingOut.divWadDown(adapter.scale());

        if ((shares = roller.withdraw(assetOut, address(this), msg.sender)) > maxSharesOut) {
            revert MaxSharesError();
        }

        uint256 underlyingOut = adapter.unwrapTarget(roller.asset().balanceOf(address(this)));
        ERC20(adapter.underlying()).safeTransfer(receiver, underlyingOut);
    }

    /// @notice Mint vault shares with slippage protection
    /// @param roller AutoRoller vault
    /// @param shares Number of shares to mint
    /// @param receiver Destination address for the returned shares
    /// @param maxAmountIn Maximum amount of assets pulled from msg.sender
    /// @return assets Amount of asset pulled from msg.sender and used to mint vault shares
    function mint(AutoRoller roller, uint256 shares, address receiver, uint256 maxAmountIn) external returns (uint256 assets) {
        ERC20(roller.asset()).safeTransferFrom(msg.sender, address(this), roller.previewMint(shares));

        if ((assets = roller.mint(shares, receiver)) > maxAmountIn) {
            revert MaxAssetError();
        }
    }

    /// @notice Convert underlying to asset and mint vault shares with slippage protection
    /// @param roller AutoRoller vault
    /// @param shares Number of shares to mint
    /// @param receiver Destination address for the returned shares
    /// @param maxAmountIn Maximum amount of underlying pulled from msg.sender
    /// @return underlyingIn Amount of underlying pulled from msg.sender and used to mint vault shares
    function mintFromUnderlying(AutoRoller roller, uint256 shares, address receiver, uint256 maxAmountIn) external returns (uint256 underlyingIn) {
        AdapterLike adapter = AdapterLike(address(roller.adapter()));

        ERC20(adapter.underlying()).safeTransferFrom(
            msg.sender,
            address(this),
            underlyingIn = roller.previewMint(shares).mulWadUp(adapter.scale()) // underlying converted from asset (round up)
        );

        adapter.wrapUnderlying(underlyingIn); // convert underlying to asset

        uint256 assetIn = roller.mint(shares, receiver);
        if ((underlyingIn = assetIn.mulWadDown(adapter.scale())) > maxAmountIn) {
            revert MaxUnderlyingError();
        }
    }

    /// @notice Deposit asset into vault with slippage protection
    /// @param roller AutoRoller vault
    /// @param assets Amount of asset pulled from msg.sender and used to mint vault shares
    /// @param receiver Destination address for the returned shares
    /// @param minSharesOut Minimum amount of returned shares
    /// @return shares Number of shares minted by the vault and returned to msg.sender
    function deposit(AutoRoller roller, uint256 assets, address receiver, uint256 minSharesOut) external returns (uint256 shares) {
        ERC20(roller.asset()).safeTransferFrom(msg.sender, address(this), assets);

        if ((shares = roller.deposit(assets, receiver)) < minSharesOut) {
            revert MinSharesError();
        }
    }

    /// @notice Convert underlying to asset and deposit into vault with slippage protection
    /// @param roller AutoRoller vault
    /// @param underlyingIn Amount of underlying pulled from msg.sender and used to mint vault shares
    /// @param receiver Destination address for the returned shares
    /// @param minSharesOut Minimum amount of returned shares
    /// @return shares Number of shares minted by the vault and returned to msg.sender
    function depositUnderlying(AutoRoller roller, uint256 underlyingIn, address receiver, uint256 minSharesOut) external returns (uint256 shares) {
        AdapterLike adapter = AdapterLike(address(roller.adapter()));

        ERC20(adapter.underlying()).safeTransferFrom(msg.sender, address(this), underlyingIn);

        if ((shares = roller.deposit(adapter.wrapUnderlying(underlyingIn), receiver)) < minSharesOut) {
            revert MinSharesError();
        }
    }

    /// @notice Quick exit into the constituent assets with slippage protection
    /// @param roller AutoRoller vault.
    /// @param shares Number of shares to eject with.
    /// @param receiver Destination address for the constituent assets.
    /// @param minAssetsOut Minimum amount of assets returned
    /// @param minExcessOut Minimum excess PT/YT returned
    /// @return assets Amount of asset redeemable by the given number of shares.
    /// @return excessBal Amount of excess PT or YT redeemable by the given number of shares.
    /// @return isExcessPTs Whether the excess token is a YT or PT.
    function eject(AutoRoller roller, uint256 shares, address receiver, uint256 minAssetsOut, uint256 minExcessOut)
        external returns (uint256 assets, uint256 excessBal, bool isExcessPTs)
    {
        (assets, excessBal, isExcessPTs) = roller.eject(shares, receiver, msg.sender);

        if (assets < minAssetsOut || excessBal < minExcessOut) {
            revert MinAssetsOrExcessError();
        }
    }

    function approve(ERC20 token, address to) public payable requiresTrust {
        token.safeApprove(to, type(uint256).max);
    }
}