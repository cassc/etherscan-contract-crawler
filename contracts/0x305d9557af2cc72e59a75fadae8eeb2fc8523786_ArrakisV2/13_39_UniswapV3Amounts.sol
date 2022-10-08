// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {FullMath} from "@arrakisfi/v3-lib-0.8/contracts/LiquidityAmounts.sol";
import {FeesEarnedPayload} from "../structs/SArrakisV2.sol";

library UniswapV3Amounts {
    // solhint-disable-next-line function-max-lines
    function computeFeesEarned(FeesEarnedPayload memory computeFeesEarned_)
        public
        view
        returns (uint256 fee)
    {
        uint256 feeGrowthOutsideLower;
        uint256 feeGrowthOutsideUpper;
        uint256 feeGrowthGlobal;
        if (computeFeesEarned_.isZero) {
            feeGrowthGlobal = computeFeesEarned_.pool.feeGrowthGlobal0X128();
            (, , feeGrowthOutsideLower, , , , , ) = computeFeesEarned_
                .pool
                .ticks(computeFeesEarned_.lowerTick);
            (, , feeGrowthOutsideUpper, , , , , ) = computeFeesEarned_
                .pool
                .ticks(computeFeesEarned_.upperTick);
        } else {
            feeGrowthGlobal = computeFeesEarned_.pool.feeGrowthGlobal1X128();
            (, , , feeGrowthOutsideLower, , , , ) = computeFeesEarned_
                .pool
                .ticks(computeFeesEarned_.lowerTick);
            (, , , feeGrowthOutsideUpper, , , , ) = computeFeesEarned_
                .pool
                .ticks(computeFeesEarned_.upperTick);
        }

        unchecked {
            // calculate fee growth below
            uint256 feeGrowthBelow;
            if (computeFeesEarned_.tick >= computeFeesEarned_.lowerTick) {
                feeGrowthBelow = feeGrowthOutsideLower;
            } else {
                feeGrowthBelow = feeGrowthGlobal - feeGrowthOutsideLower;
            }

            // calculate fee growth above
            uint256 feeGrowthAbove;
            if (computeFeesEarned_.tick < computeFeesEarned_.upperTick) {
                feeGrowthAbove = feeGrowthOutsideUpper;
            } else {
                feeGrowthAbove = feeGrowthGlobal - feeGrowthOutsideUpper;
            }

            uint256 feeGrowthInside = feeGrowthGlobal -
                feeGrowthBelow -
                feeGrowthAbove;
            fee = FullMath.mulDiv(
                computeFeesEarned_.liquidity,
                feeGrowthInside - computeFeesEarned_.feeGrowthInsideLast,
                0x100000000000000000000000000000000
            );
        }
    }

    function subtractAdminFees(
        uint256 rawFee0_,
        uint256 rawFee1_,
        uint16 managerFeeBPS_,
        uint16 arrakisFeeBPS_
    ) public pure returns (uint256 fee0, uint256 fee1) {
        fee0 =
            rawFee0_ -
            ((rawFee0_ * (managerFeeBPS_ + arrakisFeeBPS_)) / 10000);
        fee1 =
            rawFee1_ -
            ((rawFee1_ * (managerFeeBPS_ + arrakisFeeBPS_)) / 10000);
    }

    function subtractAdminFeesOnAmounts(
        uint256 rawFee0_,
        uint256 rawFee1_,
        uint16 managerFeeBPS_,
        uint16 arrakisFeeBPS_,
        uint256 amount0_,
        uint256 amount1_
    ) public pure returns (uint256 amount0, uint256 amount1) {
        (uint256 fee0, uint256 fee1) = subtractAdminFees(
            rawFee0_,
            rawFee1_,
            managerFeeBPS_,
            arrakisFeeBPS_
        );
        amount0 = amount0_ - (rawFee0_ - fee0);
        amount1 = amount1_ - (rawFee1_ - fee1);
    }

    // solhint-disable-next-line function-max-lines
    function computeMintAmounts(
        uint256 current0_,
        uint256 current1_,
        uint256 totalSupply_,
        uint256 amount0Max_,
        uint256 amount1Max_
    )
        public
        pure
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        )
    {
        // compute proportional amount of tokens to mint
        if (current0_ == 0 && current1_ > 0) {
            mintAmount = FullMath.mulDiv(amount1Max_, totalSupply_, current1_);
        } else if (current1_ == 0 && current0_ > 0) {
            mintAmount = FullMath.mulDiv(amount0Max_, totalSupply_, current0_);
        } else if (current0_ > 0 && current1_ > 0) {
            uint256 amount0Mint = FullMath.mulDiv(
                amount0Max_,
                totalSupply_,
                current0_
            );
            uint256 amount1Mint = FullMath.mulDiv(
                amount1Max_,
                totalSupply_,
                current1_
            );
            require(
                amount0Mint > 0 && amount1Mint > 0,
                "ArrakisVaultV2: mint 0"
            );

            mintAmount = amount0Mint < amount1Mint ? amount0Mint : amount1Mint;
        } else {
            revert("ArrakisVaultV2: panic");
        }

        // compute amounts owed to contract
        amount0 = FullMath.mulDivRoundingUp(
            mintAmount,
            current0_,
            totalSupply_
        );
        amount1 = FullMath.mulDivRoundingUp(
            mintAmount,
            current1_,
            totalSupply_
        );
    }
}