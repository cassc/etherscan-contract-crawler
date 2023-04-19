// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma abicoder v2;

import "@openzeppelin/contracts-0.8/utils/math/Math.sol";

contract InterestCalculator {
    struct InterestRate {
        uint interest;
        uint till;
    }

    InterestRate[] public oldRates;
    uint public currentInterest;

    event InterestRateChanged(uint rate, uint timestamp);

    constructor(uint rate) {
        currentInterest = rate;
    }

    function _updateInterest(uint rate) internal {
        oldRates.push(
            InterestRate({ interest: currentInterest, till: block.timestamp })
        );
        currentInterest = rate;
        emit InterestRateChanged(rate, block.timestamp);
    }

    function _earned(
        uint amount,
        uint begining,
        uint ending
    ) internal view returns (uint) {
        if (oldRates.length == 0)
            return _calculate(ending - begining, amount, currentInterest);

        uint index = findUpperBound(begining);
        uint total;
        InterestRate[] memory array = oldRates;
        for (uint i = index; i < oldRates.length; i += 1) {
            total += _calculate(
                array[i].till - begining,
                amount,
                array[i].interest
            );
            begining = array[i].till;
        }
        total += _calculate(ending - begining, amount, currentInterest);
        return total;
    }

    function _calculate(
        uint time,
        uint amount,
        uint rewardRate
    ) internal pure returns (uint) {
        uint timeCovered = time / 1 days; // Time covered in days

        // rewards =  amount * nominalApy * rewardPercentage
        // nominalApy = rewardPercentage / 365
        return (amount * rewardRate * timeCovered) / (36500);
    }

    // Binary search
    function findUpperBound(uint256 element) internal view returns (uint256) {
        InterestRate[] memory array = oldRates;

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            if (array[mid].till > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        if (low > 0 && array[low - 1].till == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    function getOldRates() external view returns (InterestRate[] memory) {
        return oldRates;
    }
}