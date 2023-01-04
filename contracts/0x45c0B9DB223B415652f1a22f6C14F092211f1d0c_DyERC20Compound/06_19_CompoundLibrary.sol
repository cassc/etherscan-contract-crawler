// contracts/Compound/lib/CompoundLibrary.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../lib/Exponential.sol";
import "../interfaces/ICompoundUnitroller.sol";
import "../interfaces/ICompoundERC20Delegator.sol";

library CompoundLibrary {
    using SafeMath for uint256;

    function calculateReward(
        ICompoundUnitroller rewardController,
        ICompoundERC20Delegator tokenDelegator,
        address account
    ) internal view returns (uint256) {
        uint256 compAccrued = rewardController.compAccrued(account);
        return
            compAccrued
                .add(supplyAccrued(rewardController, tokenDelegator, account))
                .add(borrowAccrued(rewardController, tokenDelegator, account));
    }

    function supplyAccrued(
        ICompoundUnitroller rewardController,
        ICompoundERC20Delegator tokenDelegator,
        address account
    ) internal view returns (uint256) {
        Exponential.Double memory supplyIndex = Exponential.Double({
            mantissa: _supplyIndex(rewardController, tokenDelegator)
        });
        Exponential.Double memory supplierIndex = Exponential.Double({
            mantissa: rewardController.compSupplierIndex(
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
        ICompoundUnitroller rewardController,
        ICompoundERC20Delegator tokenDelegator,
        address account
    ) internal view returns (uint256 borrowAccrued_) {
        Exponential.Double memory borrowerIndex = Exponential.Double({
            mantissa: rewardController.compBorrowerIndex(
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
        ICompoundUnitroller rewardController,
        ICompoundERC20Delegator tokenDelegator
    ) private view returns (uint224) {
        (uint224 supplyStateIndex, uint256 supplyStateBlock) = rewardController
            .compSupplyState(address(tokenDelegator));

        uint256 supplySpeed = rewardController.compSupplySpeeds(
            address(tokenDelegator)
        );
        uint256 deltaBlocks = Exponential.sub_(
            block.number,
            uint256(supplyStateBlock)
        );
        if (deltaBlocks > 0 && supplySpeed > 0) {
            uint256 supplyTokens = ICompoundERC20Delegator(tokenDelegator)
                .totalSupply();
            uint256 compAccrued = Exponential.mul_(deltaBlocks, supplySpeed);
            Exponential.Double memory ratio = supplyTokens > 0
                ? Exponential.fraction(compAccrued, supplyTokens)
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
        ICompoundUnitroller rewardController,
        ICompoundERC20Delegator tokenDelegator,
        Exponential.Exp memory marketBorrowIndex
    ) private view returns (uint224) {
        (uint224 borrowStateIndex, uint256 borrowStateBlock) = rewardController
            .compBorrowState(address(tokenDelegator));
        uint256 borrowSpeed = rewardController.compBorrowSpeeds(
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
            uint256 compAccrued = Exponential.mul_(deltaBlocks, borrowSpeed);
            Exponential.Double memory ratio = borrowAmount > 0
                ? Exponential.fraction(compAccrued, borrowAmount)
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