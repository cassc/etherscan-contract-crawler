// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IOracle {
    function disputeExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function endMigration() external;

    function getDisputer() external view returns (address);

    function getExpiryPrice(address _asset, uint256 _expiryTimestamp) external view returns (uint256, bool);

    function getPrice(address _asset) external view returns (uint256);

    function getPricer(address _asset) external view returns (address);

    function getPricerDisputePeriod(address _pricer) external view returns (uint256);

    function getPricerLockingPeriod(address _pricer) external view returns (uint256);

    function isDisputePeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function isLockingPeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function migrateOracle(
        address _asset,
        uint256[] memory _expiries,
        uint256[] memory _prices
    ) external;

    function owner() external view returns (address);

    function renounceOwnership() external;

    function setAssetPricer(address _asset, address _pricer) external;

    function setDisputePeriod(address _pricer, uint256 _disputePeriod) external;

    function setDisputer(address _disputer) external;

    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function setLockingPeriod(address _pricer, uint256 _lockingPeriod) external;

    function setStablePrice(address _asset, uint256 _price) external;

    function transferOwnership(address newOwner) external;
}