//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IPool} from "@yield-protocol/yieldspace-tv/src/interfaces/IPool.sol";
import "../../libraries/StorageLib.sol";
import "../../libraries/ErrorLib.sol";
import "../../libraries/DataTypes.sol";

library YieldUtils {
    function loadInstrument(Symbol symbol)
        internal
        view
        returns (Instrument storage instrument, YieldInstrument storage yieldInstrument)
    {
        instrument = StorageLib.getInstruments()[symbol];
        if (instrument.maturity == 0) {
            revert InvalidInstrument(symbol);
        }
        yieldInstrument = YieldStorageLib.getInstruments()[symbol];
    }

    function toVaultId(PositionId positionId) internal pure returns (bytes12) {
        return bytes12(uint96(PositionId.unwrap(positionId)));
    }

    /// @dev Ignores liquidity values that are too small to be useful
    function cap(function() view external returns (uint128) f) internal view returns (uint128) {
        IPool pool = IPool(f.address);
        uint128 liquidity = f();

        if (liquidity > 0) {
            uint256 scaleFactor = pool.scaleFactor();
            if (scaleFactor == 1 && liquidity <= 1e13 || scaleFactor == 1e12 && liquidity <= 1e3) {
                liquidity = 0;
            } else if (f.selector == IPool.maxFYTokenOut.selector) {
                uint128 balance = uint128(pool.fyToken().balanceOf(f.address));
                if (balance < liquidity) {
                    liquidity = balance;
                }
            }
        }

        return liquidity;
    }

    function buyFYTokenPreviewFixed(IPool pool, uint128 fyTokenOut) internal view returns (uint128 baseIn) {
        baseIn = buyFYTokenPreviewZero(pool, fyTokenOut);
        // Math is not exact anymore with the PoolEuler, so we need to transfer a bit more to the pool
        baseIn = baseIn == 0 ? 0 : baseIn + 1;
    }

    function buyFYTokenPreviewZero(IPool pool, uint128 fyTokenOut) internal view returns (uint128 baseIn) {
        baseIn = fyTokenOut == 0 ? 0 : pool.buyFYTokenPreview(fyTokenOut);
    }

    function sellBasePreviewZero(IPool pool, uint128 baseIn) internal view returns (uint128 fyTokenOut) {
        fyTokenOut = baseIn == 0 ? 0 : pool.sellBasePreview(baseIn);
    }
}