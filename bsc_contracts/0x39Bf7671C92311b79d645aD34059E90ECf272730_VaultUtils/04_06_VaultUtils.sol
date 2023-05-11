// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IVaultUtils.sol";
import "../access/Governable.sol";

contract VaultUtils is IVaultUtils, Governable {
    using SafeMath for uint256;

    struct Position {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 reserveAmount;
        int256 realisedPnl;
        uint256 lastIncreasedTime;
    }

    IVault public vault;
    address public admin;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant FUNDING_RATE_PRECISION = 1000000000;
    uint256 public constant POSITION_RATE_X_AXIS_PRECISION = 10000;
    uint256 public constant MAX_FEE_BASIS_POINTS = 500; // 5%
    uint256 public constant MAX_ZERO_FEE_INTERVAL = 30 days;

    uint256 public positionRateIncreaseR0 = 0; // 0%
    uint256 public positionRateIncreaseR1 = 5; // 0.05%
    uint256 public positionRateIncreaseR2 = 10; // 0.1%
    uint256 public positionRateIncreaseX1 = 5000; // 50%
    uint256 public positionRateDecreaseR0 = 0; // 0%
    uint256 public positionRateDecreaseR1 = 5; // 0.05%
    uint256 public positionRateDecreaseR2 = 10; // 0.1%
    uint256 public positionRateDecreaseX1 = 5000; // 50%
    bool public useDynamicPositionFee = false;

    mapping(address => uint256) public zeroPositionFee;

    event AddZeroPositionFee(address account, uint256 interval);
    event DeleteZeroPositionFee(address account);

    constructor(IVault _vault) public {
        admin = msg.sender;
        vault = _vault;
    }

    function addZeroPositionFee(
        address _account,
        uint256 _interval
    ) external onlyGov {
        require(
            _interval <= MAX_ZERO_FEE_INTERVAL,
            "VaultUtils: max zero fee interval exceeded"
        );
        zeroPositionFee[_account] = block.timestamp.add(_interval);
        emit AddZeroPositionFee(_account, block.timestamp.add(_interval));
    }

    function deleteZeroPositionFee(address _account) external onlyGov {
        delete zeroPositionFee[_account];
        emit DeleteZeroPositionFee(_account);
    }

    function setUseDynamicPositionFee(
        bool _useDynamicPositionFee
    ) external onlyGov {
        useDynamicPositionFee = _useDynamicPositionFee;
    }

    function setDynamicFeePositionRate(
        uint256 _positionRateIncreaseR0,
        uint256 _positionRateIncreaseR1,
        uint256 _positionRateIncreaseR2,
        uint256 _positionRateIncreaseX1,
        uint256 _positionRateDecreaseR0,
        uint256 _positionRateDecreaseR1,
        uint256 _positionRateDecreaseR2,
        uint256 _positionRateDecreaseX1
    ) external onlyGov {
        require(
            _positionRateIncreaseR0 <= MAX_FEE_BASIS_POINTS,
            "VaultUtils: max funding rate exceeded"
        );
        require(
            _positionRateIncreaseR1 <= MAX_FEE_BASIS_POINTS,
            "VaultUtils: max funding rate exceeded"
        );
        require(
            _positionRateIncreaseR2 <= MAX_FEE_BASIS_POINTS,
            "VaultUtils: max funding rate exceeded"
        );
        require(
            _positionRateDecreaseR0 <= MAX_FEE_BASIS_POINTS,
            "VaultUtils: max funding rate exceeded"
        );
        require(
            _positionRateDecreaseR1 <= MAX_FEE_BASIS_POINTS,
            "VaultUtils: max funding rate exceeded"
        );
        require(
            _positionRateDecreaseR2 <= MAX_FEE_BASIS_POINTS,
            "VaultUtils: max funding rate exceeded"
        );
        require(
            _positionRateIncreaseX1 <= POSITION_RATE_X_AXIS_PRECISION,
            "VaultUtils: max position rate x axis exceeded"
        );
        require(
            _positionRateDecreaseX1 <= POSITION_RATE_X_AXIS_PRECISION,
            "VaultUtils: max position rate x axis exceeded"
        );

        positionRateIncreaseR0 = _positionRateIncreaseR0;
        positionRateIncreaseR1 = _positionRateIncreaseR1;
        positionRateIncreaseR2 = _positionRateIncreaseR2;
        positionRateIncreaseX1 = _positionRateIncreaseX1;
        positionRateDecreaseR0 = _positionRateDecreaseR0;
        positionRateDecreaseR1 = _positionRateDecreaseR1;
        positionRateDecreaseR2 = _positionRateDecreaseR2;
        positionRateDecreaseX1 = _positionRateDecreaseX1;
    }

    function updateCumulativeFundingRate(
        address /* _collateralToken */,
        address /* _indexToken */
    ) public override returns (bool) {
        return true;
    }

    function validateIncreasePosition(
        address /* _account */,
        address /* _collateralToken */,
        address /* _indexToken */,
        uint256 /* _sizeDelta */,
        bool /* _isLong */
    ) external view override {
        // no additional validations
    }

    function validateDecreasePosition(
        address /* _account */,
        address /* _collateralToken */,
        address /* _indexToken */,
        uint256 /* _collateralDelta */,
        uint256 /* _sizeDelta */,
        bool /* _isLong */,
        address /* _receiver */
    ) external view override {
        // no additional validations
    }

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) internal view returns (Position memory) {
        IVault _vault = vault;
        Position memory position;
        {
            (
                uint256 size,
                uint256 collateral,
                uint256 averagePrice,
                uint256 entryFundingRate /* reserveAmount */ /* realisedPnl */ /* hasProfit */,
                ,
                ,
                ,
                uint256 lastIncreasedTime
            ) = _vault.getPosition(
                    _account,
                    _collateralToken,
                    _indexToken,
                    _isLong
                );
            position.size = size;
            position.collateral = collateral;
            position.averagePrice = averagePrice;
            position.entryFundingRate = entryFundingRate;
            position.lastIncreasedTime = lastIncreasedTime;
        }
        return position;
    }

    function validateLiquidation(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bool _raise
    ) public view override returns (uint256, uint256) {
        Position memory position = getPosition(
            _account,
            _collateralToken,
            _indexToken,
            _isLong
        );
        IVault _vault = vault;

        (bool hasProfit, uint256 delta) = _vault.getDelta(
            _indexToken,
            position.size,
            position.averagePrice,
            _isLong,
            position.lastIncreasedTime
        );
        uint256 marginFees = getFundingFee(
            _account,
            _collateralToken,
            _indexToken,
            _isLong,
            position.size,
            position.entryFundingRate
        );
        marginFees = marginFees.add(
            getPositionFee(
                _account,
                _collateralToken,
                _indexToken,
                _isLong,
                false /* isIncrease */,
                position.size
            )
        );

        if (!hasProfit && position.collateral < delta) {
            if (_raise) {
                revert("Vault: losses exceed collateral");
            }
            return (1, marginFees);
        }

        uint256 remainingCollateral = position.collateral;
        if (!hasProfit) {
            remainingCollateral = position.collateral.sub(delta);
        }

        if (remainingCollateral < marginFees) {
            if (_raise) {
                revert("Vault: fees exceed collateral");
            }
            // cap the fees to the remainingCollateral
            return (1, remainingCollateral);
        }

        if (remainingCollateral < marginFees.add(_vault.liquidationFeeUsd())) {
            if (_raise) {
                revert("Vault: liquidation fees exceed collateral");
            }
            return (1, marginFees);
        }

        if (
            remainingCollateral.mul(_vault.maxLeverage()) <
            position.size.mul(BASIS_POINTS_DIVISOR)
        ) {
            if (_raise) {
                revert("Vault: maxLeverage exceeded");
            }
            return (2, marginFees);
        }

        return (0, marginFees);
    }

    function getEntryFundingRate(
        address _collateralToken,
        address /* _indexToken */,
        bool /* _isLong */
    ) public view override returns (uint256) {
        return vault.cumulativeFundingRates(_collateralToken);
    }

    function getPositionRate(
        address /* _account */,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bool _isIncrease,
        uint256 /* _sizeDelta */
    ) public view override returns (uint256) {
        uint256 poolAmount = _isLong
            ? vault.poolAmounts(_indexToken)
            : vault.poolAmounts(_collateralToken);
        uint256 reservedAmount = _isLong
            ? vault.reservedAmounts(_indexToken)
            : vault.reservedAmounts(_collateralToken);
        if (poolAmount == 0) {
            return 0;
        }
        uint256 currentOpenInterestRate = reservedAmount
            .mul(POSITION_RATE_X_AXIS_PRECISION)
            .div(poolAmount);
        uint256 r0;
        uint256 r1;
        uint256 x;
        uint256 x1;
        if (_isIncrease) {
            if (currentOpenInterestRate <= positionRateIncreaseX1) {
                r0 = positionRateIncreaseR0;
                r1 = positionRateIncreaseR1;
                x = currentOpenInterestRate;
                x1 = positionRateIncreaseX1;
            } else {
                r0 = positionRateIncreaseR1;
                r1 = positionRateIncreaseR2;
                x = currentOpenInterestRate - positionRateIncreaseX1;
                x1 = POSITION_RATE_X_AXIS_PRECISION - positionRateIncreaseX1;
            }
        } else {
            if (currentOpenInterestRate <= positionRateDecreaseX1) {
                r0 = positionRateDecreaseR0;
                r1 = positionRateDecreaseR1;
                x = currentOpenInterestRate;
                x1 = positionRateDecreaseX1;
            } else {
                r0 = positionRateDecreaseR1;
                r1 = positionRateDecreaseR2;
                x = currentOpenInterestRate - positionRateDecreaseX1;
                x1 = POSITION_RATE_X_AXIS_PRECISION - positionRateDecreaseX1;
            }
        }
        if (r0 == r1) {
            return r0;
        } else if (r0 < r1) {
            return r0.add(r1.sub(r0).mul(x).div(x1));
        }
        return r0.sub(r0.sub(r1).mul(x).div(x1));
    }

    function getPositionFee(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bool _isIncrease,
        uint256 _sizeDelta
    ) public view override returns (uint256) {
        if (_sizeDelta == 0) {
            return 0;
        }
        if (zeroPositionFee[_account] > block.timestamp) {
            return 0;
        }
        uint256 marginFeeBasisPoints = useDynamicPositionFee
            ? getPositionRate(
                _account,
                _collateralToken,
                _indexToken,
                _isLong,
                _isIncrease,
                _sizeDelta
            )
            : vault.marginFeeBasisPoints();
        uint256 afterFeeUsd = _sizeDelta
            .mul(BASIS_POINTS_DIVISOR.sub(marginFeeBasisPoints))
            .div(BASIS_POINTS_DIVISOR);
        return _sizeDelta.sub(afterFeeUsd);
    }

    function getFundingFee(
        address /* _account */,
        address _collateralToken,
        address /* _indexToken */,
        bool /* _isLong */,
        uint256 _size,
        uint256 _entryFundingRate
    ) public view override returns (uint256) {
        if (_size == 0) {
            return 0;
        }

        uint256 fundingRate = vault
            .cumulativeFundingRates(_collateralToken)
            .sub(_entryFundingRate);
        if (fundingRate == 0) {
            return 0;
        }

        return _size.mul(fundingRate).div(FUNDING_RATE_PRECISION);
    }

    function getBuyUsdgFeeBasisPoints(
        address _token,
        uint256 _usdgAmount
    ) public view override returns (uint256) {
        return
            getFeeBasisPoints(
                _token,
                _usdgAmount,
                vault.mintBurnFeeBasisPoints(),
                vault.taxBasisPoints(),
                true
            );
    }

    function getSellUsdgFeeBasisPoints(
        address _token,
        uint256 _usdgAmount
    ) public view override returns (uint256) {
        return
            getFeeBasisPoints(
                _token,
                _usdgAmount,
                vault.mintBurnFeeBasisPoints(),
                vault.taxBasisPoints(),
                false
            );
    }

    function getSwapFeeBasisPoints(
        address _tokenIn,
        address _tokenOut,
        uint256 _usdgAmount
    ) public view override returns (uint256) {
        bool isStableSwap = vault.stableTokens(_tokenIn) &&
            vault.stableTokens(_tokenOut);
        uint256 baseBps = isStableSwap
            ? vault.stableSwapFeeBasisPoints()
            : vault.swapFeeBasisPoints();
        uint256 taxBps = isStableSwap
            ? vault.stableTaxBasisPoints()
            : vault.taxBasisPoints();
        uint256 feesBasisPoints0 = getFeeBasisPoints(
            _tokenIn,
            _usdgAmount,
            baseBps,
            taxBps,
            true
        );
        uint256 feesBasisPoints1 = getFeeBasisPoints(
            _tokenOut,
            _usdgAmount,
            baseBps,
            taxBps,
            false
        );
        // use the higher of the two fee basis points
        return
            feesBasisPoints0 > feesBasisPoints1
                ? feesBasisPoints0
                : feesBasisPoints1;
    }

    // cases to consider
    // 1. initialAmount is far from targetAmount, action increases balance slightly => high rebate
    // 2. initialAmount is far from targetAmount, action increases balance largely => high rebate
    // 3. initialAmount is close to targetAmount, action increases balance slightly => low rebate
    // 4. initialAmount is far from targetAmount, action reduces balance slightly => high tax
    // 5. initialAmount is far from targetAmount, action reduces balance largely => high tax
    // 6. initialAmount is close to targetAmount, action reduces balance largely => low tax
    // 7. initialAmount is above targetAmount, nextAmount is below targetAmount and vice versa
    // 8. a large swap should have similar fees as the same trade split into multiple smaller swaps
    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) public view override returns (uint256) {
        if (!vault.hasDynamicFees()) {
            return _feeBasisPoints;
        }

        uint256 initialAmount = vault.usdgAmounts(_token);
        uint256 nextAmount = initialAmount.add(_usdgDelta);
        if (!_increment) {
            nextAmount = _usdgDelta > initialAmount
                ? 0
                : initialAmount.sub(_usdgDelta);
        }

        uint256 targetAmount = vault.getTargetUsdgAmount(_token);
        if (targetAmount == 0) {
            return _feeBasisPoints;
        }

        uint256 initialDiff = initialAmount > targetAmount
            ? initialAmount.sub(targetAmount)
            : targetAmount.sub(initialAmount);
        uint256 nextDiff = nextAmount > targetAmount
            ? nextAmount.sub(targetAmount)
            : targetAmount.sub(nextAmount);

        // action improves relative asset balance
        if (nextDiff < initialDiff) {
            uint256 rebateBps = _taxBasisPoints.mul(initialDiff).div(
                targetAmount
            );
            return
                rebateBps > _feeBasisPoints
                    ? 0
                    : _feeBasisPoints.sub(rebateBps);
        }

        uint256 averageDiff = initialDiff.add(nextDiff).div(2);
        if (averageDiff > targetAmount) {
            averageDiff = targetAmount;
        }
        uint256 taxBps = _taxBasisPoints.mul(averageDiff).div(targetAmount);
        return _feeBasisPoints.add(taxBps);
    }
}