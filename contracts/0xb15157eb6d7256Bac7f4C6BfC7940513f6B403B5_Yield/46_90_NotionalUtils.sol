//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {Constants} from "./internal/Constants.sol";
import {NotionalProxy} from "./internal/interfaces/NotionalProxy.sol";

import {Instrument, NotionalInstrument, Symbol} from "../../libraries/DataTypes.sol";
import {InvalidInstrument} from "../../libraries/ErrorLib.sol";
import {MathLib} from "../../libraries/MathLib.sol";
import {NotionalStorageLib, StorageLib} from "../../libraries/StorageLib.sol";

import {ContangoVault} from "./ContangoVault.sol";

library NotionalUtils {
    using MathLib for uint256;
    using NotionalUtils for uint256;
    using SafeCast for uint256;

    uint256 private constant NOTIONAL_PRECISION = uint256(Constants.INTERNAL_TOKEN_PRECISION);

    function loadInstrument(Symbol symbol)
        internal
        view
        returns (Instrument storage instrument, NotionalInstrument storage notionalInstrument, ContangoVault vault)
    {
        instrument = StorageLib.getInstruments()[symbol];
        if (instrument.maturity == 0) {
            revert InvalidInstrument(symbol);
        }
        notionalInstrument = NotionalStorageLib.getInstruments()[symbol];
        vault = NotionalStorageLib.getVaults()[symbol];
    }

    function quoteLendOpenCost(
        NotionalProxy notional,
        uint256 fCashAmount,
        Instrument memory instrument,
        NotionalInstrument memory notionalInstrument
    ) internal view returns (uint256 deposit) {
        (deposit,,,) = notional.getDepositFromfCashLend({
            currencyId: notionalInstrument.baseId,
            fCashAmount: fCashAmount,
            maturity: instrument.maturity,
            minLendRate: 0, // no limit
            blockTime: block.timestamp // solhint-disable-line not-rely-on-time
        });
    }

    function quoteLendClose(
        NotionalProxy notional,
        uint256 fCashAmount,
        Instrument memory instrument,
        NotionalInstrument memory notionalInstrument
    ) internal view returns (uint256 principal) {
        (principal,,,) = notional.getPrincipalFromfCashBorrow({
            currencyId: notionalInstrument.baseId,
            fCashBorrow: fCashAmount,
            maturity: instrument.maturity,
            maxBorrowRate: 0, // no limit
            blockTime: block.timestamp // solhint-disable-line not-rely-on-time
        });
    }

    function quoteBorrowOpenCost(
        NotionalProxy notional,
        uint256 borrow,
        Instrument memory instrument,
        NotionalInstrument memory notionalInstrument
    ) internal view returns (uint88 fCashAmount) {
        (fCashAmount,,) = notional.getfCashBorrowFromPrincipal({
            currencyId: notionalInstrument.quoteId,
            borrowedAmountExternal: borrow,
            maturity: instrument.maturity,
            maxBorrowRate: 0, // no limit
            blockTime: block.timestamp, // solhint-disable-line not-rely-on-time
            useUnderlying: true
        });
        // Empirically it appears that the fCash to cash exchange rate is at most 0.01 basis points (0.0001 percent)
        // amount input into the function. This is likely due to rounding errors in calculations. What you can do to
        // buffer these values is to increase the size by x += (x * 100) / 1e9 -> equivalent to x += x / 1e7
        fCashAmount += fCashAmount >= 1e8 ? fCashAmount / 1e7 : 1;
    }

    function quoteBorrowOpen(
        NotionalProxy notional,
        uint256 fCashAmount,
        Instrument memory instrument,
        NotionalInstrument memory notionalInstrument
    ) internal view returns (uint256 principal) {
        (principal,,,) = notional.getPrincipalFromfCashBorrow({
            currencyId: notionalInstrument.quoteId,
            fCashBorrow: fCashAmount,
            maturity: instrument.maturity,
            maxBorrowRate: 0, // no limit
            blockTime: block.timestamp // solhint-disable-line not-rely-on-time
        });
    }

    function quoteBorrowCloseCost(
        NotionalProxy notional,
        uint256 fCashAmount,
        Instrument memory instrument,
        NotionalInstrument memory notionalInstrument
    ) internal view returns (uint256 deposit) {
        (deposit,,,) = notional.getDepositFromfCashLend({
            currencyId: notionalInstrument.quoteId,
            fCashAmount: fCashAmount,
            maturity: instrument.maturity,
            minLendRate: 0, // no limit
            blockTime: block.timestamp // solhint-disable-line not-rely-on-time
        });
    }

    function quoteBorrowClose(
        NotionalProxy notional,
        uint256 deposit,
        Instrument memory instrument,
        NotionalInstrument memory notionalInstrument
    ) internal view returns (uint256 fCashAmount) {
        (fCashAmount,,) = notional.getfCashLendFromDeposit({
            currencyId: notionalInstrument.quoteId,
            depositAmountExternal: deposit,
            maturity: instrument.maturity,
            minLendRate: 0, // no limit
            blockTime: block.timestamp, // solhint-disable-line not-rely-on-time
            useUnderlying: true
        });
    }

    function toNotionalPrecision(uint256 value, uint256 fromPrecision, bool roundCeiling)
        internal
        pure
        returns (uint256)
    {
        return value.scale(fromPrecision, NOTIONAL_PRECISION, roundCeiling);
    }

    function fromNotionalPrecision(uint256 value, uint256 toPrecision, bool roundCeiling)
        internal
        pure
        returns (uint256)
    {
        return value.scale(NOTIONAL_PRECISION, toPrecision, roundCeiling);
    }

    function roundFloorNotionalPrecision(uint256 value, uint256 precision) internal pure returns (uint256 rounded) {
        if (precision > NOTIONAL_PRECISION) {
            rounded = value.toNotionalPrecision(precision, false).fromNotionalPrecision(precision, false);
        } else {
            rounded = value;
        }
    }
}