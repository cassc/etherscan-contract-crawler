// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IFactory {
    // commented values are suggested default parameters
    struct DeploymentParams {
        uint256 minuteDecayFactor; // 999037758833783000  (half life of 12 hours)
        uint256 redemptionFeeFloor; // 1e18 / 1000 * 5  (0.5%)
        uint256 maxRedemptionFee; // 1e18  (100%)
        uint256 borrowingFeeFloor; // 1e18 / 1000 * 5  (0.5%)
        uint256 maxBorrowingFee; // 1e18 / 100 * 5  (5%)
        uint256 interestRateInBps; // 100 (1%)
        uint256 maxDebt;
        uint256 MCR; // 12 * 1e17  (120%)
    }

    event NewDeployment(address collateral, address priceFeed, address troveManager, address sortedTroves);

    function deployNewInstance(
        address collateral,
        address priceFeed,
        address customTroveManagerImpl,
        address customSortedTrovesImpl,
        DeploymentParams calldata params
    ) external;

    function setImplementations(address _troveManagerImpl, address _sortedTrovesImpl) external;

    function PRISMA_CORE() external view returns (address);

    function borrowerOperations() external view returns (address);

    function debtToken() external view returns (address);

    function guardian() external view returns (address);

    function liquidationManager() external view returns (address);

    function owner() external view returns (address);

    function sortedTrovesImpl() external view returns (address);

    function stabilityPool() external view returns (address);

    function troveManagerCount() external view returns (uint256);

    function troveManagerImpl() external view returns (address);

    function troveManagers(uint256) external view returns (address);
}