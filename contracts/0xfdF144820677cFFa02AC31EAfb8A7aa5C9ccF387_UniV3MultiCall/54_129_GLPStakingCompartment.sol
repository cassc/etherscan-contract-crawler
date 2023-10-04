// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IGLPStakingHelper} from "../../interfaces/compartments/staking/IGLPStakingHelper.sol";
import {BaseCompartment} from "../BaseCompartment.sol";

contract GLPStakingCompartment is BaseCompartment {
    using SafeERC20 for IERC20;

    // arbitrum WETH address
    address private constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address private constant FEE_GLP =
        0x4e971a87900b931fF39d1Aad67697F49835400b6;

    // transfer coll on repays
    function transferCollFromCompartment(
        uint256 repayAmount,
        uint256 repayAmountLeft,
        uint128 reclaimCollAmount,
        address borrowerAddr,
        address collTokenAddr,
        address callbackAddr
    ) external {
        _transferCollFromCompartment(
            reclaimCollAmount,
            borrowerAddr,
            collTokenAddr,
            callbackAddr
        );

        _transferRewards(
            collTokenAddr,
            borrowerAddr,
            repayAmount,
            repayAmountLeft,
            false
        );
    }

    // unlockColl this would be called on defaults
    function unlockCollToVault(address collTokenAddr) external {
        _unlockCollToVault(collTokenAddr);
        _transferRewards(collTokenAddr, vaultAddr, 0, 0, true);
    }

    function getReclaimableBalance(
        address collToken
    ) external view override returns (uint256) {
        return IERC20(collToken).balanceOf(address(this));
    }

    function _transferRewards(
        address collTokenAddr,
        address recipient,
        uint256 repayAmount,
        uint256 repayAmountLeft,
        bool isUnlock
    ) internal {
        // if collTokenAddr is weth, then return so don't double transfer on partial repay
        // or waste gas on unlock when no rewards will be paid out
        // note: this should never actually happen since weth
        // and this compartment should not be whitelisted, but just in case
        if (collTokenAddr == WETH) {
            return;
        }

        // solhint-disable no-empty-blocks
        try IGLPStakingHelper(FEE_GLP).claim(address(this)) {
            // do nothing
            // solhint-disable no-empty-blocks
        } catch {
            // do nothing
        }

        // check weth token balance
        uint256 currentWethBal = IERC20(WETH).balanceOf(address(this));

        // transfer proportion of weth token balance
        uint256 wethTokenAmount = isUnlock
            ? currentWethBal
            : Math.mulDiv(repayAmount, currentWethBal, repayAmountLeft);
        IERC20(WETH).safeTransfer(recipient, wethTokenAmount);
    }
}