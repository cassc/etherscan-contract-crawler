// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.21;

import "./WiseCore.sol";
import "./Babylonian.sol";

abstract contract PoolManager is WiseCore {

    struct CreatePool {
        bool allowBorrow;
        address poolToken;
        uint256 poolMulFactor;
        uint256 poolCollFactor;
        uint256 maxDepositAmount;
    }

    struct CurvePoolSettings {
        CurveSwapStructToken curveSecuritySwapsToken;
        CurveSwapStructData curveSecuritySwapsData;
    }

    function setParamsLASA(
        address _poolToken,
        uint256 _poolMulFactor,
        uint256 _upperBoundMaxRate,
        uint256 _lowerBoundMaxRate,
        bool _steppingDirection,
        bool _isFinal
    )
        external
        onlyMaster
    {
        if (parametersLocked[_poolToken] == true) {
            revert ParametersLocked();
        }

        parametersLocked[_poolToken] = _isFinal;
        algorithmData[_poolToken].increasePole = _steppingDirection;

        uint256 staticMinPole = _getMinPole(
            _poolMulFactor,
            _upperBoundMaxRate
        );

        uint256 staticMaxPole = _getMaxPole(
            _poolMulFactor,
            _lowerBoundMaxRate
        );

        uint256 staticDeltaPole = _getDeltaPole(
            staticMaxPole,
            staticMinPole
        );

        uint256 startValuePole = _getStartValue(
            staticMaxPole,
            staticMinPole
        );

        borrowRatesData[_poolToken] = BorrowRatesEntry({
            pole: startValuePole,
            deltaPole: staticDeltaPole,
            minPole: staticMinPole,
            maxPole: staticMaxPole,
            multiplicativeFactor: _poolMulFactor
        });

        algorithmData[_poolToken].bestPole = startValuePole;
        algorithmData[_poolToken].maxValue = lendingPoolData[_poolToken].totalDepositShares;
    }

    function setPoolParameters(
        address _poolToken,
        uint256 _collateralFactor,
        uint256 _maximumDeposit
    )
        external
        onlyMaster
    {
        if (_maximumDeposit > 0) {
            maxDepositValueToken[_poolToken] = _maximumDeposit;
        }

        if (_collateralFactor > 0) {
            lendingPoolData[_poolToken].collateralFactor = _collateralFactor;
        }

        if (_collateralFactor > PRECISION_FACTOR_E18) {
            revert ForbiddenValue();
        }
    }

    /**
     * @dev Allow to verify isolation pool.
     */
    function setVeryfiedIsolationPool(
        address _isolationPool,
        bool _state
    )
        external
        onlyMaster
    {
        veryfiedIsolationPool[_isolationPool] = _state;
    }

    function createPool(
        CreatePool memory _params
    )
        external
        onlyMaster
    {
        _createPool(
            _params
        );

    }

    function createCurvePool(
        CreatePool memory _params,
        CurvePoolSettings memory _settings
    )
        external
        onlyMaster
    {
        _createPool(
            _params
        );

        WISE_SECURITY.prepareCurvePools(
            _params.poolToken,
            _settings.curveSecuritySwapsData,
            _settings.curveSecuritySwapsToken
        );
    }

    function _createPool(
        CreatePool memory _params
    )
        private
    {
        if (timestampsPoolData[_params.poolToken].timeStamp > 0) {
            revert AlreadyCreated();
        }

        // Default boundary values for pool creation.
        uint256 LOWER_BOUND_MAX_RATE = 100 * PRECISION_FACTOR_E16;
        uint256 UPPER_BOUND_MAX_RATE = 300 * PRECISION_FACTOR_E16;

        // Calculating lower bound for the pole
        uint256 staticMinPole = _getMinPole(
            _params.poolMulFactor,
            UPPER_BOUND_MAX_RATE
        );

        // Calculating upper bound for the pole
        uint256 staticMaxPole = _getMaxPole(
            _params.poolMulFactor,
            LOWER_BOUND_MAX_RATE
        );

        // Calculating fraction for algorithm step
        uint256 staticDeltaPole = _getDeltaPole(
            staticMaxPole,
            staticMinPole
        );

        maxDepositValueToken[_params.poolToken] = _params.maxDepositAmount;

        FEE_MANAGER.addPoolTokenAddress(
            _params.poolToken
        );

        globalPoolData[_params.poolToken] = GlobalPoolEntry({
            totalPool: 0,
            utilization: 0,
            totalBareToken: 0,
            poolFee: 20 * PRECISION_FACTOR_E16
        });

        // Setting start value as mean of min and max value
        uint256 startValuePole = _getStartValue(
            staticMaxPole,
            staticMinPole
        );

        // Rates Pool Data
        borrowRatesData[_params.poolToken] = BorrowRatesEntry({
            pole: startValuePole,
            deltaPole: staticDeltaPole,
            minPole: staticMinPole,
            maxPole: staticMaxPole,
            multiplicativeFactor: _params.poolMulFactor
        });

        // Borrow Pool Data
        borrowPoolData[_params.poolToken] = BorrowPoolEntry({
            allowBorrow: _params.allowBorrow,
            pseudoTotalBorrowAmount: 1,
            totalBorrowShares: 1,
            borrowRate: 0
        });

        // Algorithm Pool Data
        algorithmData[_params.poolToken] = AlgorithmEntry({
            bestPole: startValuePole,
            maxValue: 0,
            previousValue: 0,
            increasePole: false
        });

        uint256 fetchBalance = IERC20(_params.poolToken).balanceOf(
            address(this)
        );

        if (fetchBalance > 0) {
            _safeTransfer(
                _params.poolToken,
                master,
                fetchBalance
            );
        }

        // Lending Pool Data
        lendingPoolData[_params.poolToken] = LendingPoolEntry({
            pseudoTotalPool: 1,
            totalDepositShares: 1,
            collateralFactor: _params.poolCollFactor
        });

        // Timestamp Pool Data
        timestampsPoolData[_params.poolToken] = TimestampsPoolEntry({
            timeStamp: block.timestamp,
            timeStampScaling: block.timestamp
        });
    }

    function _getMaxPole(
        uint256 _poolMulFactor,
        uint256 _lowerBoundMaxRate
    )
        private
        pure
        returns (uint256)
    {
        return PRECISION_FACTOR_E18 / 2
            + Babylonian.sqrt(PRECISION_FACTOR_E36 / 4
                + _poolMulFactor
                    * PRECISION_FACTOR_E36
                    / _lowerBoundMaxRate
            );
    }

    function _getMinPole(
        uint256 _poolMulFactor,
        uint256 _upperBoundMaxRate
    )
        private
        pure
        returns (uint256)
    {
        return PRECISION_FACTOR_E18 / 2
            + Babylonian.sqrt(PRECISION_FACTOR_E36 / 4
                + _poolMulFactor
                    * PRECISION_FACTOR_E36
                    / _upperBoundMaxRate
            );
    }

    function _getDeltaPole(
        uint256 _maxPole,
        uint256 _minPole
    )
        private
        pure
        returns (uint256)
    {
        return (_maxPole - _minPole) / NORMALISATION_FACTOR;
    }

    function _getStartValue(
        uint256 _maxPole,
        uint256 _minPole
    )
        private
        pure
        returns (uint256)
    {
        return (_maxPole + _minPole) / 2;
    }
}