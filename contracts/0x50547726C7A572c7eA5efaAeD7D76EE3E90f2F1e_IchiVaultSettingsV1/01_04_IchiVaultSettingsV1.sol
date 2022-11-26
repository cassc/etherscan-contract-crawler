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

    // rebalance actions volatility thresholds
    uint256 public override extremeVolatility; // for example, 10 * ONE_PCT;
    uint256 public override highVolatility; // for example, 5 * ONE_PCT;
    uint256 public override someVolatility; // for example, ONE_PCT;
    uint256 public override dtrDelta; // for example, 5 * ONE_PCT;
    uint256 public override priceChange; // for example, 2 * ONE_PCT;

    /// @param _executionDelay wait time after a rebalance has been initiated before the actual rebalance is executed (for example, 300 = 5 minutes)
    /// @param _twapSlow slow TWAP used for measuring volatility (for example, 3600 = 1 hour)
    /// @param _twapFast fast TWAPs used for measuring volatility (for example, 300 = 5 minutes)
    /// @param _extremeVolatility price move that causes the strategy to lock up (for example, 1000 = 10%)
    /// @param _highVolatility price move that causes the strategy to go defensive (for example, 500 = 5%)
    /// @param _someVolatility price move that causes the strategy to delay rebalance (for example, 100 = 1%)
    /// @param _dtrDelta max tolerated change in DTR of an under inventory vault without a rebalance (for example, 500 = 5%)
    /// @param _priceChange change in price that may indicate a need for rebalance (for example, 200 = 2%)
    constructor(
        uint256 _executionDelay,
        uint32 _twapSlow,
        uint32 _twapFast,
        uint256 _extremeVolatility,
        uint256 _highVolatility,
        uint256 _someVolatility,
        uint256 _dtrDelta,
        uint256 _priceChange
    ) {
        require(_twapSlow >= 300 && _twapFast <= 3600 && _twapSlow > _twapFast, "invalid twaps");
        require(_executionDelay <= 3600, "invalid delayed execution setting");
        require(_extremeVolatility >= _highVolatility && _highVolatility > _someVolatility, "invalid volatility settings");
        require(_dtrDelta <= 10000, "invalid DTR delta");

        twapSlow = _twapSlow;
        twapFast = _twapFast;

        executionDelay = _executionDelay;

        extremeVolatility = _extremeVolatility;
        highVolatility = _highVolatility;
        someVolatility = _someVolatility;
        dtrDelta = _dtrDelta;
        priceChange = _priceChange;

        emit DeploySettings(
            msg.sender,
            _executionDelay,
            _twapSlow,
            _twapFast,
            _extremeVolatility,
            _highVolatility,
            _someVolatility,
            _dtrDelta,
            _priceChange
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

    /// Sets all the settings in one go
    /// @param _executionDelay wait time after a rebalance has been initiated before the actual rebalance is executed (for example, 300 = 5 minutes)
    /// @param _twapSlow slow TWAP used for measuring volatility (for example, 3600 = 1 hour)
    /// @param _twapFast fast TWAPs used for measuring volatility (for example, 300 = 5 minutes)
    /// @param _extremeVolatility price move that causes the strategy to lock up (for example, 1000 = 10%)
    /// @param _highVolatility price move that causes the strategy to go defensive (for example, 500 = 5%)
    /// @param _someVolatility price move that causes the strategy to delay rebalance (for example, 100 = 1%)
    /// @param _dtrDelta max tolerated change in DTR of an under inventory vault without a rebalance (for example, 500 = 5%)
    /// @param _priceChange change in price that may indicate a need for rebalance (for example, 200 = 2%)
    function setAll(
        uint256 _executionDelay,
        uint32 _twapSlow,
        uint32 _twapFast,
        uint256 _extremeVolatility,
        uint256 _highVolatility,
        uint256 _someVolatility,
        uint256 _dtrDelta,
        uint256 _priceChange
    ) external override onlyOwner {
        require(_twapSlow >= 300 && _twapFast <= 3600 && _twapSlow > _twapFast, "invalid twaps");
        require(_executionDelay <= 3600, "invalid delayed execution setting");
        require(_extremeVolatility >= _highVolatility && _highVolatility > _someVolatility, "invalid volatility settings");
        require(_dtrDelta <= 10000, "invalid DTR delta");

        twapSlow = _twapSlow;
        twapFast = _twapFast;

        executionDelay = _executionDelay;

        extremeVolatility = _extremeVolatility;
        highVolatility = _highVolatility;
        someVolatility = _someVolatility;
        dtrDelta = _dtrDelta;
        priceChange = _priceChange;

        emit SetAll(
            msg.sender,
            _executionDelay,
            _twapSlow,
            _twapFast,
            _extremeVolatility,
            _highVolatility,
            _someVolatility,
            _dtrDelta,
            _priceChange
        );
    }

}