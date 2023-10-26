// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library OptimizedFeeList {
    uint16 private constant START_INDEX = 0; // Fees mapping start index

    // input struct for setting fees
    struct FeeData {
        address receiver;       // fee receiver address
        uint16 fee;             // fee in basis points (10000 = 10%)
        bool swapRequired;      // true - swap is required. false - transfer to receiver without swap
    }

    // storage struct which contains elements count in the first element
    struct FeeStorage {
        address receiver;       // receiver address
        uint16 fee;             // fee in basis points (10000 = 10%)
        uint16 count;           // first element must contain number of items (like array.length)
        bool swapRequired;      // true - swap to target stablecoin is required. false - transfer to receiver without swap
    }

    struct FeeAmount {
        address receiver;       // fee receiver address
        uint256 amount;         // amount of tokens to give as fees
        bool swapRequired;      // true - swap is required. false - transfer to receiver without swap
    }
    struct FeesList {
        mapping(uint256 => FeeStorage) _data;
    }


    /*
     * @title Function for setting fees
     * @param fees FeesList storage
     * @param feeData List or fees and receivers
     * @dev Sum of fees cant exceed 100% (10 000 basis points)
     */
    function setFees(
        FeesList storage fees,
        FeeData[] memory feeData
    ) internal returns(uint256 totalFees) {
        uint256 oldCount = fees._data[START_INDEX].count;
        uint256 newCount = feeData.length;
        totalFees = 0;

        fees._data[START_INDEX].count = uint16(newCount);
        for (uint i = START_INDEX; i < START_INDEX + newCount; i++) {
            fees._data[i].receiver = feeData[i].receiver;
            fees._data[i].fee = feeData[i].fee;
            fees._data[i].swapRequired = feeData[i].swapRequired;
            totalFees += feeData[i].fee;
        }

        // deleting old values to release storage and get gas refund
        // will be executed only if oldCount > newCount
        for (uint i = START_INDEX + newCount; i < START_INDEX + oldCount; i++) {
            delete fees._data[i];
        }

        require(totalFees <= 10_000, "Total fees over 100%");
    }


    /*
     * @notice Calculates amount of fees to collect for specific amount ot credits
     * @param fees FeesList storage
     * @param amount Amount of tokens to take fees from
     * @return feeAmounts Array of {receiver, feeAmount, swapRequired} structs
     * @return totalToSwap Total amount of tokens that should be swapped to target stablecoin
     */
    function calculateFeeAmounts(
        FeesList storage fees,
        uint256 amount
    ) internal view returns(
        FeeAmount[] memory feeAmounts,
        uint256 totalToSwap
    ) {
        feeAmounts = new FeeAmount[](fees._data[START_INDEX].count);
        totalToSwap = 0;
        uint256 finalAmount = amount;

        for (uint i = START_INDEX; i < START_INDEX + feeAmounts.length; i++) {
            FeeStorage memory feeMemory = fees._data[i];
            feeAmounts[i] = FeeAmount({
                receiver: feeMemory.receiver,
                amount: amount * feeMemory.fee / 10_000,
                swapRequired: feeMemory.swapRequired
            });
            if (feeMemory.swapRequired) {
                totalToSwap += feeAmounts[i].amount;
            }

            // underflow will revert function call, which will result in withdrawal without fees
            finalAmount -= feeAmounts[i].amount;
        }

        return (feeAmounts, totalToSwap);
    }


    /*
     * @return Returns true if fees are set
     */
    function isSet(
        FeesList storage fees
    ) internal view returns(bool) {
        return fees._data[START_INDEX].count != 0;
    }
}