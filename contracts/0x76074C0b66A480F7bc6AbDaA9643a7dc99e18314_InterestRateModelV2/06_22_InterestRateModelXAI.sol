// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./lib/PRBMathSD59x18.sol";
import "./lib/EasyMath.sol";
import "./interfaces/ISilo.sol";
import "./interfaces/IInterestRateModel.sol";
import "./utils/TwoStepOwnable.sol";

/// @title InterestRateModelXAI
/// @notice Dynamic interest rate model implementation
/// @dev Model stores some Silo specific data. If model is replaced, it needs to set proper config after redeployment
/// for seamless service. Please refer to separate litepaper about model for design details.
/// Difference between original `InterestRateModel` is that we made methods to be `virtual` and :
///     if (_config.ki < 0) revert InvalidKi();  --- was ... <= 0
//      if (_config.kcrit < 0) revert InvalidKcrit();  --- was ... <= 0
/// @custom:security-contact [email protected]
contract InterestRateModelXAI is IInterestRateModel, TwoStepOwnable {
    using PRBMathSD59x18 for int256;
    using SafeCast for int256;
    using SafeCast for uint256;

    /// @dev DP is 18 decimal points used for integer calculations
    uint256 public constant override DP = 1e18;

    /// @dev maximum value of compound interest the model will return
    uint256 public constant RCOMP_MAX = (2**16) * 1e18;

    /// @dev maximum value of X for which, RCOMP_MAX should be returned. If x > X_MAX => exp(x) > RCOMP_MAX.
    /// X_MAX = ln(RCOMP_MAX + 1)
    int256 public constant X_MAX = 11090370147631773313;

    /// @dev maximum allowed amount for accruedInterest, totalDeposits and totalBorrowedAmount
    /// after adding compounded interest. If rcomp cause this values to overflow, rcomp is reduced.
    /// 196 bits max allowed for an asset amounts because the multiplication product with
    /// decimal points (10^18) should not cause an overflow. 196 < log2(2^256 / 10^18)
    uint256 public constant ASSET_DATA_OVERFLOW_LIMIT = 2**196;

    // Silo => asset => ModelData
    mapping(address => mapping(address => Config)) public config;

    /// @notice Emitted on config change
    /// @param silo Silo address for which config should be set
    /// @param asset asset address for which config should be set
    /// @param config config struct for asset in Silo
    event ConfigUpdate(address indexed silo, address indexed asset, Config config);

    error InvalidBeta();
    error InvalidKcrit();
    error InvalidKi();
    error InvalidKlin();
    error InvalidKlow();
    error InvalidTcrit();
    error InvalidTimestamps();
    error InvalidUcrit();
    error InvalidUlow();
    error InvalidUopt();
    error InvalidRi();

    constructor(Config memory _config) {
        _setConfig(address(0), address(0), _config);
    }

    /// @inheritdoc IInterestRateModel
    function setConfig(address _silo, address _asset, Config calldata _config) external virtual override onlyOwner {
        // we do not care, if accrueInterest call will be successful
        // solhint-disable-next-line avoid-low-level-calls
        _silo.call(abi.encodeCall(ISilo.accrueInterest, _asset));

        _setConfig(_silo, _asset, _config);
    }

    /// @inheritdoc IInterestRateModel
    function getCompoundInterestRateAndUpdate(
        address _asset,
        uint256 _blockTimestamp
    ) external virtual override returns (uint256 rcomp) {
        // assume that caller is Silo
        address silo = msg.sender;

        ISilo.UtilizationData memory data = ISilo(silo).utilizationData(_asset);

        // TODO when depositing, we doing two calls for `calculateCompoundInterestRate`, maybe we can optimize?
        Config storage currentConfig = config[silo][_asset];

        (rcomp, currentConfig.ri, currentConfig.Tcrit) = calculateCompoundInterestRate(
            getConfig(silo, _asset),
            data.totalDeposits,
            data.totalBorrowAmount,
            data.interestRateTimestamp,
            _blockTimestamp
        );
    }

    /// @inheritdoc IInterestRateModel
    function getCompoundInterestRate(
        address _silo,
        address _asset,
        uint256 _blockTimestamp
    ) external view virtual override returns (uint256 rcomp) {
        ISilo.UtilizationData memory data = ISilo(_silo).utilizationData(_asset);

        (rcomp,,) = calculateCompoundInterestRate(
            getConfig(_silo, _asset),
            data.totalDeposits,
            data.totalBorrowAmount,
            data.interestRateTimestamp,
            _blockTimestamp
        );
    }

    /// @inheritdoc IInterestRateModel
    function overflowDetected(
        address _silo,
        address _asset,
        uint256 _blockTimestamp
    ) external view virtual override returns (bool overflow) {
        ISilo.UtilizationData memory data = ISilo(_silo).utilizationData(_asset);

        (,,,overflow) = calculateCompoundInterestRateWithOverflowDetection(
            getConfig(_silo, _asset),
            data.totalDeposits,
            data.totalBorrowAmount,
            data.interestRateTimestamp,
            _blockTimestamp
        );
    }

    /// @inheritdoc IInterestRateModel
    function getCurrentInterestRate(
        address _silo,
        address _asset,
        uint256 _blockTimestamp
    ) external view virtual override returns (uint256 rcur) {
        ISilo.UtilizationData memory data = ISilo(_silo).utilizationData(_asset);

        rcur = calculateCurrentInterestRate(
            getConfig(_silo, _asset),
            data.totalDeposits,
            data.totalBorrowAmount,
            data.interestRateTimestamp,
            _blockTimestamp
        );
    }

    /// @inheritdoc IInterestRateModel
    function getConfig(address _silo, address _asset) public view virtual override returns (Config memory) {
        Config storage currentConfig = config[_silo][_asset];

        if (currentConfig.uopt != 0) {
            return currentConfig;
        }

        // use default config
        Config memory c = config[address(0)][address(0)];

        // model data is always stored for each silo and asset so default values must be replaced
        c.ri = currentConfig.ri;
        c.Tcrit = currentConfig.Tcrit;
        return c;
    }

    /* solhint-disable */

    struct LocalVarsRCur {
        int256 T;
        int256 u;
        int256 DP;
        int256 rp;
        int256 rlin;
        int256 ri;
        bool overflow;
    }

    /// @inheritdoc IInterestRateModel
    function calculateCurrentInterestRate(
        Config memory _c,
        uint256 _totalDeposits,
        uint256 _totalBorrowAmount,
        uint256 _interestRateTimestamp,
        uint256 _blockTimestamp
    ) public pure virtual override returns (uint256 rcur) {
        if (_interestRateTimestamp > _blockTimestamp) revert InvalidTimestamps();

        // struct for local vars to avoid "Stack too deep"
        LocalVarsRCur memory _l = LocalVarsRCur(0,0,0,0,0,0,false);

        (,,,_l.overflow) = calculateCompoundInterestRateWithOverflowDetection(
            _c,
            _totalDeposits,
            _totalBorrowAmount,
            _interestRateTimestamp,
            _blockTimestamp
        );

        if (_l.overflow) {
            return 0;
        }

        // There can't be an underflow in the subtraction because of the previous check
        unchecked {
            // T := t1 - t0 # length of time period in seconds
            _l.T = (_blockTimestamp - _interestRateTimestamp).toInt256();
        }

        _l.u = EasyMath.calculateUtilization(DP, _totalDeposits, _totalBorrowAmount).toInt256();
        _l.DP = int256(DP);

        if (_l.u > _c.ucrit) {
            // rp := kcrit *(1 + Tcrit + beta *T)*( u0 - ucrit )
            _l.rp = _c.kcrit * (_l.DP + _c.Tcrit + _c.beta * _l.T) / _l.DP * (_l.u - _c.ucrit) / _l.DP;
        } else {
            // rp := min (0, klow * (u0 - ulow ))
            _l.rp = _min(0, _c.klow * (_l.u - _c.ulow) / _l.DP);
        }

        // rlin := klin * u0 # lower bound between t0 and t1
        _l.rlin = _c.klin * _l.u / _l.DP;
        // ri := max(ri , rlin )
        _l.ri = _max(_c.ri, _l.rlin);
        // ri := max(ri + ki * (u0 - uopt ) * T, rlin )
        _l.ri = _max(_l.ri + _c.ki * (_l.u - _c.uopt) * _l.T / _l.DP, _l.rlin);
        // rcur := max (ri + rp , rlin ) # current per second interest rate
        rcur = (_max(_l.ri + _l.rp, _l.rlin)).toUint256();
        rcur *= 365 days;
    }

    struct LocalVarsRComp {
        int256 T;
        int256 slopei;
        int256 rp;
        int256 slope;
        int256 r0;
        int256 rlin;
        int256 r1;
        int256 x;
        int256 rlin1;
        int256 u;
    }

    function interestRateModelPing() external pure virtual override returns (bytes4) {
        return this.interestRateModelPing.selector;
    }

    /// @inheritdoc IInterestRateModel
    function calculateCompoundInterestRate(
        Config memory _c,
        uint256 _totalDeposits,
        uint256 _totalBorrowAmount,
        uint256 _interestRateTimestamp,
        uint256 _blockTimestamp
    ) public pure virtual override returns (
        uint256 rcomp,
        int256 ri,
        int256 Tcrit
    ) {
        (rcomp, ri, Tcrit,) = calculateCompoundInterestRateWithOverflowDetection(
            _c,
            _totalDeposits,
            _totalBorrowAmount,
            _interestRateTimestamp,
            _blockTimestamp
        );
    }

    /// @inheritdoc IInterestRateModel
    function calculateCompoundInterestRateWithOverflowDetection(
        Config memory _c,
        uint256 _totalDeposits,
        uint256 _totalBorrowAmount,
        uint256 _interestRateTimestamp,
        uint256 _blockTimestamp
    ) public pure virtual override returns (
        uint256 rcomp,
        int256 ri,
        int256 Tcrit,
        bool overflow
    ) {
        ri = _c.ri;
        Tcrit = _c.Tcrit;

        // struct for local vars to avoid "Stack too deep"
        LocalVarsRComp memory _l = LocalVarsRComp(0,0,0,0,0,0,0,0,0,0);

        if (_interestRateTimestamp > _blockTimestamp) revert InvalidTimestamps();

        // There can't be an underflow in the subtraction because of the previous check
    unchecked {
        // length of time period in seconds
        _l.T = (_blockTimestamp - _interestRateTimestamp).toInt256();
    }

        int256 _DP = int256(DP);

        _l.u = EasyMath.calculateUtilization(DP, _totalDeposits, _totalBorrowAmount).toInt256();

        // slopei := ki * (u0 - uopt )
        _l.slopei = _c.ki * (_l.u - _c.uopt) / _DP;

        if (_l.u > _c.ucrit) {
            // rp := kcrit * (1 + Tcrit) * (u0 - ucrit )
            _l.rp = _c.kcrit * (_DP + Tcrit) / _DP * (_l.u - _c.ucrit) / _DP;
            // slope := slopei + kcrit * beta * (u0 - ucrit )
            _l.slope = _l.slopei + _c.kcrit * _c.beta / _DP * (_l.u - _c.ucrit) / _DP;
            // Tcrit := Tcrit + beta * T
            Tcrit = Tcrit + _c.beta * _l.T;
        } else {
            // rp := min (0, klow * (u0 - ulow ))
            _l.rp = _min(0, _c.klow * (_l.u - _c.ulow) / _DP);
            // slope := slopei
            _l.slope = _l.slopei;
            // Tcrit := max (0, Tcrit - beta * T)
            Tcrit = _max(0, Tcrit - _c.beta * _l.T);
        }

        // rlin := klin * u0 # lower bound between t0 and t1
        _l.rlin = _c.klin * _l.u / _DP;
        // ri := max(ri , rlin )
        ri = _max(ri , _l.rlin);
        // r0 := ri + rp # interest rate at t0 ignoring lower bound
        _l.r0 = ri + _l.rp;
        // r1 := r0 + slope *T # what interest rate would be at t1 ignoring lower bound
        _l.r1 = _l.r0 + _l.slope * _l.T;

        // Calculating the compound interest

        if (_l.r0 >= _l.rlin && _l.r1 >= _l.rlin) {
            // lower bound isn’t activated
            // rcomp := exp (( r0 + r1) * T / 2) - 1
            _l.x = (_l.r0 + _l.r1) * _l.T / 2;
        } else if (_l.r0 < _l.rlin && _l.r1 < _l.rlin) {
            // lower bound is active during the whole time
            // rcomp := exp( rlin * T) - 1
            _l.x = _l.rlin * _l.T;
        } else if (_l.r0 >= _l.rlin && _l.r1 < _l.rlin) {
            // lower bound is active after some time
            // rcomp := exp( rlin *T - (r0 - rlin )^2/ slope /2) - 1
            _l.x = _l.rlin * _l.T - (_l.r0 - _l.rlin)**2 / _l.slope / 2;
        } else {
            // lower bound is active before some time
            // rcomp := exp( rlin *T + (r1 - rlin )^2/ slope /2) - 1
            _l.x = _l.rlin * _l.T + (_l.r1 - _l.rlin)**2 / _l.slope / 2;
        }

        // ri := max(ri + slopei * T, rlin )
        ri = _max(ri + _l.slopei * _l.T, _l.rlin);

        // Checking for the overflow below. In case of the overflow, ri and Tcrit will be set back to zeros. Rcomp is
        // calculated to not make an overflow in totalBorrowedAmount, totalDeposits.
        (rcomp, overflow) = _calculateRComp(_totalDeposits, _totalBorrowAmount, _l.x);

        if (overflow) {
            ri = 0;
            Tcrit = 0;
        }
    }

    /// @dev set config for silo and asset
    function _setConfig(address _silo, address _asset, Config memory _config) internal virtual {
        int256 _DP = int256(DP);

        if (_config.uopt <= 0 || _config.uopt >= _DP) revert InvalidUopt();
        if (_config.ucrit <= _config.uopt || _config.ucrit >= _DP) revert InvalidUcrit();
        if (_config.ulow <= 0 || _config.ulow >= _config.uopt) revert InvalidUlow();
        if (_config.ki < 0) revert InvalidKi();
        if (_config.kcrit < 0) revert InvalidKcrit();
        if (_config.klow < 0) revert InvalidKlow();
        if (_config.klin < 0) revert InvalidKlin();
        if (_config.beta < 0) revert InvalidBeta();
        if (_config.ri < 0) revert InvalidRi();
        if (_config.Tcrit < 0) revert InvalidTcrit();

        config[_silo][_asset] = _config;
        emit ConfigUpdate(_silo, _asset, _config);
    }

    /* solhint-enable */

    /// @dev checks for the overflow in rcomp calculations, accruedInterest, totalDeposits and totalBorrowedAmount.
    /// In case of the overflow, rcomp is reduced to make totalDeposits and totalBorrowedAmount <= 2**196.
    function _calculateRComp(
        uint256 _totalDeposits,
        uint256 _totalBorrowAmount,
        int256 _x
    ) internal pure virtual returns (uint256 rcomp, bool overflow) {
        int256 rcompSigned;

        if (_x >= X_MAX) {
            rcomp = RCOMP_MAX;
            // overflow, but not return now. It counts as an overflow to reset model parameters,
            // but later on we can get overflow worse.
            overflow = true;
        } else {
            rcompSigned = _x.exp() - int256(DP);
            rcomp = rcompSigned > 0 ? rcompSigned.toUint256() : 0;
        }

        unchecked {
            // maxAmount = max(_totalDeposits, _totalBorrowAmount) to see
            // if any of this variables overflow in result.
            uint256 maxAmount = _totalDeposits > _totalBorrowAmount ? _totalDeposits : _totalBorrowAmount;

            if (maxAmount >= ASSET_DATA_OVERFLOW_LIMIT) {
                return (0, true);
            }

            uint256 rcompMulTBA = rcomp * _totalBorrowAmount;

            if (rcompMulTBA == 0) {
                return (rcomp, overflow);
            }

            if (
                rcompMulTBA / rcomp != _totalBorrowAmount ||
                rcompMulTBA / DP > ASSET_DATA_OVERFLOW_LIMIT - maxAmount
            ) {
                rcomp = (ASSET_DATA_OVERFLOW_LIMIT - maxAmount) * DP / _totalBorrowAmount;

                return (rcomp, true);
            }
        }
    }

    /// @dev Returns the largest of two numbers
    function _max(int256 a, int256 b) internal pure virtual returns (int256) {
        return a > b ? a : b;
    }

    /// @dev Returns the smallest of two numbers
    function _min(int256 a, int256 b) internal pure virtual returns (int256) {
        return a < b ? a : b;
    }
}