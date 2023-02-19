pragma solidity =0.5.16;

import "./CStorage.sol";
import "./PoolToken.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/ITarotSolidlyPriceOracleV2.sol";

contract CSetter is PoolToken, CStorage {
    uint256 public constant SAFETY_MARGIN_MIN = 1.00e18; //safetyMargin: 100%
    uint256 public constant SAFETY_MARGIN_MAX = 1.50e18; //safetyMargin: 150%
    uint256 public constant LIQUIDATION_INCENTIVE_MIN = 1.00e18; //100%
    uint256 public constant LIQUIDATION_INCENTIVE_MAX = 1.05e18; //105%
	uint256 public constant LIQUIDATION_FEE_MAX = 0.05e18; //5%
    uint256 public constant M_TOLERANCE_MIN = 1;
    uint256 public constant M_TOLERANCE_MAX = 1e12;

    event NewSafetyMargin(uint256 newSafetyMargin);
    event NewLiquidationIncentive(uint256 newLiquidationIncentive);
    event NewLiquidationFee(uint256 newLiquidationFee);
    event NewMTolerance(uint256 newMTolerance);

    // called once by the factory at the time of deployment
    function _initialize(
        string calldata _name,
        string calldata _symbol,
        address _underlying,
        address _borrowable0,
        address _borrowable1
    ) external {
        require(msg.sender == factory, "Tarot: UNAUTHORIZED"); // sufficient check
        _setName(_name, _symbol);
        underlying = _underlying;
        borrowable0 = _borrowable0;
        borrowable1 = _borrowable1;
        tarotPriceOracle = IFactory(factory).tarotPriceOracle();
    }

    function _setSafetyMargin(uint256 newSafetyMargin)
        external
        nonReentrant
    {
        _checkSetting(
            newSafetyMargin,
            SAFETY_MARGIN_MIN,
            SAFETY_MARGIN_MAX
        );
        safetyMargin = newSafetyMargin;
        emit NewSafetyMargin(newSafetyMargin);
    }

    function _setLiquidationIncentive(uint256 newLiquidationIncentive)
        external
        nonReentrant
    {
        _checkSetting(
            newLiquidationIncentive,
            LIQUIDATION_INCENTIVE_MIN,
            LIQUIDATION_INCENTIVE_MAX
        );
        liquidationIncentive = newLiquidationIncentive;
        emit NewLiquidationIncentive(newLiquidationIncentive);
    }

    function _setLiquidationFee(uint256 newLiquidationFee)
        external
        nonReentrant
    {
        _checkSetting(
            newLiquidationFee,
            0,
            LIQUIDATION_FEE_MAX
        );
        liquidationFee = newLiquidationFee;
        emit NewLiquidationFee(newLiquidationFee);
    }

    function _setMTolerance(uint256 newMTolerance)
        external
        nonReentrant
    {
        _checkSetting(
            newMTolerance,
            M_TOLERANCE_MIN,
            M_TOLERANCE_MAX
        );
        mTolerance = newMTolerance;
        emit NewMTolerance(newMTolerance);
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