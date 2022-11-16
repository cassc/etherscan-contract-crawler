// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LibOrder.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

library LibFill {
    using SafeMathUpgradeable for uint256;

    struct FillResult {
        uint256 leftValue;
        uint256 rightValue;
    }

    /**
     * @dev Should return filled values
     * @param leftOrder left order
     * @param rightOrder right order
     * @param leftOrderFill current fill of the left order (0 if order is unfilled)
     * @param rightOrderFill current fill of the right order (0 if order is unfilled)
     * @param leftIsMakeFill true if left orders fill is calculated from the make side, false if from the take side
     * @param rightIsMakeFill true if right orders fill is calculated from the make side, false if from the take side
     */
    function fillOrder(
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        uint256 leftOrderFill,
        uint256 rightOrderFill,
        bool leftIsMakeFill,
        bool rightIsMakeFill
    ) internal view returns (FillResult memory) {
        (uint256 leftMakeValue, uint256 leftTakeValue) = LibOrder
            .calculateRemaining(leftOrder, leftOrderFill, leftIsMakeFill);
        (uint256 rightMakeValue, uint256 rightTakeValue) = LibOrder
            .calculateRemaining(rightOrder, rightOrderFill, rightIsMakeFill);

        //We have 2 cases here:
        if (rightTakeValue > leftMakeValue) {
            //1nd: left order should be fully filled
            return
                fillLeft(
                    leftMakeValue,
                    leftTakeValue,
                    rightOrder.makeAsset.value,
                    rightOrder.takeAsset.value
                );
        } //2st: right order should be fully filled or 3d: both should be fully filled if required values are the same
        return
            fillRight(
                leftOrder.makeAsset.value,
                leftOrder.takeAsset.value,
                rightMakeValue,
                rightTakeValue,
                leftOrder
            );
    }

    function fillRight(
        uint256 leftMakeValue,
        uint256 leftTakeValue,
        uint256 rightMakeValue,
        uint256 rightTakeValue,
        LibOrder.Order memory leftOrder
    ) internal view returns (FillResult memory result) {
        uint256 makerValue = LibMath.safeGetPartialAmountFloor(
            rightTakeValue,
            leftMakeValue,
            leftTakeValue
        );
        // check if it is the seller accepted offer
        if (msg.sender == leftOrder.maker) {
            return FillResult(rightTakeValue, rightMakeValue);
        }

        require(makerValue <= rightMakeValue, "fillRight: unable to fill");
        return FillResult(rightTakeValue, makerValue);
    }

    function fillLeft(
        uint256 leftMakeValue,
        uint256 leftTakeValue,
        uint256 rightMakeValue,
        uint256 rightTakeValue
    ) internal pure returns (FillResult memory result) {
        uint256 rightTake = LibMath.safeGetPartialAmountFloor(
            leftTakeValue,
            rightMakeValue,
            rightTakeValue
        );
        require(rightTake <= leftMakeValue, "fillLeft: unable to fill");
        return FillResult(leftMakeValue, leftTakeValue);
    }

    function fillAuctionOrder(
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        uint256 leftOrderFill,
        uint256 rightOrderFill,
        bool leftIsMakeFill,
        bool rightIsMakeFill
    ) internal pure returns (FillResult memory) {
        (uint256 leftMakeValue, uint256 leftTakeValue) = LibOrder
            .calculateRemaining(leftOrder, leftOrderFill, leftIsMakeFill);
        (uint256 rightMakeValue, uint256 rightTakeValue) = LibOrder
            .calculateRemaining(rightOrder, rightOrderFill, rightIsMakeFill);
        require(leftTakeValue <= rightMakeValue, "Lower than reserved price");
        uint256 makerValue = LibMath.safeGetPartialAmountFloor(
            rightTakeValue,
            leftMakeValue,
            rightMakeValue
        );
        require(
            makerValue <= rightMakeValue,
            "fillAuctionOrder: unable to fill"
        );

        return FillResult(rightTakeValue, rightMakeValue);
    }
}