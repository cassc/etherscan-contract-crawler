// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Decimal} from "./utils/Decimal.sol";
import {SignedDecimal} from "./utils/SignedDecimal.sol";
import {MixedDecimal} from "./utils/MixedDecimal.sol";
import {IAmm} from "./interface/IAmm.sol";
import {IInsuranceFund} from "./interface/IInsuranceFund.sol";
import {ClearingHouse, IClearingHouse} from "./ClearingHouse.sol";

contract ClearingHouseViewer {
    using Decimal for Decimal.decimal;
    using SignedDecimal for SignedDecimal.signedDecimal;
    using MixedDecimal for SignedDecimal.signedDecimal;

    ClearingHouse public clearingHouse;

    //
    // FUNCTIONS
    //

    constructor(ClearingHouse _clearingHouse) {
        clearingHouse = _clearingHouse;
    }

    //
    // Public
    //

    /**
     * @notice get unrealized PnL
     * @param _amm IAmm address
     * @param _trader trader address
     * @param _pnlCalcOption IClearingHouse.PnlCalcOption, can be SPOT_PRICE or TWAP.
     * @return unrealized PnL in 18 digits
     */
    function getUnrealizedPnl(
        IAmm _amm,
        address _trader,
        IClearingHouse.PnlCalcOption _pnlCalcOption
    ) external view returns (SignedDecimal.signedDecimal memory) {
        (, SignedDecimal.signedDecimal memory unrealizedPnl) = (
            clearingHouse.getPositionNotionalAndUnrealizedPnl(
                _amm,
                _trader,
                _pnlCalcOption
            )
        );
        return unrealizedPnl;
    }

    /**
     * @notice get unrealized PnL for several users
     * @param _amm IAmm address
     * @param _traders list of trader address
     * @param _pnlCalcOption IClearingHouse.PnlCalcOption, can be SPOT_PRICE or TWAP.
     * @return unrealizedPnls unrealized PnL in 18 digits
     */
    function getUnrealizedPnlInBatch(
        IAmm _amm,
        address[] calldata _traders,
        IClearingHouse.PnlCalcOption _pnlCalcOption
    )
        external
        view
        returns (SignedDecimal.signedDecimal[] memory unrealizedPnls)
    {
        uint256 len = _traders.length;
        require(len != 0, "ClearingHouseViewer: invalid length");
        unrealizedPnls = new SignedDecimal.signedDecimal[](len);

        for (uint256 i = 0; i < len; i += 1) {
            (, unrealizedPnls[i]) = (
                clearingHouse.getPositionNotionalAndUnrealizedPnl(
                    _amm,
                    _traders[i],
                    _pnlCalcOption
                )
            );
        }
    }

    /**
     * @notice get personal balance with funding payment
     * @param _trader trader address
     * @return margin personal balance with funding payment in 18 digits
     */
    function getPersonalBalanceWithFundingPayment(address _trader)
        external
        view
        returns (Decimal.decimal memory margin)
    {
        IInsuranceFund insuranceFund = clearingHouse.insuranceFund();
        IAmm[] memory amms = insuranceFund.getAllAmms();
        for (uint256 i = 0; i < amms.length; i++) {
            Decimal.decimal
                memory posMargin = getPersonalPositionWithFundingPayment(
                    amms[i],
                    _trader
                ).margin;
            margin = margin.addD(posMargin);
        }
    }

    /**
     * @notice get personal position with funding payment
     * @param _amm IAmm address
     * @param _trader trader address
     * @return position ClearingHouse.Position struct
     */
    function getPersonalPositionWithFundingPayment(IAmm _amm, address _trader)
        public
        view
        returns (ClearingHouse.Position memory position)
    {
        position = clearingHouse.getPosition(_amm, _trader);
        SignedDecimal.signedDecimal
            memory marginWithFundingPayment = MixedDecimal
                .fromDecimal(position.margin)
                .addD(
                    getFundingPayment(
                        position,
                        clearingHouse.getLatestCumulativePremiumFraction(_amm)
                    )
                );
        position.margin = marginWithFundingPayment.toInt() >= 0
            ? marginWithFundingPayment.abs()
            : Decimal.zero();
    }

    /**
     * @notice verify if trader's position needs to be migrated
     * @param _amm IAmm address
     * @param _trader trader address
     * @return true if trader's position is not at the latest Amm curve, otherwise is false
     */
    function isPositionNeedToBeMigrated(IAmm _amm, address _trader)
        external
        view
        returns (bool)
    {
        ClearingHouse.Position memory unadjustedPosition = clearingHouse
            .getPosition(_amm, _trader);
        if (unadjustedPosition.size.toInt() == 0) {
            return false;
        }
        uint256 latestLiquidityIndex = _amm.getLiquidityHistoryLength() - 1;
        if (unadjustedPosition.liquidityHistoryIndex == latestLiquidityIndex) {
            return false;
        }
        return true;
    }

    /**
     * @notice get personal margin ratio
     * @param _amm IAmm address
     * @param _trader trader address
     * @return personal margin ratio in 18 digits
     */
    function getMarginRatio(IAmm _amm, address _trader)
        external
        view
        returns (SignedDecimal.signedDecimal memory)
    {
        return clearingHouse.getMarginRatio(_amm, _trader);
    }

    /**
     * @notice get personal margin ratio for multiple users
     * @param _amm IAmm address
     * @param _traders list of trader address
     * @return marginRatios personal margin ratio in 18 digits
     */
    function getMarginRatioInBatch(IAmm _amm, address[] calldata _traders)
        external
        view
        returns (SignedDecimal.signedDecimal[] memory marginRatios)
    {
        uint256 len = _traders.length;
        marginRatios = new SignedDecimal.signedDecimal[](len);
        for (uint256 i = 0; i < len; i += 1) {
            ClearingHouse.Position memory position = clearingHouse.getPosition(
                _amm,
                _traders[i]
            );
            if (position.size.toInt() != 0) {
                marginRatios[i] = clearingHouse.getMarginRatio(
                    _amm,
                    _traders[i]
                );
            }
        }
    }

    /**
     * @notice get withdrawable margin
     * @param _amm IAmm address
     * @param _trader trader address
     * @return withdrawable margin in 18 digits
     */
    function getFreeCollateral(IAmm _amm, address _trader)
        external
        view
        returns (SignedDecimal.signedDecimal memory)
    {
        // get trader's margin
        ClearingHouse.Position
            memory position = getPersonalPositionWithFundingPayment(
                _amm,
                _trader
            );

        // get trader's unrealized PnL and choose the least beneficial one for the trader
        (
            Decimal.decimal memory spotPositionNotional,
            SignedDecimal.signedDecimal memory spotPricePnl
        ) = (
                clearingHouse.getPositionNotionalAndUnrealizedPnl(
                    _amm,
                    _trader,
                    IClearingHouse.PnlCalcOption.SPOT_PRICE
                )
            );
        (
            Decimal.decimal memory twapPositionNotional,
            SignedDecimal.signedDecimal memory twapPricePnl
        ) = (
                clearingHouse.getPositionNotionalAndUnrealizedPnl(
                    _amm,
                    _trader,
                    IClearingHouse.PnlCalcOption.TWAP
                )
            );

        SignedDecimal.signedDecimal memory unrealizedPnl;
        Decimal.decimal memory positionNotional;
        (unrealizedPnl, positionNotional) = (spotPricePnl.toInt() >
            twapPricePnl.toInt())
            ? (twapPricePnl, twapPositionNotional)
            : (spotPricePnl, spotPositionNotional);

        // min(margin + funding, margin + funding + unrealized PnL) - position value * initMarginRatio
        SignedDecimal.signedDecimal memory accountValue = unrealizedPnl.addD(
            position.margin
        );
        SignedDecimal.signedDecimal memory minCollateral = accountValue
            .subD(position.margin)
            .toInt() > 0
            ? MixedDecimal.fromDecimal(position.margin)
            : accountValue;

        Decimal.decimal memory initMarginRatio = Decimal.decimal(
            clearingHouse.initMarginRatio()
        );
        SignedDecimal.signedDecimal memory marginRequirement = position
            .size
            .toInt() > 0
            ? MixedDecimal.fromDecimal(position.openNotional).mulD(
                initMarginRatio
            )
            : MixedDecimal.fromDecimal(positionNotional).mulD(initMarginRatio);

        return minCollateral.subD(marginRequirement);
    }

    //
    // PRIVATE
    //

    // negative means trader paid and vice versa
    function getFundingPayment(
        ClearingHouse.Position memory _position,
        SignedDecimal.signedDecimal memory _latestCumulativePremiumFraction
    ) private pure returns (SignedDecimal.signedDecimal memory) {
        return
            _position.size.toInt() == 0
                ? SignedDecimal.zero()
                : _latestCumulativePremiumFraction
                    .subD(_position.lastUpdatedCumulativePremiumFraction)
                    .mulD(_position.size)
                    .mulScalar(-1);
    }
}