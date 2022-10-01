pragma solidity ^0.8.9;

import {BondStruct} from "./BondStruct.sol";

library BondMath {
    function calculateFaceValue(uint256 bondUnit, uint256 faceValue)
        internal
        pure
        returns (uint256)
    {
        return (bondUnit * faceValue) / (10**18);
    }

    function calculateBondAmountWithFlexPrice(
        uint256 maxOfRange,
        uint256 priceOfRange,
        uint256 currentSupply,
        uint256 faceAmount
    ) internal pure returns (uint256 bondAmount, uint256 paidFaceAmount) {
        uint256 availableAmountInRange = maxOfRange - currentSupply;
        uint256 faceAmountForAvailable = (availableAmountInRange *
            priceOfRange) / (10**18);
        if (faceAmount <= faceAmountForAvailable) {
            bondAmount = calculateBondAmountWithFixPrice(
                faceAmount,
                priceOfRange
            );
            paidFaceAmount = faceAmount;
        } else {
            bondAmount = calculateBondAmountWithFixPrice(
                faceAmountForAvailable,
                priceOfRange
            );
            paidFaceAmount = faceAmountForAvailable;
        }
    }

    function calculateBondAmountWithFixPrice(
        uint256 faceAmount,
        uint256 issuePrice
    ) internal pure returns (uint256) {
        return (faceAmount * (10**18)) / issuePrice;
    }

    function calculateUnderlyingAsset(
        uint256 bondBalance,
        uint256 bondSupply,
        uint256 underlyingAmount
    ) internal pure returns (uint256) {
        return (bondBalance * underlyingAmount) / bondSupply;
    }

    function calculateRemainderUnderlyingAsset(
        uint256 totalBondSupply,
        uint256 currentBondSupply,
        uint256 underlyingAmount
    ) internal pure returns (uint256) {
        return
            ((totalBondSupply - currentBondSupply) * underlyingAmount) /
            totalBondSupply;
    }

    function getBondAmountInRange(
        BondStruct.BondPriceRange[] memory _bondPriceRange,
        uint256 _currentSupply,
        uint256 amount
    ) internal pure returns (uint256 bondAmount, uint256 faceAmount) {
        for (uint256 i = 0; i < _bondPriceRange.length; i++) {
            if (
                _bondPriceRange[i].min <= _currentSupply &&
                _currentSupply < _bondPriceRange[i].max
            ) {
                (bondAmount, faceAmount) = BondMath
                    .calculateBondAmountWithFlexPrice(
                        _bondPriceRange[i].max,
                        _bondPriceRange[i].price,
                        _currentSupply,
                        amount
                    );
                return (bondAmount, faceAmount);
            }
        }
        return (0, 0);
    }

    function calculateIssuePriceWithRange(
        BondStruct.BondPriceRange[] memory _bondPriceRange,
        uint256 _totalSupply
    ) internal pure returns (uint256) {
        uint256 totalFaceValue;
        for (uint256 i = 0; i < _bondPriceRange.length; i++) {
            totalFaceValue +=
                (_bondPriceRange[i].max - _bondPriceRange[i].min) *
                _bondPriceRange[i].price;
        }
        return totalFaceValue / _totalSupply;
    }

    function availableAmountToCommit(
        uint256 amountCommit,
        uint256 totalAmountCommitted,
        uint256 maxAmountCanCommit
    ) internal pure returns (uint256) {
        if (totalAmountCommitted + amountCommit > maxAmountCanCommit) {
            return maxAmountCanCommit - totalAmountCommitted;
        }
        return amountCommit;
    }

    function calculateBondDistributionAmount(
        uint256 amountCommitted,
        uint256 totalAmountCommitted,
        uint256 bondSupply
    ) internal pure returns (uint256 bondAmount) {
        return (bondSupply * amountCommitted) / totalAmountCommitted;
    }
}