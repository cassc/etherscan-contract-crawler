//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import {IPool} from "@yield-protocol/yieldspace-tv/src/interfaces/IPool.sol";
import {YieldMath} from "@yield-protocol/yieldspace-tv/src/YieldMath.sol";

import {StorageLib, YieldStorageLib} from "../../libraries/StorageLib.sol";
import {InvalidInstrument} from "../../libraries/ErrorLib.sol";
import {Instrument, Symbol, PositionId, YieldInstrument} from "../../libraries/DataTypes.sol";

library YieldUtils {
    uint32 internal constant MATURITY_2212 = 1672412400;

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

    /// 🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈🙈
    function cap(function() view external returns (uint128) f) internal view returns (uint128) {
        uint128 liquidity;

        // TODO Remove after Dec 2022
        IPool pool = IPool(f.address);
        uint32 maturity = pool.maturity();
        if (maturity == MATURITY_2212 && block.chainid == 1) {
            if (f.selector == IPool.maxFYTokenOut.selector) {
                liquidity = _maxFYTokenOut(pool, maturity);
            } else if (f.selector == IPool.maxFYTokenIn.selector) {
                liquidity = _maxFYTokenIn(pool, maturity);
            } else if (f.selector == IPool.maxBaseOut.selector) {
                liquidity = _maxBaseOut(pool);
            } else if (f.selector == IPool.maxBaseIn.selector) {
                liquidity = _maxBaseIn(pool, maturity);
            }
        } else {
            liquidity = _safeCall(f);
        }

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

    function sellFYTokenPreviewFixed(IPool pool, uint128 fyTokenIn) internal view returns (uint128 baseOut) {
        baseOut = pool.sellFYTokenPreview(fyTokenIn);
        // TODO Remove after Dec 2022
        if (block.chainid == 1 && pool.maturity() == MATURITY_2212) {
            baseOut = uint128(pool.unwrapPreview(baseOut));
        }
    }

    function buyFYTokenPreviewFixed(IPool pool, uint128 fyTokenOut) internal view returns (uint128 baseIn) {
        baseIn = buyFYTokenPreviewZero(pool, fyTokenOut);
        // Math is not exact anymore with the PoolEuler, so we need to transfer a bit more to the pool
        if (baseIn > 0) {
            baseIn++;
        }
    }

    function buyFYTokenPreviewZero(IPool pool, uint128 fyTokenOut) internal view returns (uint128 baseIn) {
        if (fyTokenOut == 0) {
            return 0;
        }
        baseIn = pool.buyFYTokenPreview(fyTokenOut);
    }

    function sellBasePreviewZero(IPool pool, uint128 baseIn) internal view returns (uint128 fyTokenOut) {
        if (baseIn == 0) {
            return 0;
        }
        fyTokenOut = pool.sellBasePreview(baseIn);
    }

    // TODO all of this should die after Dec 2022
    function _safeCall(function() view external returns (uint128) f) private view returns (uint128) {
        try f() returns (uint128 liquidity) {
            return liquidity;
        } catch (bytes memory) /*lowLevelData*/ {
            return 0;
        }
    }

    function _maxFYTokenIn(IPool pool, uint32 maturity) internal view returns (uint128) {
        (uint96 scaleFactor, uint128 timeTillMaturity, uint128 sharesCached, uint128 fyTokenCached) =
            _reserves(pool, maturity);
        try YieldMath.maxFYTokenIn(
            sharesCached, fyTokenCached, timeTillMaturity, pool.ts(), pool.g2(), pool.getC(), pool.mu()
        ) returns (uint128 fyTokenIn) {
            return fyTokenIn / scaleFactor;
        } catch (bytes memory) /*lowLevelData*/ {
            return 0;
        }
    }

    function _maxFYTokenOut(IPool pool, uint32 maturity) internal view returns (uint128) {
        (uint96 scaleFactor, uint128 timeTillMaturity, uint128 sharesCached, uint128 fyTokenCached) =
            _reserves(pool, maturity);
        try YieldMath.maxFYTokenOut(
            sharesCached, fyTokenCached, timeTillMaturity, pool.ts(), pool.g1(), pool.getC(), pool.mu()
        ) returns (uint128 fyTokenOut) {
            return fyTokenOut / scaleFactor;
        } catch (bytes memory) /*lowLevelData*/ {
            return 0;
        }
    }

    function _maxBaseIn(IPool pool, uint32 maturity) internal view returns (uint128 baseIn) {
        (uint96 scaleFactor, uint128 timeTillMaturity, uint128 sharesCached, uint128 fyTokenCached) =
            _reserves(pool, maturity);
        try YieldMath.maxSharesIn(
            sharesCached, fyTokenCached, timeTillMaturity, pool.ts(), pool.g1(), pool.getC(), pool.mu()
        ) returns (uint128 sharesIn) {
            baseIn = uint128(pool.unwrapPreview(sharesIn / scaleFactor));
        } catch (bytes memory) /*lowLevelData*/ {
            return 0;
        }
    }

    function _maxBaseOut(IPool pool) internal view returns (uint128 baseOut) {
        (uint104 sharesOut,,,) = pool.getCache();
        baseOut = uint128(pool.unwrapPreview(sharesOut));
    }

    function _reserves(IPool pool, uint32 maturity)
        private
        view
        returns (uint96 scaleFactor, uint128 timeTillMaturity, uint128 sharesCached, uint128 fyTokenCached)
    {
        timeTillMaturity = maturity - uint32(block.timestamp);
        scaleFactor = pool.scaleFactor();
        (uint104 _sharesCached, uint104 _fyTokenCached,,) = pool.getCache();

        sharesCached = _sharesCached * scaleFactor;
        fyTokenCached = _fyTokenCached * scaleFactor;
    }
}