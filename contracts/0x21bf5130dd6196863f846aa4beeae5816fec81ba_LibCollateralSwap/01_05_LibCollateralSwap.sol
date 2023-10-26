// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.7;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IComet} from "../interfaces/IComet.sol";

/// @title LibCollateralSwap Library
/// @notice Helper functions to swap collateral assets on Compound V3.
library LibCollateralSwap {
    using SafeMath for uint256;

    error WidoRouterFailed();
    error InvalidSwapOutputToken();

    struct Collateral {
        address addr;
        uint256 amount;
    }

    struct Signatures {
        Signature allow;
        Signature revoke;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct WidoSwap {
        address router;
        address tokenManager;
        bytes callData;
    }

    /// @dev Performs supply, withdraw and swap steps to swap collaterals on the Comet contract
    /// @param borrowedAsset The address of the asset that has been borrowed.
    /// @param borrowedAmount The amount of the asset that has been borrowed.
    /// @param fee The fee associated with the borrowed asset.
    /// @param data The encoded payload containing details required for the swap.
    function performCollateralSwap(
        address borrowedAsset,
        uint256 borrowedAmount,
        uint256 fee,
        bytes memory data
    ) external {
        // decode payload
        (
        address user,
        IComet comet,
        Collateral memory existingCollateral,
        Signatures memory signatures,
        WidoSwap memory swapDetails
        ) = abi.decode(
            data,
            (address, IComet, Collateral, Signatures, WidoSwap)
        );

        // supply new collateral on behalf of user
        _supplyTo(comet, user, borrowedAsset, borrowedAmount.sub(fee));

        // withdraw existing collateral
        _withdrawFrom(comet, user, existingCollateral, signatures);

        // Store the initial balance of the borrowed asset in this contract
        uint256 borrowedAssetBalanceBeforeSwap = IERC20(borrowedAsset).balanceOf(address(this));

        // execute swap
        _swap(existingCollateral, swapDetails);

        // Ensure that the swap operation has returned the correct token by comparing the balances before and after the swap.
        // This step verifies that the swap destination token type is the same as the flash loan token type, to avoid accidentally swapping to an incorrect asset.
        if (IERC20(borrowedAsset).balanceOf(address(this)) <= borrowedAssetBalanceBeforeSwap) revert InvalidSwapOutputToken();

        // check amount of surplus collateral
        uint256 surplusAmount = IERC20(borrowedAsset).balanceOf(address(this)) - borrowedAmount - fee;

        // if positive slippage, supply extra to user
        if (surplusAmount > 0) {
            _supplyTo(comet, user, borrowedAsset, surplusAmount);
        }
    }

    /// @dev Performs the swap of the collateral on the WidoRouter
    function _swap(
        Collateral memory collateral,
        WidoSwap memory swap
    ) internal {
        // approve WidoTokenManager initial collateral to make the swap
        IERC20(collateral.addr).approve(
            swap.tokenManager,
            collateral.amount
        );

        // execute swap
        (bool success, bytes memory result) = swap.router.call(swap.callData);

        if (!success) {
            if (result.length < 68) revert WidoRouterFailed();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }

    /// @dev Supplies collateral on behalf of user
    function _supplyTo(
        IComet comet,
        address user,
        address asset,
        uint256 amount
    ) internal {
        IERC20(asset).approve(address(comet), amount);
        comet.supplyTo(user, asset, amount);
    }

    /// @dev This function withdraws the collateral from the user.
    /// It requires two consecutive EIP712 signatures to allow and revoke
    /// permissions to and from this contract.
    function _withdrawFrom(
        IComet comet,
        address user,
        Collateral memory collateral,
        Signatures memory sigs
    ) internal {
        // get current nonce
        uint256 nonce = comet.userNonce(user);
        // allow the contract
        _allowBySig(comet, user, true, nonce, sigs.allow);
        // withdraw assets
        comet.withdrawFrom(user, address(this), collateral.addr, collateral.amount);
        // increment nonce
        unchecked { nonce++; }
        // revoke permission
        _allowBySig(comet, user, false, nonce, sigs.revoke);
    }

    /// @dev Executes a single `allowBySig` operation on the Comet contract
    function _allowBySig(
        IComet comet,
        address user,
        bool allowed,
        uint256 nonce,
        Signature memory sig
    ) internal {
        comet.allowBySig(
            user,
            address(this),
            allowed,
            nonce,
            10e9,
            sig.v,
            sig.r,
            sig.s
        );
    }

}