//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../interfaces/IPriceStrategy3.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@prb/math/contracts/PRBMathUD60x18.sol";

library AMMPriceStrategyV3 {
    using PRBMathUD60x18 for uint256;
    uint256 public constant WEI = 10**18;

    /*
     PRBMathUD60x18 works on base 18 decimal, so need to convert number to base 18 decimal first
     Remember some variable are already on base 18, some not
     */

    struct CalcParams {
        uint256 shares;
        uint256 liquid;
        uint256 totalShares;
        uint256 totalLiquid;
        uint256 deltaP;
        uint256 deltaP2;
        uint256 p31;
        uint256 p32;
        uint256 p33;
        uint256 p41;
        uint256 p42;
        uint256 p43;
        uint256 price;
    }

    /*

    */

    function openPrice(IPriceStrategy3.PriceParams memory _priceParams)
        external
        view
        returns (uint256 price)
    {
        price = (_priceParams.strength * WEI)
            .mul(_priceParams.num_of_teams * WEI)
            .mul(_priceParams.REF_PRICE)
            .div(_priceParams.totalStrength * WEI);
        // price = (price * _priceParams.DECIMAL) / WEI;
    }

    function calcParams(
        IPriceStrategy3.PriceParams memory _priceParams,
        bool isSell
    ) internal view returns (CalcParams memory _calcParams) {
        uint256 SLIPPAGE = (_priceParams.TOTAL_TEAMS * WEI).div(32 * WEI);

        _calcParams.shares = _priceParams.shares * WEI;
        // _calcParams.shares =
        //     (
        //         _priceParams.num_of_teams == 1
        //             ? _priceParams.shares
        //             : _priceParams.shares
        //     ) * // the first share of system
        // WEI;
        _calcParams.liquid = _priceParams.num_of_teams == 1
            ? ((_priceParams.liquid + _priceParams.liquidReserved) * WEI) /
                _priceParams.DECIMAL
            : (_priceParams.liquid * WEI) / _priceParams.DECIMAL;
        _calcParams.totalShares = _priceParams.totalShares * WEI;
        _calcParams.totalLiquid =
            ((_priceParams.totalLiquid + _priceParams.totalLiquidReserved) *
                WEI) /
            _priceParams.DECIMAL;

        // base price base on only strength - initial base price
        uint256 p0 = (_priceParams.strength * WEI)
            .mul(_priceParams.num_of_teams * WEI)
            .mul((_priceParams.REF_PRICE * WEI) / _priceParams.DECIMAL)
            .div(_priceParams.totalStrength * WEI);
        uint256 p1 = _calcParams.shares > 0
            ? _calcParams.liquid.div(_calcParams.shares)
            : p0;
        uint256 p2 = (_priceParams.totalStrength *
            WEI +
            _calcParams.totalLiquid).div(
                (_priceParams.totalStrength * WEI).div(
                    (_priceParams.REF_PRICE * WEI) / _priceParams.DECIMAL
                ) + _calcParams.totalShares
            );

        {
            uint256 deltaP_a = (_priceParams.totalStrength -
                _priceParams.strength) *
                WEI +
                _calcParams.totalLiquid -
                _calcParams.liquid;
            uint256 deltaP_b = (_priceParams.strength * WEI).div(p2) +
                _calcParams.shares;
            //            uint256 deltaP_c = (_priceParams.num_of_teams * 3 * WEI);
            //            uint256 deltaP_d = _priceParams.TOTAL_TEAMS * WEI;
            _calcParams.deltaP = deltaP_a.div(deltaP_b);
        }

        {
            uint256 p31_a = (_priceParams.strength * WEI).div(p2) +
                _calcParams.shares;
            uint256 p31_b = (_priceParams.totalStrength * WEI).div(p2) +
                _calcParams.totalShares;
            _calcParams.p31 = p31_a.mul(SLIPPAGE).div(p31_b);
        }

        {
            uint256 p32_a = _priceParams.strength * WEI + _calcParams.liquid;
            uint256 p32_b = _priceParams.totalStrength *
                WEI +
                _calcParams.totalLiquid;
            _calcParams.p32 = p32_a.div(p32_b);
        }

        {
            uint256 p33_a = _priceParams.totalStrength *
                WEI +
                _calcParams.totalLiquid;
            uint256 p33_b = _priceParams.totalStrength * WEI;
            _calcParams.p33 = p33_a.div(p33_b);
        }

        _calcParams.deltaP2 = _calcParams
            .deltaP
            .mul(_calcParams.p31)
            .mul(_calcParams.p32)
            .mul(_calcParams.p33);

        //        if (_priceParams.amount <= 0){
        //            _priceParams.amount = 1;
        //        }

        if (isSell) {
            _calcParams.p41 = 0;
            _calcParams.p42 = 0;
            _calcParams.p43 = 0;
            _calcParams.deltaP2 = _calcParams.deltaP2.mul(
                WEI - (_priceParams.amount * WEI).div(_priceParams.shares * WEI)
            );
        } else {
            {
                uint256 p41_a = (_priceParams.strength * WEI).div(p2) +
                    _calcParams.shares +
                    _priceParams.amount *
                    WEI;
                uint256 p41_b = (_priceParams.totalStrength * WEI).div(p2) +
                    _calcParams.totalShares +
                    _priceParams.amount *
                    WEI;
                _calcParams.p41 = p41_a.mul(SLIPPAGE).div(p41_b);
            }
            {
                uint256 p42_a = _priceParams.strength *
                    WEI +
                    _calcParams.liquid +
                    (_priceParams.amount * WEI).mul(p1);
                uint256 p42_b = _priceParams.totalStrength *
                    WEI +
                    _calcParams.totalLiquid +
                    (_priceParams.amount * WEI).mul(p1);
                _calcParams.p42 = p42_a.div(p42_b);
            }

            {
                uint256 p43_a = _priceParams.totalStrength *
                    WEI +
                    _calcParams.totalLiquid +
                    (_priceParams.amount * WEI).mul(p1);
                uint256 p43_b = _priceParams.totalStrength * WEI;
                _calcParams.p43 = p43_a.div(p43_b);
            }

            _calcParams.deltaP2 = _calcParams
                .deltaP
                .mul(_calcParams.p41)
                .mul(_calcParams.p42)
                .mul(_calcParams.p43);
        }

        _calcParams.price = p1 + _calcParams.deltaP2;

        return _calcParams;
    }

    function ammPriceBuy(IPriceStrategy3.PriceParams memory _priceParams)
        external
        view
        returns (uint256)
    {
        if (_priceParams.amount == 0) {
            return 0;
        }
        CalcParams memory _calcParams = calcParams(_priceParams, false);
        return
            ((_calcParams.price.mul(_priceParams.amount * WEI)) *
                _priceParams.DECIMAL) / WEI;
    }

    function ammPriceSell(IPriceStrategy3.PriceParams memory _priceParams)
        external
        view
        returns (uint256)
    {
        if (
            _priceParams.shares == 0 ||
            _priceParams.shares < _priceParams.amount
        ) {
            return 0;
        }
        if (_priceParams.amount == 0) {
            return 0;
        }

        CalcParams memory _calcParams = calcParams(_priceParams, true);

        return
            ((_calcParams.price.mul(_priceParams.amount * WEI)) *
                _priceParams.DECIMAL) / WEI;
    }
}