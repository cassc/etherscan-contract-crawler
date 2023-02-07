// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;
pragma abicoder v2;

import {IIchiVaultSettingsV1} from "./IIchiVaultSettingsV1.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract IchiVaultSettingsV1 is IIchiVaultSettingsV1, Ownable {

    // wait time after a rebalance has been initiated before the actual rebalance is executed
    uint256 public override executionDelay; // for example, 300 = 5 minutes

    // TWAPs used for measuring volatility
    uint32 public override twapSlow; // for example, 3600 = 1 hour
    uint32 public override twapFast; // for example, 300 = 5 minutes

    // minimum time between rebalances (in seconds)
    uint256 public override minTimeBetweenRebalances;

    // rebalance actions volatility thresholds
    uint256 public override extremeVolatility; // for example, 10 * ONE_PCT;
    uint256 public override highVolatility; // for example, 5 * ONE_PCT;
    uint256 public override someVolatility; // for example, ONE_PCT;
    uint256 public override dtrDelta; // for example, 5 * ONE_PCT;
    uint256 public override priceChange; // for example, 2 * ONE_PCT;
    address public override gasOracle; // chainlink fast gas oracle, NULL_ADDRESS means no oracle is used;
    uint256 public override gasTolerance; // for example, 40 gwei;

    /// @param _executionDelay wait time after a rebalance has been initiated before the actual rebalance is executed (for example, 300 = 5 minutes)
    /// @param _twapSlow slow TWAP used for measuring volatility (for example, 3600 = 1 hour)
    /// @param _twapFast fast TWAPs used for measuring volatility (for example, 300 = 5 minutes)
    /// @param _extremeVolatility price move that causes the strategy to lock up (for example, 1000 = 10%)
    /// @param _highVolatility price move that causes the strategy to go defensive (for example, 500 = 5%)
    /// @param _someVolatility price move that causes the strategy to delay rebalance (for example, 100 = 1%)
    /// @param _dtrDelta max tolerated change in DTR of an under inventory vault without a rebalance (for example, 500 = 5%)
    /// @param _priceChange change in price that may indicate a need for rebalance (for example, 200 = 2%)
    /// @param _minTimeBetweenRebalances min time that should pass between two normal rebalances (in seconds)
    /// @param _gasOracle chainlink fast gas oracle. NULL_ADDRESS means no oracle is used
    /// @param _gasTolerance gas tolerance threshold for the rebalance transaction (for example, 40 gwei)
    constructor(
        uint256 _executionDelay,
        uint32 _twapSlow,
        uint32 _twapFast,
        uint256 _extremeVolatility,
        uint256 _highVolatility,
        uint256 _someVolatility,
        uint256 _dtrDelta,
        uint256 _priceChange,
        uint256 _minTimeBetweenRebalances,
        address _gasOracle,
        uint256 _gasTolerance
    ) {
        require(_twapSlow >= 300 && _twapFast <= 3600 && _twapSlow > _twapFast, "invalid twaps");
        require(_executionDelay <= 3600, "invalid delayed execution setting");
        require(_extremeVolatility >= _highVolatility && _highVolatility > _someVolatility, "invalid volatility settings");
        require(_dtrDelta <= 10000, "invalid DTR delta");
        require(_gasTolerance > 0, "invalid gasTolerance");

        twapSlow = _twapSlow;
        twapFast = _twapFast;

        executionDelay = _executionDelay;

        extremeVolatility = _extremeVolatility;
        highVolatility = _highVolatility;
        someVolatility = _someVolatility;
        dtrDelta = _dtrDelta;
        priceChange = _priceChange;
        minTimeBetweenRebalances = _minTimeBetweenRebalances;
        gasOracle = _gasOracle;
        gasTolerance = _gasTolerance;

        emit DeploySettings(
            msg.sender,
            _executionDelay,
            _twapSlow,
            _twapFast,
            _extremeVolatility,
            _highVolatility,
            _someVolatility,
            _dtrDelta,
            _priceChange,
            _minTimeBetweenRebalances,
            _gasOracle,
            _gasTolerance
        );
    }

    /// Sets executionDelay
    /// @param _executionDelay wait time after a rebalance has been initiated before the actual rebalance is executed (for example, 300 = 5 minutes)
    function setExecutionDelay(uint256 _executionDelay) external override onlyOwner {
        require(_executionDelay <= 3600, "invalid delayed execution setting");
        executionDelay = _executionDelay;
        emit SetExecutionDelay(msg.sender, executionDelay);
    }

    /// Sets twapSlow
    /// @param _twapSlow slow TWAP used for measuring volatility (for example, 3600 = 1 hour)
    function setTwapSlow(uint32 _twapSlow) external override onlyOwner {
        require(_twapSlow >= 300 && _twapSlow > twapFast, "invalid twaps");
        twapSlow = _twapSlow;
        emit SetTwapSlow(msg.sender, twapSlow);
    }

    /// Sets twapFast
    /// @param _twapFast fast TWAPs used for measuring volatility (for example, 300 = 5 minutes)
    function setTwapFast(uint32 _twapFast) external override onlyOwner {
        require(_twapFast <= 3600 && twapSlow > _twapFast, "invalid twaps");
        twapFast = _twapFast;
        emit SetTwapFast(msg.sender, twapFast);
    }

    /// Sets extremeVolatility
    /// @param _extremeVolatility price move that causes the strategy to lock up (for example, 1000 = 10%)
    function setExtremeVolatility(uint256 _extremeVolatility) external override onlyOwner {
        require(_extremeVolatility >= highVolatility, "invalid volatility settings");
        extremeVolatility = _extremeVolatility;
        emit SetExecutionDelay(msg.sender, executionDelay);
    }

    /// Sets highVolatility
    /// @param _highVolatility price move that causes the strategy to go defensive (for example, 500 = 5%)
    function setHighVolatility(uint256 _highVolatility) external override onlyOwner {
        require(extremeVolatility >= _highVolatility && _highVolatility > someVolatility, "invalid volatility settings");
        highVolatility = _highVolatility;
        emit SetHighVolatility(msg.sender, highVolatility);
    }

    /// Sets someVolatility
    /// @param _someVolatility price move that causes the strategy to delay rebalance (for example, 100 = 1%)
    function setSomeVolatility(uint256 _someVolatility) external override onlyOwner {
        require(highVolatility > _someVolatility, "invalid volatility settings");
        someVolatility = _someVolatility;
        emit SetSomeVolatility(msg.sender, someVolatility);
    }

    /// Sets dtrDelta
    /// @param _dtrDelta max tolerated change in DTR of an under inventory vault without a ebalance (for example, 500 = 5%)
    function setDtrDelta(uint256 _dtrDelta) external override onlyOwner {
        require(_dtrDelta <= 10000, "invalid DTR delta");
        dtrDelta = _dtrDelta;
        emit SetDtrDelta(msg.sender, dtrDelta);
    }

    /// Sets priceChange
    /// @param _priceChange change in price that may indicate a need for rebalance (for example, 200 = 2%)
    function setPriceChange(uint256 _priceChange) external override onlyOwner {
        priceChange = _priceChange;
        emit SetPriceChange(msg.sender, priceChange);
    }

    /// Sets minTimeBetweenRebalances
    /// @param _minTimeBetweenRebalances minimum time between rebalances (in seconds)
    function setMinTimeBetweenRebalances(uint256 _minTimeBetweenRebalances) external override onlyOwner {
        minTimeBetweenRebalances = _minTimeBetweenRebalances;
        emit SetMinTimeBetweenRebalances(msg.sender, _minTimeBetweenRebalances);
    }

    /// Sets the gas oracle
    /// @param _gasOracle chainlink fast gas oracle. NULL_ADDRESS means no oracle is used
    function setGasOracle(address _gasOracle) external override onlyOwner {
        gasOracle = _gasOracle;
        emit SetGasOracle(msg.sender, _gasOracle);
    }

    /// Sets the gas tolerance threshold for the rebalance transaction
    /// @param _gasTolerance gas tolerance threshold in gwei
    function setGasTolerance(uint256 _gasTolerance) external override onlyOwner {
        require(_gasTolerance > 0, "invalid gasTolerance");
        gasTolerance = _gasTolerance;
        emit SetGasTolerance(msg.sender, _gasTolerance);
    }

    /// Sets all the settings in one go
    /// @param _executionDelay wait time after a rebalance has been initiated before the actual rebalance is executed (for example, 300 = 5 minutes)
    /// @param _twapSlow slow TWAP used for measuring volatility (for example, 3600 = 1 hour)
    /// @param _twapFast fast TWAPs used for measuring volatility (for example, 300 = 5 minutes)
    /// @param _extremeVolatility price move that causes the strategy to lock up (for example, 1000 = 10%)
    /// @param _highVolatility price move that causes the strategy to go defensive (for example, 500 = 5%)
    /// @param _someVolatility price move that causes the strategy to delay rebalance (for example, 100 = 1%)
    /// @param _dtrDelta max tolerated change in DTR of an under inventory vault without a rebalance (for example, 500 = 5%)
    /// @param _priceChange change in price that may indicate a need for rebalance (for example, 200 = 2%)
    /// @param _minTimeBetweenRebalances min time that should pass between two normal rebalances (in seconds)
    /// @param _gasOracle chainlink fast gas oracle. NULL_ADDRESS means no oracle is used
    /// @param _gasTolerance gas tolerance threshold for the rebalance transaction (for example, 40 gwei)
    function setAll(
        uint256 _executionDelay,
        uint32 _twapSlow,
        uint32 _twapFast,
        uint256 _extremeVolatility,
        uint256 _highVolatility,
        uint256 _someVolatility,
        uint256 _dtrDelta,
        uint256 _priceChange,
        uint256 _minTimeBetweenRebalances,
        address _gasOracle,
        uint256 _gasTolerance
    ) external override onlyOwner {
        require(_twapSlow >= 300 && _twapFast <= 3600 && _twapSlow > _twapFast, "invalid twaps");
        require(_executionDelay <= 3600, "invalid delayed execution setting");
        require(_extremeVolatility >= _highVolatility && _highVolatility > _someVolatility, "invalid volatility settings");
        require(_dtrDelta <= 10000, "invalid DTR delta");
        require(_gasTolerance > 0, "invalid gasTolerance");

        twapSlow = _twapSlow;
        twapFast = _twapFast;

        executionDelay = _executionDelay;

        extremeVolatility = _extremeVolatility;
        highVolatility = _highVolatility;
        someVolatility = _someVolatility;
        dtrDelta = _dtrDelta;
        priceChange = _priceChange;
        minTimeBetweenRebalances = _minTimeBetweenRebalances;
        gasOracle = _gasOracle;
        gasTolerance = _gasTolerance;

        emit SetAll(
            msg.sender,
            _executionDelay,
            _twapSlow,
            _twapFast,
            _extremeVolatility,
            _highVolatility,
            _someVolatility,
            _dtrDelta,
            _priceChange,
            _minTimeBetweenRebalances,
            _gasOracle,
            _gasTolerance
        );
    }

}