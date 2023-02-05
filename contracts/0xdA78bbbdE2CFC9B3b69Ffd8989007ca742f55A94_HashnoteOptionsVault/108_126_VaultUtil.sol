// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { FixedPointMathLib } from "../../lib/solmate/src/utils/FixedPointMathLib.sol";
import { SafeERC20 } from "../../lib/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { Vault } from "./Vault.sol";

import { IERC20 } from "../interfaces/IERC20.sol";
import { IWhitelist } from "../interfaces/IWhitelist.sol";

import "./Errors.sol";

library VaultUtil {
    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    /**
     * @notice Transfers assets between account holder and vault
     */
    function transferAssets(
        uint256 primaryDeposit,
        Vault.Collateral[] calldata collaterals,
        uint256[] calldata roundStartingBalances,
        address recipient
    ) external returns (uint256[] memory amounts) {
        // primary asset amount used to calculating the amount of secondary assets deposted in the round
        uint256 primaryTotal = roundStartingBalances[0];

        bool isWithdraw = recipient != address(this);

        amounts = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length;) {
            uint256 balance = roundStartingBalances[i];

            if (isWithdraw) {
                amounts[i] = balance.mulDivDown(primaryDeposit, primaryTotal);
            } else {
                amounts[i] = balance.mulDivUp(primaryDeposit, primaryTotal);
            }

            if (amounts[i] != 0) {
                if (isWithdraw) {
                    IERC20(collaterals[i].addr).safeTransfer(recipient, amounts[i]);
                } else {
                    IERC20(collaterals[i].addr).safeTransferFrom(msg.sender, recipient, amounts[i]);
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Rebalances assets
     * @dev will only allow surplus assets to be exchanged
     */
    function rebalance(
        address otc,
        uint256[] calldata amounts,
        Vault.Collateral[] calldata collaterals,
        uint256[] calldata vault,
        address whitelist
    ) external {
        if (collaterals.length != amounts.length) revert VL_DifferentLengths();

        if (!IWhitelist(whitelist).isOTC(otc)) revert VL_Unauthorized();

        for (uint256 i; i < collaterals.length;) {
            if (amounts[i] != 0) {
                IERC20 asset = IERC20(collaterals[i].addr);

                uint256 surplus = asset.balanceOf(address(this)) - vault[i];

                if (amounts[i] > surplus) revert VL_ExceedsSurplus();

                asset.safeTransfer(otc, amounts[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Processes withdrawing assets based on shares
     * @dev used to send assets to the pauser at the end of each round
     */
    function withdrawWithShares(address recipient, uint256 shares, uint256 totalSupply, Vault.Collateral[] calldata collaterals)
        external
        returns (uint256[] memory amounts)
    {
        amounts = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length;) {
            uint256 balance = IERC20(collaterals[i].addr).balanceOf(address(this));

            amounts[i] = balance.mulDivDown(shares, totalSupply);

            if (amounts[i] != 0) {
                IERC20(collaterals[i].addr).safeTransfer(recipient, amounts[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Verify the constructor params satisfy requirements
     * @param initParams is the struct with vault general data
     * @param vaultParams is the struct with vault general data
     */
    function verifyInitializerParams(Vault.InitParams calldata initParams, Vault.VaultParams calldata vaultParams)
        external
        pure
    {
        if (initParams._owner == address(0)) revert VL_BadOwnerAddress();
        if (initParams._manager == address(0)) revert VL_BadManagerAddress();
        if (initParams._feeRecipient == address(0)) revert VL_BadFeeAddress();
        if (initParams._oracle == address(0)) revert VL_BadOracleAddress();
        if (initParams._pauser == address(0)) revert VL_BadPauserAddress();
        if (initParams._performanceFee > 100 * Vault.FEE_MULTIPLIER || initParams._managementFee > 100 * Vault.FEE_MULTIPLIER) {
            revert VL_BadFee();
        }

        if (initParams._instruments.length == 0) revert VL_BadInstruments();

        for (uint256 i; i < initParams._instruments.length;) {
            if (initParams._instruments[i].weight == 0) revert VL_BadWeight();
            if (initParams._instruments[i].oracle == address(0)) revert VL_BadOracleAddress();
            if (initParams._instruments[i].underlying == address(0)) revert VL_BadUnderlyingAddress();
            if (initParams._instruments[i].strike == address(0)) revert VL_BadStrikeAddress();
            if (initParams._instruments[i].collateral == address(0)) revert VL_BadCollateralAddress();

            unchecked {
                ++i;
            }
        }

        if (initParams._collaterals.length == 0) revert VL_BadCollateral();
        for (uint256 i; i < initParams._collaterals.length;) {
            if (initParams._collaterals[i].id == 0) revert VL_BadCollateral();
            if (initParams._collaterals[i].addr == address(0)) revert VL_BadCollateralAddress();

            unchecked {
                ++i;
            }
        }

        if (vaultParams.minimumSupply == 0) revert VL_BadSupply();
        if (vaultParams.cap == 0) revert VL_BadCap();
        if (vaultParams.cap <= vaultParams.minimumSupply) revert VL_BadCap();

        if (
            initParams._roundConfig.duration == 0 || initParams._roundConfig.dayOfWeek > 8
                || initParams._roundConfig.hourOfDay > 23
        ) revert VL_BadDuration();
    }
}