// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import './Assimilators.sol';
import './Storage.sol';
import './CurveMath.sol';

import './lib/UnsafeMath64x64.sol';
import './lib/ABDKMath64x64.sol';

// importing copy paste OZ SafeMath here to avoid circular dependency + balancer version has missing funcs
import './lib/OZSafeMath.sol';

library FXSwaps {
    using ABDKMath64x64 for int128;
    using UnsafeMath64x64 for int128;
    using ABDKMath64x64 for uint256;
    using OZSafeMath for uint256;

    int128 public constant ONE = 0x10000000000000000;

    function getOriginAndTarget(
        Storage.Curve storage curve,
        address _o,
        address _t
    ) private view returns (Storage.Assimilator memory, Storage.Assimilator memory) {
        Storage.Assimilator memory o_ = curve.assimilators[_o];
        Storage.Assimilator memory t_ = curve.assimilators[_t];

        require(o_.addr != address(0), 'FxSwaps/origin-not-supported');
        require(t_.addr != address(0), 'FxSwaps/target-not-supported');

        return (o_, t_);
    }

    function viewOriginSwap(
        Storage.Curve storage curve,
        address _origin,
        address _target,
        uint256 _originAmount
    ) external view returns (uint256 tAmt_, int128 accruedFees_) {
        (Storage.Assimilator memory _o, Storage.Assimilator memory _t) = getOriginAndTarget(curve, _origin, _target);

        // explanation: no additional fees since fee calculation is in line 57
        if (_o.ix == _t.ix)
            return (Assimilators.viewRawAmount(_t.addr, Assimilators.viewNumeraireAmount(_o.addr, _originAmount)), 0);

        (
            int128 _amt,
            int128 _oGLiq,
            int128 _nGLiq,
            int128[] memory _nBals,
            int128[] memory _oBals
        ) = viewOriginSwapData(curve, _o.ix, _t.ix, _originAmount, _o.addr);

        int128 inputNumeraireAmount = _amt;

        _amt = CurveMath.calculateTrade(curve, _oGLiq, _nGLiq, _oBals, _nBals, _amt, _t.ix);

        _amt = _amt.us_mul(ONE - curve.epsilon);

        accruedFees_ = inputNumeraireAmount.sub(_amt.abs());

        // total amount gets converted to output token amount
        tAmt_ = Assimilators.viewRawAmount(_t.addr, _amt.abs());
    }

    function viewTargetSwap(
        Storage.Curve storage curve,
        address _origin,
        address _target,
        uint256 _targetAmount
    ) external view returns (uint256 oAmt_, int128 accruedFees_) {
        (Storage.Assimilator memory _o, Storage.Assimilator memory _t) = getOriginAndTarget(curve, _origin, _target);

        // explanation: no additional fees since fee calculation is in line 73
        if (_o.ix == _t.ix)
            return (Assimilators.viewRawAmount(_o.addr, Assimilators.viewNumeraireAmount(_t.addr, _targetAmount)), 0);

        // If the origin is the quote currency (i.e. usdc)
        // we need to make sure to massage the _targetAmount
        // by dividing it by the exchange rate (so it gets
        // multiplied later to reach the same target amount).
        // Inelegant solution, but this way we don't need to
        // re-write large chunks of the code-base

        // curve.assets[1].addr = quoteCurrency
        // no variable assignment due to stack too deep
        if (curve.assets[1].addr == _o.addr) {
            _targetAmount = _targetAmount.mul(1e8).div(Assimilators.getRate(_t.addr));
        }

        (
            int128 _amt,
            int128 _oGLiq,
            int128 _nGLiq,
            int128[] memory _nBals,
            int128[] memory _oBals
        ) = viewTargetSwapData(curve, _t.ix, _o.ix, _targetAmount, _t.addr);

        // used calculations in curve.asssets[1] conditional to derive numeraire value of input amount
        int128 inputNumeraireAmount = _amt;

        _amt = CurveMath.calculateTrade(curve, _oGLiq, _nGLiq, _oBals, _nBals, _amt, _o.ix);

        // If the origin is the quote currency (i.e. usdc)
        // we need to make sure to massage the _amt too
        // curve.assets[1].addr = quoteCurrency
        // transforms it to numeraire value
        if (curve.assets[1].addr == _o.addr) {
            _amt = _amt.mul(Assimilators.getRate(_t.addr).divu(1e8));
            inputNumeraireAmount = _amt;
        }

        _amt = _amt.us_mul(ONE + curve.epsilon);

        accruedFees_ = _amt.abs().sub(inputNumeraireAmount.abs());

        // total amount gets converted to output token amount
        oAmt_ = Assimilators.viewRawAmount(_o.addr, _amt);
    }

    function viewTargetSwapData(
        Storage.Curve storage curve,
        uint256 _inputIx,
        uint256 _outputIx,
        uint256 _amt,
        address _assim
    )
        private
        view
        returns (
            int128 amt_,
            int128 oGLiq_,
            int128 nGLiq_,
            int128[] memory,
            int128[] memory
        )
    {
        uint256 _length = curve.assets.length;
        int128[] memory nBals_ = new int128[](_length);
        int128[] memory oBals_ = new int128[](_length);

        for (uint256 i = 0; i < _length; i++) {
            if (i != _inputIx) {
                nBals_[i] = oBals_[i] = _viewNumeraireBalance(curve, i);
            } else {
                int128 _bal;
                (amt_, _bal) = _viewNumeraireAmountAndBalance(curve, _assim, _amt);
                amt_ = amt_.neg();

                oBals_[i] = _bal;
                nBals_[i] = _bal.add(amt_);
            }

            oGLiq_ += oBals_[i];
            nGLiq_ += nBals_[i];
        }

        nGLiq_ = nGLiq_.sub(amt_);
        nBals_[_outputIx] = ABDKMath64x64.sub(nBals_[_outputIx], amt_);

        return (amt_, oGLiq_, nGLiq_, nBals_, oBals_);
    }

    function viewOriginSwapData(
        Storage.Curve storage curve,
        uint256 _inputIx,
        uint256 _outputIx,
        uint256 _amt,
        address _assim
    )
        private
        view
        returns (
            int128 amt_,
            int128 oGLiq_,
            int128 nGLiq_,
            int128[] memory,
            int128[] memory
        )
    {
        uint256 _length = curve.assets.length;
        int128[] memory nBals_ = new int128[](_length);
        int128[] memory oBals_ = new int128[](_length);

        for (uint256 i = 0; i < _length; i++) {
            if (i != _inputIx) {
                nBals_[i] = oBals_[i] = _viewNumeraireBalance(curve, i);
            } else {
                int128 _bal;
                (amt_, _bal) = _viewNumeraireAmountAndBalance(curve, _assim, _amt);

                oBals_[i] = _bal;
                nBals_[i] = _bal.add(amt_);
            }

            oGLiq_ += oBals_[i];
            nGLiq_ += nBals_[i];
        }

        nGLiq_ = nGLiq_.sub(amt_);
        nBals_[_outputIx] = ABDKMath64x64.sub(nBals_[_outputIx], amt_);

        return (amt_, oGLiq_, nGLiq_, nBals_, oBals_);
    }

    // internal function to avoid stack too deep
    function _viewNumeraireBalance(Storage.Curve storage curve, uint256 index) internal view returns (int128) {
        return Assimilators.viewNumeraireBalance(curve.assets[index].addr, address(curve.vault), curve.poolId);
    }

    // internal function to avoid stack too deep
    function _viewNumeraireAmountAndBalance(
        Storage.Curve storage curve,
        address _assim,
        uint256 _amt
    ) internal view returns (int128 amt_, int128 bal_) {
        return Assimilators.viewNumeraireAmountAndBalance(_assim, _amt, address(curve.vault), curve.poolId);
    }
}