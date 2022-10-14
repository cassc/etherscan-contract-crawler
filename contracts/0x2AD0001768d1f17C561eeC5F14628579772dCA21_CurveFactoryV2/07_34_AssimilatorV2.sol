// SPDX-License-Identifier: MIT

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.13;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

import "../lib/ABDKMath64x64.sol";
import "../interfaces/IAssimilator.sol";
import "../interfaces/IOracle.sol";

contract AssimilatorV2 is IAssimilator {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private constant usdc = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

    IOracle private immutable oracle;
    IERC20 private immutable token;
    uint256 private immutable oracleDecimals;
    uint256 private immutable tokenDecimals;

    // solhint-disable-next-line
    constructor(
        IOracle _oracle,
        address _token,
        uint256 _tokenDecimals,
        uint256 _oracleDecimals
    ) {
        oracle = _oracle;
        token = IERC20(_token);
        oracleDecimals = _oracleDecimals;
        tokenDecimals = _tokenDecimals;
    }

    function getRate() public view override returns (uint256) {
        (, int256 price, , , ) = oracle.latestRoundData();
        return uint256(price);
    }

    // takes raw eurs amount, transfers it in, calculates corresponding numeraire amount and returns it
    function intakeRawAndGetBalance(uint256 _amount) external override returns (int128 amount_, int128 balance_) {
        token.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 _balance = token.balanceOf(address(this));

        uint256 _rate = getRate();

        balance_ = ((_balance * _rate) / 10**oracleDecimals).divu(10**tokenDecimals);

        amount_ = ((_amount * _rate) / 10**oracleDecimals).divu(10**tokenDecimals);
    }

    // takes raw eurs amount, transfers it in, calculates corresponding numeraire amount and returns it
    function intakeRaw(uint256 _amount) external override returns (int128 amount_) {
        token.safeTransferFrom(msg.sender, address(this), _amount);
        
        uint256 _rate = getRate();

        amount_ = ((_amount * _rate) / 10**oracleDecimals).divu(10**tokenDecimals);
    }

    // takes a numeraire amount, calculates the raw amount of eurs, transfers it in and returns the corresponding raw amount
    function intakeNumeraire(int128 _amount) external override returns (uint256 amount_) {
        uint256 _rate = getRate();

        amount_ = (_amount.mulu(10**tokenDecimals) * 10**oracleDecimals) / _rate;

        token.safeTransferFrom(msg.sender, address(this), amount_);
    }

    // takes a numeraire amount, calculates the raw amount of eurs, transfers it in and returns the corresponding raw amount
    function intakeNumeraireLPRatio(
        uint256 _baseWeight,
        uint256 _quoteWeight,
        address _addr,
        int128 _amount
    ) external override returns (uint256 amount_) {
        uint256 _tokenBal = token.balanceOf(_addr);

        if (_tokenBal <= 0) return 0;

        _tokenBal = _tokenBal.mul(1e18).div(_baseWeight);

        uint256 _usdcBal = usdc.balanceOf(_addr).mul(1e18).div(_quoteWeight);

        // Rate is in 1e6
        uint256 _rate = _usdcBal.mul(10**tokenDecimals).div(_tokenBal);

        amount_ = (_amount.mulu(10**tokenDecimals) * 1e6) / _rate;

        token.safeTransferFrom(msg.sender, address(this), amount_);
    }

    // takes a raw amount of eurs and transfers it out, returns numeraire value of the raw amount
    function outputRawAndGetBalance(address _dst, uint256 _amount)
        external
        override
        returns (int128 amount_, int128 balance_)
    {
        uint256 _rate = getRate();

        uint256 _tokenAmount = ((_amount) * _rate) / 10**oracleDecimals;

        token.safeTransfer(_dst, _tokenAmount);

        uint256 _balance = token.balanceOf(address(this));

        amount_ = _tokenAmount.divu(10**tokenDecimals);

        balance_ = ((_balance * _rate) / 10**oracleDecimals).divu(10**tokenDecimals);
    }

    // takes a raw amount of eurs and transfers it out, returns numeraire value of the raw amount
    function outputRaw(address _dst, uint256 _amount) external override returns (int128 amount_) {
        uint256 _rate = getRate();

        uint256 _tokenAmount = (_amount * _rate) / 10**oracleDecimals;

        token.safeTransfer(_dst, _tokenAmount);

        amount_ = _tokenAmount.divu(10**tokenDecimals);
    }

    // takes a numeraire value of eurs, figures out the raw amount, transfers raw amount out, and returns raw amount
    function outputNumeraire(address _dst, int128 _amount) external override returns (uint256 amount_) {
        uint256 _rate = getRate();

        amount_ = (_amount.mulu(10**tokenDecimals) * 10**oracleDecimals) / _rate;

        token.safeTransfer(_dst, amount_);
    }

    // takes a numeraire amount and returns the raw amount
    function viewRawAmount(int128 _amount) external view override returns (uint256 amount_) {
        uint256 _rate = getRate();

        amount_ = (_amount.mulu(10**tokenDecimals) * 10**oracleDecimals) / _rate;
    }

    function viewRawAmountLPRatio(
        uint256 _baseWeight,
        uint256 _quoteWeight,
        address _addr,
        int128 _amount
    ) external view override returns (uint256 amount_) {
        uint256 _tokenBal = token.balanceOf(_addr);

        if (_tokenBal <= 0) return 0;

        // 1e2
        _tokenBal = _tokenBal.mul(1e18).div(_baseWeight);

        // 1e6
        uint256 _usdcBal = usdc.balanceOf(_addr).mul(1e18).div(_quoteWeight);

        // Rate is in 1e6
        uint256 _rate = _usdcBal.mul(10**tokenDecimals).div(_tokenBal);

        amount_ = (_amount.mulu(10**tokenDecimals) * 1e6) / _rate;
    }

    // takes a raw amount and returns the numeraire amount
    function viewNumeraireAmount(uint256 _amount) external view override returns (int128 amount_) {
        uint256 _rate = getRate();

        amount_ = ((_amount * _rate) / 10**oracleDecimals).divu(10**tokenDecimals);
    }

    // views the numeraire value of the current balance of the reserve, in this case eurs
    function viewNumeraireBalance(address _addr) external view override returns (int128 balance_) {
        uint256 _rate = getRate();

        uint256 _balance = token.balanceOf(_addr);

        if (_balance <= 0) return ABDKMath64x64.fromUInt(0);

        balance_ = ((_balance * _rate) / 10**oracleDecimals).divu(10**tokenDecimals);
    }

    // views the numeraire value of the current balance of the reserve, in this case eurs
    function viewNumeraireAmountAndBalance(address _addr, uint256 _amount)
        external
        view
        override
        returns (int128 amount_, int128 balance_)
    {
        uint256 _rate = getRate();

        amount_ = ((_amount * _rate) / 10**oracleDecimals).divu(10**tokenDecimals);

        uint256 _balance = token.balanceOf(_addr);

        balance_ = ((_balance * _rate) / 10**oracleDecimals).divu(10**tokenDecimals);
    }

    // views the numeraire value of the current balance of the reserve, in this case eurs
    // instead of calculating with chainlink's "rate" it'll be determined by the existing
    // token ratio. This is in here to prevent LPs from losing out on future oracle price updates
    function viewNumeraireBalanceLPRatio(
        uint256 _baseWeight,
        uint256 _quoteWeight,
        address _addr
    ) external view override returns (int128 balance_) {
        uint256 _tokenBal = token.balanceOf(_addr);

        if (_tokenBal <= 0) return ABDKMath64x64.fromUInt(0);

        uint256 _usdcBal = usdc.balanceOf(_addr).mul(1e18).div(_quoteWeight);

        // Rate is in 1e6
        uint256 _rate = _usdcBal.mul(1e18).div(_tokenBal.mul(1e18).div(_baseWeight));

        balance_ = ((_tokenBal * _rate) / 1e6).divu(1e18);
    }

    function transferFee(int128 _amount, address _treasury) external override returns (bool transferSuccess_) {
        uint256 _rate = getRate();
        if(_amount < 0) _amount = - (_amount);
        uint256 amount = (_amount.mulu(10**tokenDecimals) * 10**oracleDecimals) / _rate;
        token.safeTransfer(_treasury, amount);
    }
}