// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Math} from "./libraries/Math.sol";
import {IPoolInformation} from "./interfaces/IPoolInformation.sol";
import {IPool} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IPool.sol";

contract PoolInformation is IPoolInformation {
    uint8 constant NUMBER_OF_KINDS = 4;

    function getActiveBins(IPool pool, uint128 startBinIndex, uint128 endBinIndex) external view returns (BinInfo[] memory bins) {
        uint128 binCounter = pool.getState().binCounter;
        if (endBinIndex != 0) {
            binCounter = binCounter < endBinIndex ? binCounter : endBinIndex;
        }
        bins = new BinInfo[](binCounter);
        uint128 activeCounter = 0;
        for (uint128 i = startBinIndex; i < binCounter; i++) {
            IPool.BinState memory bin = pool.getBin(i + 1);
            if (pool.binPositions(bin.lowerTick, bin.kind) == i + 1 || bin.mergeId != 0) {
                bins[activeCounter] = BinInfo({id: i + 1, kind: bin.kind, lowerTick: bin.lowerTick, reserveA: bin.reserveA, reserveB: bin.reserveB, mergeId: bin.mergeId});
                activeCounter++;
            }
        }
        if (activeCounter != binCounter) {
            uint128 binCountToRemove = binCounter - activeCounter;
            assembly {
                mstore(bins, sub(mload(bins), binCountToRemove))
            }
        }
    }

    function getBinDepth(IPool pool, uint128 binId) public view returns (uint256 depth) {
        IPool.BinState memory bin = pool.getBin(binId);
        while (bin.mergeId != 0) {
            depth++;
            binId = bin.mergeId;
            bin = pool.getBin(bin.mergeId);
        }
    }

    function swapCallback(uint256 amountIn, uint256 amountOut, bytes calldata _data) external pure {
        bool exactOutput = abi.decode(_data, (bool));
        if (exactOutput) {
            revert(string(abi.encode(amountIn)));
        } else {
            revert(string(abi.encode(amountOut)));
        }
    }

    function calculateSwap(IPool pool, uint128 amount, bool tokenAIn, bool exactOutput, uint256 sqrtPriceLimit) external returns (uint256 returnAmount) {
        try pool.swap(address(this), amount, tokenAIn, exactOutput, sqrtPriceLimit, abi.encode(exactOutput)) {} catch Error(string memory _data) {
            if (bytes(_data).length == 0) {
                revert("Invalid Swap");
            }
            return abi.decode(bytes(_data), (uint256));
        }
    }

    function getSqrtPrice(IPool pool) external view returns (uint256 sqrtPrice) {
        (sqrtPrice, , , ) = activeTickLiquidity(pool);
    }

    function getBinsAtTick(IPool pool, int32 tick) public view returns (IPool.BinState[] memory bins) {
        uint8 binCounter = NUMBER_OF_KINDS;
        bins = new IPool.BinState[](binCounter);
        for (uint8 i = 0; i < NUMBER_OF_KINDS; i++) {
            uint128 binId = pool.binPositions(tick, i);
            if (binId != 0) {
                IPool.BinState memory bin = pool.getBin(binId);
                bins[NUMBER_OF_KINDS - binCounter] = bin;
                binCounter--;
            }
        }
        if (binCounter != 0) {
            assembly {
                mstore(bins, sub(mload(bins), binCounter))
            }
        }
    }

    function tickLiquidity(IPool pool, int32 tick) public view returns (uint256 sqrtPrice, uint256 liquidity, uint256 reserveA, uint256 reserveB) {
        uint256 tickSpacing = pool.tickSpacing();
        IPool.BinState[] memory bins = getBinsAtTick(pool, tick);
        for (uint256 i; i < bins.length; i++) {
            IPool.BinState memory bin = bins[i];
            reserveA += bin.reserveA;
            reserveB += bin.reserveB;
        }
        (sqrtPrice, liquidity) = Math.getTickSqrtPriceAndL(reserveA, reserveB, Math.tickSqrtPrice(tickSpacing, tick), Math.tickSqrtPrice(tickSpacing, tick + 1));
    }

    function activeTickLiquidity(IPool pool) public view returns (uint256 sqrtPrice, uint256 liquidity, uint256 reserveA, uint256 reserveB) {
        int32 activeTick = pool.getState().activeTick;
        (sqrtPrice, liquidity, reserveA, reserveB) = tickLiquidity(pool, activeTick);
    }
}