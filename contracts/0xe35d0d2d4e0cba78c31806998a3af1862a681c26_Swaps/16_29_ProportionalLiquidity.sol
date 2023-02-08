// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./Assimilators.sol";

import "./Storage.sol";

import "./lib/UnsafeMath64x64.sol";
import "./lib/ABDKMath64x64.sol";

import "./CurveMath.sol";
import "./Structs.sol";

library ProportionalLiquidity {
    using ABDKMath64x64 for uint256;
    using ABDKMath64x64 for int128;
    using UnsafeMath64x64 for int128;

    event Transfer(address indexed from, address indexed to, uint256 value);

    int128 public constant ONE = 0x10000000000000000;
    int128 public constant ONE_WEI = 0x12;

    function proportionalDeposit(Storage.Curve storage curve, DepositData memory depositData)
        external
        returns (uint256 curves_, uint256[] memory)
    {
        int128 __deposit = depositData.deposits.divu(1e18);

        uint256 _length = curve.assets.length;

        uint256[] memory deposits_ = new uint256[](_length);

        (int128 _oGLiq, int128[] memory _oBals) = getGrossLiquidityAndBalancesForDeposit(curve);

        // Needed to calculate liquidity invariant
        // (int128 _oGLiqProp, int128[] memory _oBalsProp) = getGrossLiquidityAndBalances(curve);

        // No liquidity, oracle sets the ratio
        if (_oGLiq == 0) {
            for (uint256 i = 0; i < _length; i++) {
                // Variable here to avoid stack-too-deep errors
                int128 _d = __deposit.mul(curve.weights[i]);
                deposits_[i] = Assimilators.intakeNumeraire(curve.assets[i].addr, _d.add(ONE_WEI));
            }
        } else {
            // We already have an existing pool ratio
            // which must be respected
            int128 _multiplier = __deposit.div(_oGLiq);

            uint256 _baseWeight = curve.weights[0].mulu(1e18);
            uint256 _quoteWeight = curve.weights[1].mulu(1e18);

            for (uint256 i = 0; i < _length; i++) {
                IntakeNumLpRatioInfo memory info;
                info.baseWeight = _baseWeight;
                info.minBase = depositData.minBase;
                info.maxBase = depositData.maxBase;
                info.quoteWeight = _quoteWeight;
                info.minQuote = depositData.minQuote;
                info.maxQuote = depositData.maxQuote;
                info.amount = _oBals[i].mul(_multiplier).add(ONE_WEI);
                deposits_[i] = Assimilators.intakeNumeraireLPRatio(
                    curve.assets[i].addr,
                    info
                );
            }
        }

        int128 _totalShells = curve.totalSupply.divu(1e18);

        int128 _newShells = __deposit;

        if (_totalShells > 0) {
            _newShells = __deposit.mul(_totalShells);
            _newShells = _newShells.div(_oGLiq);
        }

        require(_newShells > 0, "Proportional Liquidity/can't mint negative amount");
        mint(curve, msg.sender, curves_ = _newShells.mulu(1e18));

        return (curves_, deposits_);
    }

    function viewProportionalDeposit(Storage.Curve storage curve, uint256 _deposit)
        external
        view
        returns (uint256 curves_, uint256[] memory)
    {
        int128 __deposit = _deposit.divu(1e18);

        uint256 _length = curve.assets.length;

        (int128 _oGLiq, int128[] memory _oBals) = getGrossLiquidityAndBalancesForDeposit(curve);

        uint256[] memory deposits_ = new uint256[](_length);

        // No liquidity
        if (_oGLiq == 0) {
            for (uint256 i = 0; i < _length; i++) {
                deposits_[i] = Assimilators.viewRawAmount(
                    curve.assets[i].addr,
                    __deposit.mul(curve.weights[i]).add(ONE_WEI)
                );
            }
        } else {
            // We already have an existing pool ratio
            // this must be respected
            int128 _multiplier = __deposit.div(_oGLiq);

            uint256 _baseWeight = curve.weights[0].mulu(1e18);
            uint256 _quoteWeight = curve.weights[1].mulu(1e18);

            // Deposits into the pool is determined by existing LP ratio
            for (uint256 i = 0; i < _length; i++) {
                deposits_[i] = Assimilators.viewRawAmountLPRatio(
                    curve.assets[i].addr,
                    _baseWeight,
                    _quoteWeight,
                    _oBals[i].mul(_multiplier).add(ONE_WEI)
                );
            }
        }

        int128 _totalShells = curve.totalSupply.divu(1e18);

        int128 _newShells = __deposit;

        if (_totalShells > 0) {
            _newShells = __deposit.mul(_totalShells);
            _newShells = _newShells.div(_oGLiq);
        }

        curves_ = _newShells.mulu(1e18);

        return (curves_, deposits_);
    }

    function proportionalWithdraw(Storage.Curve storage curve, uint256 _withdrawal)
        external
        returns (uint256[] memory)
    {
        uint256 _length = curve.assets.length;

        (, int128[] memory _oBals) = getGrossLiquidityAndBalances(curve);

        uint256[] memory withdrawals_ = new uint256[](_length);

        int128 _totalShells = curve.totalSupply.divu(1e18);
        int128 __withdrawal = _withdrawal.divu(1e18);

        int128 _multiplier = __withdrawal.div(_totalShells);

        for (uint256 i = 0; i < _length; i++) {
            withdrawals_[i] = Assimilators.outputNumeraire(
                curve.assets[i].addr,
                msg.sender,
                _oBals[i].mul(_multiplier)
            );
        }

        burn(curve, msg.sender, _withdrawal);

        return withdrawals_;
    }

    function viewProportionalWithdraw(Storage.Curve storage curve, uint256 _withdrawal)
        external
        view
        returns (uint256[] memory)
    {
        uint256 _length = curve.assets.length;

        (, int128[] memory _oBals) = getGrossLiquidityAndBalances(curve);

        uint256[] memory withdrawals_ = new uint256[](_length);

        int128 _multiplier = _withdrawal.divu(1e18).div(curve.totalSupply.divu(1e18));

        for (uint256 i = 0; i < _length; i++) {
            withdrawals_[i] = Assimilators.viewRawAmount(curve.assets[i].addr, _oBals[i].mul(_multiplier));
        }

        return withdrawals_;
    }

    function getGrossLiquidityAndBalancesForDeposit(Storage.Curve storage curve)
        internal
        view
        returns (int128 grossLiquidity_, int128[] memory)
    {
        uint256 _length = curve.assets.length;

        int128[] memory balances_ = new int128[](_length);
        uint256 _baseWeight = curve.weights[0].mulu(1e18);
        uint256 _quoteWeight = curve.weights[1].mulu(1e18);

        for (uint256 i = 0; i < _length; i++) {
            int128 _bal = Assimilators.viewNumeraireBalanceLPRatio(_baseWeight, _quoteWeight, curve.assets[i].addr);

            balances_[i] = _bal;
            grossLiquidity_ += _bal;
        }

        return (grossLiquidity_, balances_);
    }

    function getGrossLiquidityAndBalances(Storage.Curve storage curve)
        internal
        view
        returns (int128 grossLiquidity_, int128[] memory)
    {
        uint256 _length = curve.assets.length;

        int128[] memory balances_ = new int128[](_length);

        for (uint256 i = 0; i < _length; i++) {
            int128 _bal = Assimilators.viewNumeraireBalance(curve.assets[i].addr);

            balances_[i] = _bal;
            grossLiquidity_ += _bal;
        }

        return (grossLiquidity_, balances_);
    }

    function burn(
        Storage.Curve storage curve,
        address account,
        uint256 amount
    ) private {
        curve.balances[account] = burnSub(curve.balances[account], amount);

        curve.totalSupply = burnSub(curve.totalSupply, amount);

        emit Transfer(msg.sender, address(0), amount);
    }

    function mint(
        Storage.Curve storage curve,
        address account,
        uint256 amount
    ) private {
        uint256 minLock = 1e6;
        if (curve.totalSupply == 0) {
            require(amount > minLock, "Proportional Liquidity/amount too small!");
            uint256 toMintAmt = amount - minLock;
            // mint to lp provider
            curve.totalSupply = mintAdd(curve.totalSupply, toMintAmt);
            curve.balances[account] = mintAdd(
                curve.balances[account],
                toMintAmt
            );
            emit Transfer(address(0), msg.sender, toMintAmt);
            // mint to 0 address
            curve.totalSupply = mintAdd(curve.totalSupply, minLock);
            curve.balances[address(0)] = mintAdd(
                curve.balances[address(0)],
                minLock
            );
            emit Transfer(address(this), address(0), minLock);
        } else {
            curve.totalSupply = mintAdd(curve.totalSupply, amount);
            curve.balances[account] = mintAdd(curve.balances[account], amount);
            emit Transfer(address(0), msg.sender, amount);
        }
    }

    function mintAdd(uint256 x, uint256 y) private pure returns (uint256 z) {
        require((z = x + y) >= x, "Curve/mint-overflow");
    }

    function burnSub(uint256 x, uint256 y) private pure returns (uint256 z) {
        require((z = x - y) <= x, "Curve/burn-underflow");
    }
}