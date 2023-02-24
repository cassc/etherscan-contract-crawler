// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IInsuranceFund} from "./IInsuranceFund.sol";
import {Decimal} from "../utils/Decimal.sol";
import {SignedDecimal} from "../utils/SignedDecimal.sol";
import {IAmm} from "./IAmm.sol";

interface IClearingHouse {
    //
    // Struct and Enum
    //

    enum Side {
        BUY,
        SELL
    }

    enum PnlCalcOption {
        SPOT_PRICE,
        TWAP,
        ORACLE
    }

    /// @param MAX_PNL most beneficial way for traders to calculate position notional
    /// @param MIN_PNL least beneficial way for traders to calculate position notional
    enum PnlPreferenceOption {
        MAX_PNL,
        MIN_PNL
    }

    /// @notice This struct records personal position information
    /// @param size denominated in amm.baseAsset
    /// @param margin isolated margin
    /// @param openNotional the quoteAsset value of position when opening position. the cost of the position
    /// @param lastUpdatedCumulativePremiumFraction for calculating funding payment, record at the moment every time when trader open/reduce/close position
    /// @param liquidityHistoryIndex
    /// @param blockNumber the block number of the last position
    struct Position {
        SignedDecimal.signedDecimal size;
        Decimal.decimal margin;
        Decimal.decimal openNotional;
        SignedDecimal.signedDecimal lastUpdatedCumulativePremiumFraction;
        uint256 liquidityHistoryIndex;
        uint256 blockNumber;
    }

    function addMargin(IAmm _amm, Decimal.decimal calldata _addedMargin)
        external;

    function removeMargin(IAmm _amm, Decimal.decimal calldata _removedMargin)
        external;

    function settlePosition(IAmm _amm) external;

    function openPosition(
        IAmm _amm,
        Side _side,
        Decimal.decimal calldata _quoteAssetAmount,
        Decimal.decimal calldata _leverage,
        Decimal.decimal calldata _baseAssetAmountLimit
    )
        external
        returns (
            SignedDecimal.signedDecimal memory exchangedPositionSize,
            Decimal.decimal memory exchangedQuoteAmount
        );

    function closePosition(
        IAmm _amm,
        Decimal.decimal calldata _quoteAssetAmountLimit
    )
        external
        returns (
            SignedDecimal.signedDecimal memory exchangedPositionSize,
            Decimal.decimal memory exchangedQuoteAmount
        );

    function closePartialPosition(
        IAmm _amm,
        Decimal.decimal memory _percentage,
        Decimal.decimal memory _quoteAssetAmountLimit
    )
        external
        returns (
            SignedDecimal.signedDecimal memory exchangedPositionSize,
            Decimal.decimal memory exchangedQuoteAmount
        );

    function liquidate(IAmm _amm, address _trader) external;

    function payFunding(IAmm _amm) external;

    // VIEW FUNCTIONS
    function getMarginRatio(IAmm _amm, address _trader)
        external
        view
        returns (SignedDecimal.signedDecimal memory);

    function getPosition(IAmm _amm, address _trader)
        external
        view
        returns (Position memory);

    function getPositionNotionalAndUnrealizedPnl(
        IAmm _amm,
        address _trader,
        PnlCalcOption _pnlCalcOption
    )
        external
        view
        returns (
            Decimal.decimal memory positionNotional,
            SignedDecimal.signedDecimal memory unrealizedPnl
        );

    function getLatestCumulativePremiumFraction(IAmm _amm)
        external
        view
        returns (SignedDecimal.signedDecimal memory);

    function quoteToken() external view returns (IERC20);

    function insuranceFund() external view returns (IInsuranceFund);

    function calcFee(Decimal.decimal calldata _quoteAssetAmount)
        external
        view
        returns (Decimal.decimal memory);
}