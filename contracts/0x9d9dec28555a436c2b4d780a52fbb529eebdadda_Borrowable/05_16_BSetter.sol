pragma solidity =0.5.16;

import "./BStorage.sol";
import "./PoolToken.sol";
import "./interfaces/IFactory.sol";

contract BSetter is PoolToken, BStorage {
    uint256 public constant RESERVE_FACTOR_MAX = 0.20e18; //20%
    uint256 public constant KINK_UR_MIN = 0.50e18; //50%
    uint256 public constant KINK_UR_MAX = 0.99e18; //99%
    uint256 public constant ADJUST_SPEED_MIN = 0.05787037e12; //0.5% per day
    uint256 public constant ADJUST_SPEED_MAX = 115.74074e12; //1000% per day

    event NewReserveFactor(uint256 newReserveFactor);
    event NewKinkUtilizationRates(uint256 newKinkUtilizationRateLower, uint256 newKinkUtilizationRateUpper);
    event NewAdjustSpeed(uint256 newAdjustSpeed);
    event NewBorrowTracker(address newBorrowTracker);

    // called once by the factory at time of deployment
    function _initialize(
        string calldata _name,
        string calldata _symbol,
        address _underlying,
        address _collateral
    ) external {
        require(msg.sender == factory, "Tarot: UNAUTHORIZED"); // sufficient check
        _setName(_name, _symbol);
        underlying = _underlying;
        collateral = _collateral;
        exchangeRateLast = initialExchangeRate;
    }

    function _setReserveFactor(uint256 newReserveFactor) external nonReentrant {
        _checkSetting(newReserveFactor, 0, RESERVE_FACTOR_MAX);
        reserveFactor = newReserveFactor;
        emit NewReserveFactor(newReserveFactor);
    }

    function _setKinkUtilizationRates(uint256 newKinkUtilizationRateLower, uint256 newKinkUtilizationRateUpper)
        external
        nonReentrant
    {
        _checkSetting(newKinkUtilizationRateLower, KINK_UR_MIN, newKinkUtilizationRateUpper);
        _checkSetting(newKinkUtilizationRateUpper, newKinkUtilizationRateLower, KINK_UR_MAX);
        kinkUtilizationRateLower = newKinkUtilizationRateLower;
        kinkUtilizationRateUpper = newKinkUtilizationRateUpper;
        emit NewKinkUtilizationRates(newKinkUtilizationRateLower, newKinkUtilizationRateUpper);
    }

    function _setAdjustSpeed(uint256 newAdjustSpeed) external nonReentrant {
        _checkSetting(newAdjustSpeed, ADJUST_SPEED_MIN, ADJUST_SPEED_MAX);
        adjustSpeed = newAdjustSpeed;
        emit NewAdjustSpeed(newAdjustSpeed);
    }

    function _setBorrowTracker(address newBorrowTracker) external nonReentrant {
        _checkAdmin();
        borrowTracker = newBorrowTracker;
        emit NewBorrowTracker(newBorrowTracker);
    }

    function _checkSetting(
        uint256 parameter,
        uint256 min,
        uint256 max
    ) internal view {
        _checkAdmin();
        require(parameter >= min, "Tarot: INVALID_SETTING");
        require(parameter <= max, "Tarot: INVALID_SETTING");
    }

    function _checkAdmin() internal view {
        require(msg.sender == IFactory(factory).admin(), "Tarot: UNAUTHORIZED");
    }
}