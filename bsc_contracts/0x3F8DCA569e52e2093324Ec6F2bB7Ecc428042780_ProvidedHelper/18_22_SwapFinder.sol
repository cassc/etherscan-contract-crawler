// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./AddressArray.sol";
import "hardhat/console.sol";

struct SwapPoint {
    uint256 amountIn;
    uint256 valueIn;
    uint256 amountOut;
    uint256 valueOut;
    int256 slippage;
    address tokenIn;
    address[] swappers;
    address tokenOut;
    address[][] paths;
}

library SwapFinder {
    using AddressArray for address[];

    function sort(SwapPoint[] memory self) internal pure returns (SwapPoint[] memory sorted) {
        sorted = new SwapPoint[](self.length);
        for (uint256 i = 0; i < self.length; i++) {
            int256 minSlippage = 2 ** 128 - 1;
            uint256 minSlippageIndex = 0;
            for (uint256 j = 0; j < self.length; j++) {
                if (self[j].slippage < minSlippage) {
                    minSlippageIndex = j;
                    minSlippage = self[j].slippage;
                }
            }
            sorted[i] = self[minSlippageIndex];
            self[minSlippageIndex].slippage = 2 ** 128 - 1;
        }
    }

    function append(
        SwapPoint[] memory self,
        SwapPoint memory swap
    ) internal pure returns (SwapPoint[] memory newSwaps) {
        newSwaps = new SwapPoint[](self.length + 1);
        for (uint i = 0; i < self.length; i++) {
            newSwaps[i] = self[i];
        }
        newSwaps[self.length] = swap;
        return newSwaps;
    }

    struct StackMinimizingStruct {
        uint256 valueIn;
        uint256 toConvertIndex;
        uint256 convertToIndex;
    }

    struct StackMinimizingStruct2 {
        uint256[] valuesUsed;
        uint256[] valuesProvided;
        uint256 swapsAdded;
    }

    function findBestSwaps(
        SwapPoint[] memory self,
        address[] memory toConvert,
        uint256[] memory valuesToConvert,
        uint256[] memory amountsToConvert,
        address[] memory convertTo,
        uint256[] memory wantedValues
    ) internal pure returns (SwapPoint[] memory swaps) {
        SwapPoint[] memory bestSwaps = new SwapPoint[](self.length);
        StackMinimizingStruct2 memory data2 = StackMinimizingStruct2(
            new uint256[](toConvert.length),
            new uint256[](wantedValues.length),
            0
        );
        for (uint256 i = 0; i < self.length; i++) {
            StackMinimizingStruct memory data = StackMinimizingStruct(
                self[i].valueIn,
                toConvert.findFirst(self[i].tokenIn),
                convertTo.findFirst(self[i].tokenOut)
            );
            if (self[i].tokenIn == address(0) || self[i].tokenOut == address(0)) continue;
            if (
                data2.valuesUsed[data.toConvertIndex] < valuesToConvert[data.toConvertIndex] &&
                data2.valuesProvided[data.convertToIndex] < wantedValues[data.convertToIndex]
            ) {
                uint256 valueInAdjusted;
                {
                    uint256 moreValueInAvailable = valuesToConvert[data.toConvertIndex] -
                        data2.valuesUsed[data.toConvertIndex];
                    uint256 moreValueOutNeeded = wantedValues[data.convertToIndex] -
                        data2.valuesProvided[data.convertToIndex];
                    valueInAdjusted = moreValueInAvailable >= data.valueIn ? data.valueIn : moreValueInAvailable;
                    if (valueInAdjusted > moreValueOutNeeded) {
                        valueInAdjusted = moreValueOutNeeded;
                    }
                }
                self[i].amountIn =
                    (valueInAdjusted * amountsToConvert[data.toConvertIndex]) /
                    valuesToConvert[data.toConvertIndex];
                self[i].valueIn = valueInAdjusted;
                self[i].valueOut = (valueInAdjusted * self[i].valueOut) / self[i].valueIn;
                self[i].amountOut = (valueInAdjusted * self[i].amountOut) / self[i].valueIn;
                bestSwaps[data2.swapsAdded] = self[i];
                data2.swapsAdded += 1;
                data2.valuesUsed[data.toConvertIndex] += valueInAdjusted;
                data2.valuesProvided[data.convertToIndex] += valueInAdjusted;
                continue;
            }
        }
        uint256 numSwaps = 0;
        for (uint256 i = 0; i < bestSwaps.length; i++) {
            if (bestSwaps[i].tokenIn != address(0) && bestSwaps[i].amountIn > 0) {
                numSwaps += 1;
            }
        }
        swaps = new SwapPoint[](numSwaps);
        uint256 swapsAdded;
        for (uint256 i = 0; i < bestSwaps.length; i++) {
            if (bestSwaps[i].tokenIn != address(0) && bestSwaps[i].amountIn > 0) {
                swaps[swapsAdded] = bestSwaps[i];
                swapsAdded += 1;
            }
        }
        for (uint256 i = 0; i < swaps.length; i++) {
            swaps[i].amountIn = (1e18 * swaps[i].amountIn) / amountsToConvert[toConvert.findFirst(swaps[i].tokenIn)];
        }
        return swaps;
    }

    function log(SwapPoint memory self) internal view {
        console.log("Swapping ", self.tokenIn, " for ", self.tokenOut);
        console.log("Amount in: ", self.amountIn, " Value in: ", self.valueIn);
        console.log("Amount out: ", self.amountOut, " Value out: ", self.valueOut);
        console.log("Swappers used:");
        for (uint i = 0; i < self.swappers.length; i++) {
            console.log(self.swappers[i]);
            console.log("Path used:");
            for (uint j = 0; j < self.paths[i].length; j++) {
                console.log(self.paths[i][j]);
            }
            console.log("___________________");
        }
    }

    function log(SwapPoint[] memory self) internal view {
        for (uint i = 0; i < self.length; i++) {
            log(self[i]);
        }
    }
}