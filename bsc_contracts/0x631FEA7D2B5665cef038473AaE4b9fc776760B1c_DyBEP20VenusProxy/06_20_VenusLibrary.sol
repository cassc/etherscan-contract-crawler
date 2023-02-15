// contracts/Venus/VenusLibrary.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../lib/Exponential.sol";
import "../interfaces/IVenusUnitroller.sol";
import "../interfaces/IVenusBEP20Delegator.sol";

library VenusLibrary {
    using SafeMath for uint256;

    function calculateReward(
        IVenusUnitroller rewardController,
        IVenusBEP20Delegator tokenDelegator,
        address account
    ) internal view returns (uint256) {
        uint256 venusAccrued = rewardController.venusAccrued(account);
        return
            venusAccrued
                .add(supplyAccrued(rewardController, tokenDelegator, account))
                .add(borrowAccrued(rewardController, tokenDelegator, account));
    }

    function supplyAccrued(
        IVenusUnitroller rewardController,
        IVenusBEP20Delegator tokenDelegator,
        address account
    ) internal view returns (uint256) {
        Exponential.Double memory supplyIndex = Exponential.Double({
            mantissa: _supplyIndex(rewardController, tokenDelegator)
        });
        Exponential.Double memory supplierIndex = Exponential.Double({
            mantissa: rewardController.venusSupplierIndex(
                address(tokenDelegator),
                account
            )
        });

        if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
            supplierIndex.mantissa = 1e36;
        }
        Exponential.Double memory deltaIndex = supplyIndex.mantissa > 0
            ? Exponential.sub_(supplyIndex, supplierIndex)
            : Exponential.Double({mantissa: 0});
        return Exponential.mul_(tokenDelegator.balanceOf(account), deltaIndex);
    }

    function borrowAccrued(
        IVenusUnitroller rewardController,
        IVenusBEP20Delegator tokenDelegator,
        address account
    ) internal view returns (uint256 borrowAccrued_) {
        Exponential.Double memory borrowerIndex = Exponential.Double({
            mantissa: rewardController.venusBorrowerIndex(
                address(tokenDelegator),
                account
            )
        });
        borrowAccrued_ = 0;
        if (borrowerIndex.mantissa > 0) {
            Exponential.Exp memory marketBorrowIndex = Exponential.Exp({
                mantissa: tokenDelegator.borrowIndex()
            });
            Exponential.Double memory borrowIndex = Exponential.Double({
                mantissa: _borrowIndex(
                    rewardController,
                    tokenDelegator,
                    marketBorrowIndex
                )
            });
            if (borrowIndex.mantissa > 0) {
                Exponential.Double memory deltaIndex = Exponential.sub_(
                    borrowIndex,
                    borrowerIndex
                );
                uint256 borrowerAmount = Exponential.div_(
                    tokenDelegator.borrowBalanceStored(address(this)),
                    marketBorrowIndex
                );
                borrowAccrued_ = Exponential.mul_(borrowerAmount, deltaIndex);
            }
        }
    }

    function _supplyIndex(
        IVenusUnitroller rewardController,
        IVenusBEP20Delegator tokenDelegator
    ) private view returns (uint224) {
        (uint224 supplyStateIndex, uint256 supplyStateBlock) = rewardController
            .venusSupplyState(address(tokenDelegator));

        uint256 supplySpeed = rewardController.venusSpeeds(
            address(tokenDelegator)
        );
        uint256 deltaBlocks = Exponential.sub_(
            block.number,
            uint256(supplyStateBlock)
        );
        if (deltaBlocks > 0 && supplySpeed > 0) {
            uint256 supplyTokens = IVenusBEP20Delegator(tokenDelegator)
                .totalSupply();
            uint256 venusAccrued = Exponential.mul_(deltaBlocks, supplySpeed);
            Exponential.Double memory ratio = supplyTokens > 0
                ? Exponential.fraction(venusAccrued, supplyTokens)
                : Exponential.Double({mantissa: 0});
            Exponential.Double memory index = Exponential.add_(
                Exponential.Double({mantissa: supplyStateIndex}),
                ratio
            );
            return
                Exponential.safe224(
                    index.mantissa,
                    "new index exceeds 224 bits"
                );
        }
        return 0;
    }

    function _borrowIndex(
        IVenusUnitroller rewardController,
        IVenusBEP20Delegator tokenDelegator,
        Exponential.Exp memory marketBorrowIndex
    ) private view returns (uint224) {
        (uint224 borrowStateIndex, uint256 borrowStateBlock) = rewardController
            .venusBorrowState(address(tokenDelegator));
        uint256 borrowSpeed = rewardController.venusSpeeds(
            address(tokenDelegator)
        );
        uint256 deltaBlocks = Exponential.sub_(
            block.number,
            uint256(borrowStateBlock)
        );
        if (deltaBlocks > 0 && borrowSpeed > 0) {
            uint256 borrowAmount = Exponential.div_(
                tokenDelegator.totalBorrows(),
                marketBorrowIndex
            );
            uint256 venusAccrued = Exponential.mul_(deltaBlocks, borrowSpeed);
            Exponential.Double memory ratio = borrowAmount > 0
                ? Exponential.fraction(venusAccrued, borrowAmount)
                : Exponential.Double({mantissa: 0});
            Exponential.Double memory index = Exponential.add_(
                Exponential.Double({mantissa: borrowStateIndex}),
                ratio
            );
            return
                Exponential.safe224(
                    index.mantissa,
                    "new index exceeds 224 bits"
                );
        }
        return 0;
    }
}