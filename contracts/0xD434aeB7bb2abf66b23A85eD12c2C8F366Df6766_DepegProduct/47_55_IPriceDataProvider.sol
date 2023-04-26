// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IPriceDataProvider {

    enum ComplianceState {
        Undefined,
        Initializing,
        Valid,
        FailedOnce,
        FailedMultipleTimes
    }

    enum StabilityState {
        Undefined,
        Initializing,
        Stable,
        Triggered,
        Depegged
    }

    enum EventType {
        Undefined,
        Update,
        TriggerEvent,
        RecoveryEvent,
        DepegEvent
    }

    event LogPriceDataDeviationExceeded (
        uint256 priceId,
        uint256 priceDeviation,
        uint256 currentPrice,
        uint256 lastPrice);

    event LogPriceDataHeartbeatExceeded (
        uint256 priceId,
        uint256 timeDifference,
        uint256 currentCreatedAt,
        uint256 lastCreatedAt);

    event LogPriceDataTriggered (
        uint256 priceId,
        uint256 price,
        uint256 triggeredAt);

    event LogPriceDataRecovered (
        uint256 priceId,
        uint256 price,
        uint256 triggeredAt,
        uint256 recoveredAt);

    event LogPriceDataDepegged (
        uint256 priceId,
        uint256 price,
        uint256 triggeredAt,
        uint256 depeggedAt);

    event LogPriceDataProcessed (
        uint256 priceId,
        uint256 price,
        uint256 createdAt);

    event LogUsdcProviderForcedDepeg (
        uint256 updatedTriggeredAt,
        uint256 forcedDepegAt);

    event LogUsdcProviderResetDepeg (
        uint256 resetDepegAt);

    struct PriceInfo {
        uint256 id;
        uint256 price;
        ComplianceState compliance;
        StabilityState stability;
        EventType eventType;
        uint256 triggeredAt;
        uint256 depeggedAt;
        uint256 createdAt;
    }

    function processLatestPriceInfo()
        external 
        returns(PriceInfo memory priceInfo);

    // only on testnets
    function forceDepegForNextPriceInfo()
        external;

    // only on testnets
    function resetDepeg()
        external;

    function isNewPriceInfoEventAvailable()
        external
        view
        returns(
            bool newEvent, 
            PriceInfo memory priceInfo,
            uint256 timeSinceEvent);

    function getLatestPriceInfo()
        external
        view 
        returns(PriceInfo memory priceInfo);

    function getDepegPriceInfo()
        external
        view 
        returns(PriceInfo memory priceInfo);

    function getTargetPrice() external view returns(uint256 targetPrice);

    function getTriggeredAt() external view returns(uint256 triggeredAt);
    function getDepeggedAt() external view returns(uint256 depeggedAt);

    function getAggregatorAddress() external view returns(address aggregatorAddress);
    function getHeartbeat() external view returns(uint256 heartbeatSeconds);
    function getDeviation() external view returns(uint256 deviationLevel);
    function getDecimals() external view returns(uint8 aggregatorDecimals);

    function getToken() external view returns(address);
    function getOwner() external view returns(address);

    function isMainnetProvider() external view returns(bool);
    function isTestnetProvider() external view returns(bool);
}