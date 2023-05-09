// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./InterestRateModelXAI.sol";
import "./lib/EasyMathV2.sol";

interface IGenericInterestRateModel {
    function config(address _silo, address _asset) external view returns (IInterestRateModel.Config memory);
}

/// @title InterestRateModelV2
/// @notice Dynamic interest rate model implementation
/// @dev Model stores some Silo specific data. If model is replaced, it needs to set proper config after redeployment
/// for seamless service. Please refer to separate litepaper about model for design details.
/// @custom:security-contact [email protected]
contract InterestRateModelV2 is InterestRateModelXAI {
    using SafeCast for int256;
    using SafeCast for uint256;

    constructor(Config memory _config, address _owner) InterestRateModelXAI(_config) {
        if (_owner != address(0)) {
            transferOwnership(_owner);
        }
    }

    /// @dev migration method for models before InterestRateModelV2
    /// @param _silos array of Silos addresses for which config will be cloned
    /// @param _siloRepository SiloRepository addresses
    function migrationFromV1(address[] calldata _silos, ISiloRepository _siloRepository)
        external
        virtual
        onlyOwner
    {
        IInterestRateModel model;

        for (uint256 i; i < _silos.length;) {
            address[] memory assets = ISilo(_silos[i]).getAssets();

            if (address(model) == address(0)) {
                // assumption is that XAI is not first asset otherwise this optimisation will not work
                model = _siloRepository.getInterestRateModel(_silos[0], assets[0]);
            }

            for (uint256 j; j < assets.length;) {
                Config memory clonedConfig = IGenericInterestRateModel(address(model)).config(_silos[i], assets[j]);

                if (clonedConfig.uopt == 0) {
                    IInterestRateModel secondModel = _siloRepository.getInterestRateModel(_silos[i], assets[j]);
                    clonedConfig = IGenericInterestRateModel(address(secondModel)).config(_silos[i], assets[j]);
                }

                // in order not to clone empty config, check `uopt` - based on requirements it can not be 0
                if (clonedConfig.uopt != 0) {
                    // beta is divided by value of 4 for all configs, except stableLowCap, stableHighCap and bridgeXAI
                    // With current values of beta parameter, volatile assets will get their interest rate
                    // (proportional term) multiplied by 2 in one hour. Division of beta coefficient by 4 will result
                    // in changing time for to double from one hour to four hours, which will make the interest rate
                    // model behaviour less risky,
                    // If we will forget about integral term (which will have less impact in first hours of critical
                    // utilisation), proportional term will grow linear. It will double in first 4 hours,
                    // triple in 8, x4 in 12, etc.
                    if (clonedConfig.beta == 277777777777778) {
                        clonedConfig.beta = 69444444444444;
                    }

                    // when we `setConfig()` we call `accrueInterest()`
                    // we don't have to do it when we cloning, because config will not change
                    _setConfig(_silos[i], assets[j], clonedConfig);
                }

                unchecked { j++; }
            }

            unchecked { i++; }
        }
    }

    /// @inheritdoc IInterestRateModel
    function calculateCurrentInterestRate( // solhint-disable-line function-max-lines
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

        _l.u = EasyMathV2.calculateUtilization(DP, _totalDeposits, _totalBorrowAmount).toInt256();
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

        return _currentInterestRateCAP(rcur);
    }

    /// @inheritdoc IInterestRateModel
    function calculateCompoundInterestRateWithOverflowDetection( // solhint-disable-line function-max-lines
        Config memory _c,
        uint256 _totalDeposits,
        uint256 _totalBorrowAmount,
        uint256 _interestRateTimestamp,
        uint256 _blockTimestamp
    ) public pure virtual override returns (
        uint256 rcomp,
        int256 ri,
        int256 Tcrit, // solhint-disable-line var-name-mixedcase
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

        int256 _DP = int256(DP); // solhint-disable-line var-name-mixedcase

        _l.u = EasyMathV2.calculateUtilization(DP, _totalDeposits, _totalBorrowAmount).toInt256();

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

        // if we got a limit for rcomp, we reset Tcrit and Ri model parameters to zeros
        // Resetting parameters will make IR drop from 10k%/year to 100% per year and it will start growing again.
        // If we don’t reset, we will have to wait ~2 weeks to make IR drop (low utilisation ratio required).
        // So zeroing parameters is a only hope for a market to get well again, otherwise it will be almost impossible.
        bool capApplied;

        (rcomp, capApplied) = _compoundInterestRateCAP(rcomp, _l.T.toUint256());

        if (overflow || capApplied) {
            ri = 0;
            Tcrit = 0;
        }
    }

    /// @dev in order to keep methods pure and bee able to deploy easily new caps,
    /// that method with hardcoded CAP was created
    /// @notice limit for compounding interest rcomp := RCOMP_CAP * _l.T.
    /// The limit is simple. Let’s threat our interest rate model as the black box. And for past _l.T time we got
    /// a value for rcomp. We need to provide the top limit this value to take into account the limit for current
    /// interest. Let’s imagine, if we had maximum allowed interest for _l.T. `RCOMP_CAP * _l.T` will be the value of
    /// rcomp in this case, which will serve as the limit.
    /// If we got this limit, we should make Tcrit and Ri equal to zero, otherwise there is a low probability of the
    /// market going back below the limit.
    function _compoundInterestRateCAP(uint256 _rcomp, uint256 _t)
        internal
        pure
        virtual
        returns (uint256 updatedRcomp, bool capApplied) {
        // uint256 cap = 10**20 / (365 * 24 * 3600); // this is per-second rate because _l.T is in seconds.
        uint256 cap = 3170979198376 * _t;
        return _rcomp > cap ? (cap, true) : (_rcomp, false);
    }

    /// @notice limit for rcur - RCUR_CAP (FE/integrations, does not affect our protocol).
    /// This is the limit for current interest rate, we picked 10k% of interest per year. Interest rate model is working
    /// as expected before that threshold and simply sets the maximum value in case of limit.
    /// 10k% is a really significant threshold, which will mean the death of market in most of cases.
    /// Before 10k% interest rate can be good for certain market conditions.
    /// We don’t read the current interest rate in our protocol, because we care only about the interest we compounded
    /// over the past time since the last update. It is used in UI and other protocols integrations,
    /// for example investing strategies.
    function _currentInterestRateCAP(uint256 _rcur) internal pure virtual returns (uint256) {
        uint256 cap = 1e20; // 10**20; this is 10,000% APR in the 18-decimals format.
        return _rcur > cap ? cap : _rcur;
    }
}