// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@prb/math/contracts/PRBMathSD59x18.sol";
import "./InterestRateModelBase.sol";
import "../libraries/Trigonometry.sol";

/// @notice This contract represent interest rate model based on modulating cosine function
contract CosineInterestRateModel is InterestRateModelBase, Ownable {
    using SafeCast for uint256;
    using SafeCast for int256;
    using PRBMathSD59x18 for int256;

    /// @notice Type of the model
    string public constant TYPE = "Cosine";

    /// @notice Number one as 18-digit decimal
    int256 private constant ONE = 1e18;

    /// @notice Interest rate at zero utilization (as 18-digit decimal)
    uint256 public zeroRate;

    /// @notice Interest rate at full utilization (as 18-digit decimal)
    uint256 public fullRate;

    /// @notice Utilization at which minimal interest rate applies
    uint256 public kink;

    /// @notice Interest rate at kink utilization (as 18-digit decimal)
    uint256 public kinkRate;

    // EVENTS

    // Event emitted when model's parameters are adjusted
    event Configured(
        uint256 zeroRate,
        uint256 fullRate,
        uint256 kink,
        uint256 kinkRate
    );

    // CONSTRUCTOR

    /// @notice Contract's constructor
    /// @param zeroRate_ Zero rate value
    /// @param fullRate_ Full rate value
    /// @param kink_ Kink value
    /// @param kinkRate_ Kink rate value
    constructor(
        uint256 zeroRate_,
        uint256 fullRate_,
        uint256 kink_,
        uint256 kinkRate_
    ) {
        require(kink_ <= ONE.toUint256(), "GTO");

        zeroRate = _perSecond(zeroRate_);
        fullRate = _perSecond(fullRate_);
        kink = kink_;
        kinkRate = _perSecond(kinkRate_);

        emit Configured(zeroRate_, fullRate_, kink_, kinkRate_);
    }

    // PUBLIC FUNCTIONS

    /// @notice Function that calculates borrow interest rate for pool
    /// @param balance Total pool balance
    /// @param borrows Total pool borrows
    /// @param reserves Sum of pool reserves and insurance
    /// @return Borrow rate per second
    function getBorrowRate(
        uint256 balance,
        uint256 borrows,
        uint256 reserves
    ) public view override returns (uint256) {
        int256 util = utilizationRate(balance, borrows, reserves).toInt256();
        int256 iKink = kink.toInt256();
        int256 theta = util <= iKink ? int256(0) : ONE;
        int256 n = -ONE.div(iKink.log2());
        int256 cosX = util == 0
            ? ONE
            : Trigonometry.cos((2 * Trigonometry.PI).mul(util.pow(n)));
        int256 rate = (zeroRate.toInt256().mul(ONE + cosX).mul(ONE - theta) +
            fullRate.toInt256().mul(ONE + cosX).mul(theta) +
            kinkRate.toInt256().mul(ONE - cosX)) / 2;
        uint256 uRate = rate.toUint256();
        require(uRate <= MAX_RATE, "HMR");
        return uRate;
    }

    // RESTRICTED FUNCTIONS

    /// @notice Owner's function to configure model's parameters
    /// @param zeroRate_ Zero rate value
    /// @param fullRate_ Full rate value
    /// @param kink_ Kink value
    /// @param kinkRate_ Kink rate value
    function configure(
        uint256 zeroRate_,
        uint256 fullRate_,
        uint256 kink_,
        uint256 kinkRate_
    ) external onlyOwner {
        require(kink_ <= ONE.toUint256(), "GTO");

        zeroRate = _perSecond(zeroRate_);
        fullRate = _perSecond(fullRate_);
        kink = kink_;
        kinkRate = _perSecond(kinkRate_);

        emit Configured(zeroRate_, fullRate_, kink_, kinkRate_);
    }
}