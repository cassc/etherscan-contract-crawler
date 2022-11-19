// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../governance/InitializableGovernable.sol";
import "../registry/TokenRegistry.sol";

// import "@nomiclabs/buidler/console.sol";
// solhint-disable-next-line max-states-count
contract GlobalConfig is InitializableGovernable {
    using SafeMath for uint256;

    // Constants
    uint256 public constant MIN_APR = 3; // 3%
    uint256 public constant MAX_APR = 300; // 300%

    // Following storage should be initialized per pool
    // -------------------------------------------------
    uint256 public minReserveRatio = 10; // 10%
    uint256 public maxReserveRatio = 20; // 20%
    uint256 public liquidationThreshold = 85; // 85%
    uint256 public liquidationDiscountRatio = 95; // 95%
    uint256 public compoundSupplyRateWeights = 5; // 0.5
    uint256 public compoundBorrowRateWeights = 5; // 0.5
    uint256 public rateCurveConstant = 3 * 10**16; // 3
    uint256 public deFinerRate = 10; // 10%

    address public bank; // the Bank contract
    address public savingAccount; // the SavingAccount contract
    address public tokenRegistry; // the TokenRegistry contract
    address public accounts; // the Accounts contract
    address public poolRegistry; // the PoolRegistry contract
    // -------------------------------------------------

    event MinReserveRatioUpdated(uint256 indexed minReserveRatio);
    event MaxReserveRatioUpdated(uint256 indexed maxReserveRatio);
    event LiquidationThresholdUpdated(uint256 indexed liquidationThreshold);
    event LiquidationDiscountRatioUpdated(uint256 indexed liquidationDiscountRatio);
    event CompoundSupplyRateWeightsUpdated(uint256 indexed compoundSupplyRateWeights);
    event CompoundBorrowRateWeightsUpdated(uint256 indexed compoundBorrowRateWeights);
    event MinMaxBorrowAPRUpdated(uint256 indexed minBorrowAPRPercentage, uint256 maxBorrowAPRPercentage);
    event ConstantUpdated(address indexed constants);
    event DeFinerRateUpdated(uint256 indexed deFinerRate);
    event ChainLinkUpdated(address indexed chainLink);

    modifier onlyAuthroized() {
        require(msg.sender == poolRegistry || msg.sender == governor(), "not authorized");
        _;
    }

    function initialize(
        address _gemGlobalConfig,
        address _bank,
        address _savingAccount,
        address _tokenRegistry,
        address _accounts,
        address _poolRegistry
    ) external {
        _initialize(_gemGlobalConfig);
        _initDefaultStorageValues();
        bank = _bank;
        savingAccount = _savingAccount;
        tokenRegistry = _tokenRegistry;
        accounts = _accounts;
        poolRegistry = _poolRegistry;
    }

    /**
     * @dev Initialize storage variables with default values when GlobalConfig
     * proxy is deployed per pool
     */
    function _initDefaultStorageValues() private {
        minReserveRatio = 10; // 10%
        maxReserveRatio = 20; // 20%
        liquidationThreshold = 85; // 85%
        liquidationDiscountRatio = 95; // 95%
        compoundSupplyRateWeights = 5; // 0.5
        compoundBorrowRateWeights = 5; // 0.5
        rateCurveConstant = 3 * 10**16; // 3
        deFinerRate = 10; // 10%
    }

    /**
     * Update the minimum reservation reatio
     * @param _minReserveRatio the new value of the minimum reservation ratio
     */
    function updateMinReserveRatio(uint256 _minReserveRatio) external onlyGov {
        if (_minReserveRatio == minReserveRatio) return;

        require(_minReserveRatio > 0 && _minReserveRatio < maxReserveRatio, "Invalid min reserve ratio.");
        minReserveRatio = _minReserveRatio;

        emit MinReserveRatioUpdated(_minReserveRatio);
    }

    /**
     * Update the maximum reservation reatio
     * @param _maxReserveRatio the new value of the maximum reservation ratio
     */
    function updateMaxReserveRatio(uint256 _maxReserveRatio) external onlyGov {
        if (_maxReserveRatio == maxReserveRatio) return;

        require(_maxReserveRatio > minReserveRatio && _maxReserveRatio < 100, "Invalid max reserve ratio.");
        maxReserveRatio = _maxReserveRatio;

        emit MaxReserveRatioUpdated(_maxReserveRatio);
    }

    /**
     * Update the liquidation threshold, i.e. the LTV that will trigger the liquidation.
     * @param _liquidationThreshold the new threshhold value
     */
    function updateLiquidationThreshold(uint256 _liquidationThreshold) external onlyGov {
        if (_liquidationThreshold == liquidationThreshold) return;

        require(
            _liquidationThreshold > 0 && _liquidationThreshold < liquidationDiscountRatio,
            "Invalid liquidation threshold."
        );
        liquidationThreshold = _liquidationThreshold;

        emit LiquidationThresholdUpdated(_liquidationThreshold);
    }

    /**
     * Update the liquidation discount
     * @param _liquidationDiscountRatio the new liquidation discount
     */
    function updateLiquidationDiscountRatio(uint256 _liquidationDiscountRatio) external onlyGov {
        if (_liquidationDiscountRatio == liquidationDiscountRatio) return;

        require(
            _liquidationDiscountRatio > liquidationThreshold && _liquidationDiscountRatio < 100,
            "Invalid liquidation discount ratio."
        );
        liquidationDiscountRatio = _liquidationDiscountRatio;

        emit LiquidationDiscountRatioUpdated(_liquidationDiscountRatio);
    }

    /**
     * Medium value of the reservation ratio, which is the value that the pool try to maintain.
     */
    function midReserveRatio() public view returns (uint256) {
        return minReserveRatio.add(maxReserveRatio).div(2);
    }

    function updateCompoundSupplyRateWeights(uint256 _compoundSupplyRateWeights) external onlyGov {
        compoundSupplyRateWeights = _compoundSupplyRateWeights;

        emit CompoundSupplyRateWeightsUpdated(_compoundSupplyRateWeights);
    }

    function updateCompoundBorrowRateWeights(uint256 _compoundBorrowRateWeights) external onlyGov {
        compoundBorrowRateWeights = _compoundBorrowRateWeights;

        emit CompoundBorrowRateWeightsUpdated(_compoundBorrowRateWeights);
    }

    function updateMinMaxBorrowAPR(uint256 _minBorrowAPRInPercent, uint256 _maxBorrowAPRInPercent)
        external
        onlyAuthroized
    {
        // borrowAPR
        require(_minBorrowAPRInPercent <= _maxBorrowAPRInPercent, "_minBorrowAPRInPercent > _maxBorrowAPRInPercent");
        require(_minBorrowAPRInPercent >= MIN_APR, "_minBorrowAPRInPercent is out-of-bound");
        require(_maxBorrowAPRInPercent <= MAX_APR, "_maxBorrowAPRInPercent is out-of-bound");

        // set `rateCurveConstant` storage
        rateCurveConstant = _minBorrowAPRInPercent * 10**16; // because 10^18 = 100%
        uint256 _maxBorrowAPR = _maxBorrowAPRInPercent * 10**16;
        IBank(bank).configureMaxUtilToCalcBorrowAPR(_maxBorrowAPR);

        emit MinMaxBorrowAPRUpdated(_minBorrowAPRInPercent, _maxBorrowAPRInPercent);
    }

    function updatedeFinerRate(uint256 _deFinerRate) external onlyGov {
        require(_deFinerRate <= 100, "_deFinerRate cannot exceed 100");
        deFinerRate = _deFinerRate;

        emit DeFinerRateUpdated(_deFinerRate);
    }
}