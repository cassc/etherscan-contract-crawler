// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IPool} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IPool.sol";
import {Math as MavMath} from "./libraries/Math.sol";
import {IPositionInspector} from "./interfaces/IPositionInspector.sol";

contract PositionInspector is IPositionInspector {
    /// @dev The tick and merge states of a bin are not modified before the
    //swap callback is called inside of a pool when a user calls swap. This was
    //an intentional design decision that makes it easier for aggregators to
    //project the price of a swap without having to know the precise time of
    //the swap. But one implication of this decision is that the binstate in
    //the callback and after the swap may differ.  In many cases, it is not
    //desirable to have users values read from inside of a callback because
    //a user may get unpredictable results.  When using the functions in this
    //contract for an integration, it is best practice to not allow users to
    //call your integration from inside of the swap callback. The
    //IPool.getState().status field indicates whether the pool is in a
    //reentrancy lock status if that status value is 1.  When using functions
    //from this contract in an integration that can be used by outside users,
    //consider checking to ensure the status of the pool is != 1 before
    //allowing a user to interact with your integration.  This will prevent the
    //user from calling your integration from inside of a swap callback.
    //
    // Example check to be added to integrations using this contract:
    //
    // if (pool.getState().status == 1) revert;
    //

    uint8 constant KIND_ALL = 4;

    function lpBalanceInActive(
        uint256 tokenId,
        uint128 binId,
        uint256 prevBalance,
        IPool pool,
        uint8 kindToKeep
    ) internal view returns (uint256 balance, uint128 activeBin, uint256 amountA, uint256 amountB) {
        IPool.BinState memory bin = pool.getBin(binId);

        if (kindToKeep == KIND_ALL || kindToKeep == bin.kind) {
            if (bin.mergeId != 0) {
                return lpBalanceInActive(tokenId, bin.mergeId, Math.mulDiv(prevBalance, bin.mergeBinBalance, bin.totalSupply), pool, kindToKeep);
            }
            balance = prevBalance;
            activeBin = binId;
            amountA = Math.mulDiv(balance, bin.reserveA, bin.totalSupply);
            amountB = Math.mulDiv(balance, bin.reserveB, bin.totalSupply);
        }
    }

    function tokenBinReserves(uint256 tokenId, IPool pool, uint128 startBin, uint128 endBin) public view returns (uint256 amountA, uint256 amountB) {
        uint128 binCounter = pool.getState().binCounter;
        binCounter = endBin < binCounter ? endBin : binCounter;

        for (uint128 i = startBin; i <= binCounter; i++) {
            uint256 lpBalance = pool.balanceOf(tokenId, i);
            if (lpBalance != 0) {
                (, , uint256 A, uint256 B) = lpBalanceInActive(tokenId, i, lpBalance, pool, KIND_ALL);
                amountA += A;
                amountB += B;
            }
        }
        amountA = MavMath.toScale(amountA, pool.tokenAScale(), false);
        amountB = MavMath.toScale(amountB, pool.tokenBScale(), false);
    }

    function tokenBinReserves(uint256 tokenId, IPool pool, uint128 startBin, uint128 endBin, uint8 kind) public view returns (uint256 amountA, uint256 amountB) {
        uint128 binCounter = pool.getState().binCounter;
        binCounter = endBin < binCounter ? endBin : binCounter;

        uint256 lpBalance;
        for (uint128 i = startBin; i <= binCounter; i++) {
            lpBalance = pool.balanceOf(tokenId, i);
            if (lpBalance != 0) {
                (, , uint256 A, uint256 B) = lpBalanceInActive(tokenId, i, lpBalance, pool, kind);
                amountA += A;
                amountB += B;
            }
        }
        amountA = MavMath.toScale(amountA, pool.tokenAScale(), false);
        amountB = MavMath.toScale(amountB, pool.tokenBScale(), false);
    }

    function tokenBinReserves(uint256 tokenId, IPool pool, uint128[] memory userBins) public view returns (uint256 amountA, uint256 amountB) {
        uint256 length = userBins.length;
        for (uint128 i; i < length; i++) {
            uint128 binId = userBins[i];
            uint256 lpBalance = pool.balanceOf(tokenId, binId);
            if (lpBalance != 0) {
                (, , uint256 A, uint256 B) = lpBalanceInActive(tokenId, binId, lpBalance, pool, KIND_ALL);
                amountA += A;
                amountB += B;
            }
        }
        amountA = MavMath.toScale(amountA, pool.tokenAScale(), false);
        amountB = MavMath.toScale(amountB, pool.tokenBScale(), false);
    }
}