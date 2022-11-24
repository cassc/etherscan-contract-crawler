// SPDX-License-Identifier: ISC
pragma solidity ^0.8.17;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================= FraxlendPairCore =========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author
// Drake Evans: https://github.com/DrakeEvans

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./libraries/VaultAccount.sol";

import "./interfaces/IFraxlendPair.sol";
import "./interfaces/IRateCalculator.sol";
import "./interfaces/IRateCalculatorV2.sol";

contract FraxlendPairHelper {
    using VaultAccountingLibrary for VaultAccount;
    using SafeCast for uint256;

    error OracleLTEZero(address _oracle);

    string public constant version = "1.1.0";

    struct ImmutablesAddressBool {
        bool _borrowerWhitelistActive;
        bool _lenderWhitelistActive;
        address _assetContract;
        address _collateralContract;
        address _oracleMultiply;
        address _oracleDivide;
        address _rateContract;
        address _DEPLOYER_CONTRACT;
        address _COMPTROLLER_ADDRESS;
        address _FRAXLEND_WHITELIST;
    }

    struct ImmutablesUint256 {
        uint256 _oracleNormalization;
        uint256 _maxLTV;
        uint256 _liquidationFee;
        uint256 _maturityDate;
        uint256 _penaltyRate;
    }

    struct CurrentRateInfo {
        uint64 lastBlock;
        uint64 feeToProtocolRate; // Fee amount 1e5 precision
        uint64 lastTimestamp;
        uint64 ratePerSec;
        uint64 fullUtilizationRate;
    }

    function getImmutableAddressBool(address _fraxlendPairAddress)
        external
        view
        returns (ImmutablesAddressBool memory)
    {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        return
            ImmutablesAddressBool({
                _assetContract: _fraxlendPair.asset(),
                _collateralContract: _fraxlendPair.collateralContract(),
                _oracleMultiply: _fraxlendPair.oracleMultiply(),
                _oracleDivide: _fraxlendPair.oracleDivide(),
                _rateContract: _fraxlendPair.rateContract(),
                _DEPLOYER_CONTRACT: _fraxlendPair.DEPLOYER_ADDRESS(),
                _COMPTROLLER_ADDRESS: _fraxlendPair.COMPTROLLER_ADDRESS(),
                _FRAXLEND_WHITELIST: _fraxlendPair.FRAXLEND_WHITELIST_ADDRESS(),
                _borrowerWhitelistActive: _fraxlendPair.borrowerWhitelistActive(),
                _lenderWhitelistActive: _fraxlendPair.lenderWhitelistActive()
            });
    }

    function getImmutableUint256(address _fraxlendPairAddress) external view returns (ImmutablesUint256 memory) {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        return
            ImmutablesUint256({
                _oracleNormalization: _fraxlendPair.oracleNormalization(),
                _maxLTV: _fraxlendPair.maxLTV(),
                _liquidationFee: _fraxlendPair.cleanLiquidationFee(),
                _maturityDate: _fraxlendPair.maturityDate(),
                _penaltyRate: _fraxlendPair.penaltyRate()
            });
    }

    function getUserSnapshot(address _fraxlendPairAddress, address _address)
        external
        view
        returns (uint256 _userAssetShares, uint256 _userBorrowShares, uint256 _userCollateralBalance)
    {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        _userAssetShares = _fraxlendPair.balanceOf(_address);
        _userBorrowShares = _fraxlendPair.userBorrowShares(_address);
        _userCollateralBalance = _fraxlendPair.userCollateralBalance(_address);
    }

    function getPairAccounting(address _fraxlendPairAddress)
        external
        view
        returns (
            uint128 _totalAssetAmount,
            uint128 _totalAssetShares,
            uint128 _totalBorrowAmount,
            uint128 _totalBorrowShares,
            uint256 _totalCollateral
        )
    {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        (_totalAssetAmount, _totalAssetShares) = _fraxlendPair.totalAsset();
        (_totalBorrowAmount, _totalBorrowShares) = _fraxlendPair.totalBorrow();
        _totalCollateral = _fraxlendPair.totalCollateral();
    }

    function previewUpdateExchangeRate(address _fraxlendPairAddress) public view returns (uint256 _exchangeRate) {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        address _oracleMultiply = _fraxlendPair.oracleMultiply();
        address _oracleDivide = _fraxlendPair.oracleDivide();
        uint256 _oracleNormalization = _fraxlendPair.oracleNormalization();

        uint256 _price = uint256(1e36);
        if (_oracleMultiply != address(0)) {
            (, int256 _answer, , , ) = AggregatorV3Interface(_oracleMultiply).latestRoundData();
            if (_answer <= 0) {
                revert OracleLTEZero(_oracleMultiply);
            }
            _price = _price * uint256(_answer);
        }

        if (_oracleDivide != address(0)) {
            (, int256 _answer, , , ) = AggregatorV3Interface(_oracleDivide).latestRoundData();
            if (_answer <= 0) {
                revert OracleLTEZero(_oracleDivide);
            }
            _price = _price / uint256(_answer);
        }

        _exchangeRate = _price / _oracleNormalization;
    }

    function _isPastMaturity(uint256 _maturityDate, uint256 _timestamp) internal pure returns (bool) {
        return _maturityDate != 0 && _timestamp > _maturityDate;
    }

    function previewRateInterest(address _fraxlendPairAddress, uint256 _timestamp, uint256 _blockNumber)
        public
        view
        returns (uint256 _interestEarned, uint256 _newRate)
    {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        (, , uint256 _UTIL_PREC, , , uint64 _DEFAULT_INT, , ) = _fraxlendPair.getConstants();

        // Add interest only once per block
        CurrentRateInfo memory _currentRateInfo;
        {
            (uint64 lastBlock, uint64 feeToProtocolRate, uint64 lastTimestamp, uint64 ratePerSec, uint64 _fullUtilizationRate) = _fraxlendPair
                .currentRateInfo();
            _currentRateInfo = CurrentRateInfo({
                lastBlock: lastBlock,
                feeToProtocolRate: feeToProtocolRate,
                lastTimestamp: lastTimestamp,
                ratePerSec: ratePerSec,
                fullUtilizationRate: _fullUtilizationRate
            });
        }

        // Pull some data from storage to save gas
        VaultAccount memory _totalAsset;
        VaultAccount memory _totalBorrow;
        {
            (uint128 _totalAssetAmount, uint128 _totalAssetShares) = _fraxlendPair.totalAsset();
            _totalAsset = VaultAccount({ amount: _totalAssetAmount, shares: _totalAssetShares });
            (uint128 _totalBorrowAmount, uint128 _totalBorrowShares) = _fraxlendPair.totalBorrow();
            _totalBorrow = VaultAccount({ amount: _totalBorrowAmount, shares: _totalBorrowShares });
        }

        // If there are no borrows, no interest accrues
        if (_totalBorrow.shares == 0 || _fraxlendPair.paused()) {
            if (!_fraxlendPair.paused()) {
                _currentRateInfo.ratePerSec = _DEFAULT_INT;
            }
            // _currentRateInfo.lastTimestamp = uint32(_timestamp);
            // _currentRateInfo.lastBlock = uint16(_blockNumber);
        } else {
            // NOTE: Violates Checks-Effects-Interactions pattern
            // Be sure to mark external version NONREENTRANT (even though rateContract is trusted)
            // Calc new rate
            if (_isPastMaturity(_fraxlendPair.maturityDate(), _timestamp)) {
                _newRate = uint64(_fraxlendPair.penaltyRate());
            } else {
                try _fraxlendPair.version() {
                    (_newRate, ) = IRateCalculatorV2(_fraxlendPair.rateContract()).getNewRate(
                        _timestamp - _currentRateInfo.lastTimestamp,
                        (_totalBorrow.amount * _UTIL_PREC) / _totalAsset.amount,
                        _currentRateInfo.fullUtilizationRate
                    );
                } catch {
                    _newRate = IRateCalculator(_fraxlendPair.rateContract()).getNewRate(
                        abi.encode(
                            _currentRateInfo.ratePerSec,
                            _timestamp - _currentRateInfo.lastTimestamp,
                            (_totalBorrow.amount * _UTIL_PREC) / _totalAsset.amount,
                            _blockNumber - _currentRateInfo.lastBlock
                        ),
                        abi.encode()
                    );
                }
            }

            // Calculate interest accrued
            _interestEarned = (_totalBorrow.amount * _newRate * (_timestamp - _currentRateInfo.lastTimestamp)) / 1e18;
        }
    }

    function previewRateInterestFees(address _fraxlendPairAddress, uint256 _timestamp, uint256 _blockNumber)
        external
        view
        returns (uint256 _interestEarned, uint256 _feesAmount, uint256 _feesShare, uint256 _newRate)
    {
        (_interestEarned, _newRate) = previewRateInterest(_fraxlendPairAddress, _timestamp, _blockNumber);
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        (, uint64 _feeToProtocolRate, , , ) = _fraxlendPair.currentRateInfo();
        (, , , uint256 _FEE_PRECISION, , , , ) = _fraxlendPair.getConstants();
        (uint128 _totalAssetAmount, uint128 _totalAssetShares) = _fraxlendPair.totalAsset();
        if (_feeToProtocolRate > 0) {
            _feesAmount = (_interestEarned * _feeToProtocolRate) / _FEE_PRECISION;
            _feesShare = (_feesAmount * _totalAssetShares) / (_totalAssetAmount + _interestEarned - _feesAmount);
        }
    }

    function previewLiquidatePure(address _fraxlendPairAddress, uint128 _sharesToLiquidate, address _borrower)
        public
        view
        returns (
            uint128 _amountLiquidatorToRepay,
            uint256 _collateralForLiquidator,
            uint128 _sharesToSocialize,
            uint128 _amountToSocialize
        )
    {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);

        VaultAccount memory _totalBorrow;
        {
            (uint128 _totalBorrowAmount, uint128 _totalBorrowShares) = _fraxlendPair.totalBorrow();
            _totalBorrow = VaultAccount({ amount: _totalBorrowAmount, shares: _totalBorrowShares });
        }

        int256 _leftoverCollateral;
        uint128 _borrowerShares;
        {
            uint256 _exchangeRate = previewUpdateExchangeRate(_fraxlendPairAddress);
            _borrowerShares = _fraxlendPair.userBorrowShares(_borrower).toUint128();
            (, uint256 _LIQ_PRECISION, , , uint256 _EXCHANGE_PRECISION, , , ) = _fraxlendPair.getConstants();
            uint256 _userCollateralBalance = _fraxlendPair.userCollateralBalance(_borrower);
            // Determine the liquidation amount in collateral units (i.e. how much debt is liquidator going to repay)
            uint256 _liquidationAmountInCollateralUnits = ((_totalBorrow.toAmount(_borrowerShares, false) *
                _exchangeRate) / _EXCHANGE_PRECISION);

            // We first optimistically calculate the amount of collateral to give the liquidator based on the higher clean liquidation fee
            // This fee only applies if the liquidator does a full liquidation
            uint256 _optimisticCollateralForLiquidator = (_liquidationAmountInCollateralUnits *
                (_LIQ_PRECISION + _fraxlendPair.cleanLiquidationFee())) / _LIQ_PRECISION;

            // Because interest accrues every block, _liquidationAmountInCollateralUnits (line 913) is an ever increasing value
            // This means that leftoverCollateral can occasionally go negative by a few hundred wei (cleanLiqFee premium covers this for liquidator)
            _leftoverCollateral = (_userCollateralBalance.toInt256() - _optimisticCollateralForLiquidator.toInt256());
            // If cleanLiquidation fee results in no leftover collateral, give liquidator all the collateral
            // This will only be true when there liquidator is cleaning out the position
            _collateralForLiquidator = _leftoverCollateral <= 0
                ? _userCollateralBalance
                : (_liquidationAmountInCollateralUnits * (_LIQ_PRECISION + _fraxlendPair.dirtyLiquidationFee())) /
                    _LIQ_PRECISION;
        }
        _amountLiquidatorToRepay = (_totalBorrow.toAmount(_sharesToLiquidate, true)).toUint128();

        // Determine if and how much debt to socialize
        if (_leftoverCollateral <= 0 && (_borrowerShares - _sharesToLiquidate) > 0) {
            // Socialize bad debt
            _sharesToSocialize = _borrowerShares - _sharesToLiquidate;
            _amountToSocialize = (_totalBorrow.toAmount(_sharesToSocialize, false)).toUint128();
        }
    }

    function previewTotalBorrow(address _fraxlendPairAddress, uint256 _timestamp, uint256 _blockNumber)
        public
        view
        returns (VaultAccount memory _previewTotalBorrow)
    {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        (uint128 _totalBorrowAmount, uint128 _totalBorrowShares) = _fraxlendPair.totalBorrow();
        (uint256 _interestEarned, ) = previewRateInterest(_fraxlendPairAddress, _timestamp, _blockNumber);
        _previewTotalBorrow.amount = _totalBorrowAmount + _interestEarned.toUint128();
        _previewTotalBorrow.shares = _totalBorrowShares;
    }

    function previewTotalAsset(address _fraxlendPairAddress, uint256 _timestamp, uint256 _blockNumber)
        public
        view
        returns (VaultAccount memory _previewTotalBorrow)
    {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        (uint128 _totalAssetAmount, uint128 _totalAssetShares) = _fraxlendPair.totalAsset();
        (uint256 _interestEarned, ) = previewRateInterest(_fraxlendPairAddress, _timestamp, _blockNumber);
        _previewTotalBorrow.amount = _totalAssetAmount + _interestEarned.toUint128();
        _previewTotalBorrow.shares = _totalAssetShares;
    }

    function toBorrowAmount(
        address _fraxlendPairAddress,
        uint256 _shares,
        uint256 _timestamp,
        uint256 _blockNumber,
        bool _roundUp
    ) external view returns (uint256 _amount, uint256 _totalAmount, uint256 _totalShares) {
        VaultAccount memory _previewTotalBorrow = previewTotalBorrow(_fraxlendPairAddress, _timestamp, _blockNumber);
        _amount = _previewTotalBorrow.toAmount(_shares, _roundUp);
        _totalAmount = _previewTotalBorrow.amount;
        _totalShares = _previewTotalBorrow.shares;
    }

    function toBorrowShares(
        address _fraxlendPairAddress,
        uint256 _amount,
        uint256 _timestamp,
        uint256 _blockNumber,
        bool _roundUp
    ) external view returns (uint256 _shares, uint256 _totalAmount, uint256 _totalShares) {
        VaultAccount memory _previewTotalBorrow = previewTotalBorrow(_fraxlendPairAddress, _timestamp, _blockNumber);
        _shares = _previewTotalBorrow.toShares(_amount, _roundUp);
        _totalAmount = _previewTotalBorrow.amount;
        _totalShares = _previewTotalBorrow.shares;
    }

    function toAssetAmount(
        address _fraxlendPairAddress,
        uint256 _shares,
        uint256 _timestamp,
        uint256 _blockNumber,
        bool _roundUp
    ) external view returns (uint256 _amount, uint256 _totalAmount, uint256 _totalShares) {
        VaultAccount memory _previewTotalAsset = previewTotalAsset(_fraxlendPairAddress, _timestamp, _blockNumber);
        _amount = _previewTotalAsset.toAmount(_shares, _roundUp);
        _totalAmount = _previewTotalAsset.amount;
        _totalShares = _previewTotalAsset.shares;
    }

    function toAssetShares(
        address _fraxlendPairAddress,
        uint256 _amount,
        uint256 _timestamp,
        uint256 _blockNumber,
        bool _roundUp
    ) external view returns (uint256 _shares, uint256 _totalAmount, uint256 _totalShares) {
        VaultAccount memory _previewTotalAsset = previewTotalAsset(_fraxlendPairAddress, _timestamp, _blockNumber);
        _shares = _previewTotalAsset.toShares(_amount, _roundUp);
        _totalAmount = _previewTotalAsset.amount;
        _totalShares = _previewTotalAsset.shares;
    }
}