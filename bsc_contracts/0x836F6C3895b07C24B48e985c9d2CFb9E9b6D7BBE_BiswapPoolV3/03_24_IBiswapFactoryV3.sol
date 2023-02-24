// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface IBiswapFactoryV3 {

    /// @notice emit when successfully create a new pool (calling iBiswapFactoryV3#newPool)
    /// @param tokenX address of erc-20 tokenX
    /// @param tokenY address of erc-20 tokenY
    /// @param fee fee amount of swap (3000 means 0.3%)
    /// @param pointDelta minimum number of distance between initialized or limitorder points
    /// @param pool address of swap pool
    event NewPool(
        address indexed tokenX,
        address indexed tokenY,
        uint24 indexed fee,
        uint24 pointDelta,
        address pool
    );

    /// @notice module to support swap from tokenX to tokenY
    /// @return swapX2YModule address
    function swapX2YModule() external returns (address);

    /// @notice module to support swap from tokenY to tokenX
    /// @return swapY2XModule address
    function swapY2XModule() external returns (address);

    /// @notice module to support mint/burn/collect function of pool
    /// @return liquidityModule address
    function liquidityModule() external returns (address);

    /// @notice address of module for user to manage limit orders
    /// @return limitOrderModule address
    function limitOrderModule() external returns (address);

    /// @notice address of module for flash loan
    /// @return flashModule address
    function flashModule() external returns (address);

    /// @notice default fee rate from miner's fee gain
    /// @return defaultFeeChargePercent default fee rate * 100
    function defaultFeeChargePercent() external returns (uint24);

    /// @notice Enables a fee amount with the given pointDelta
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee fee amount (3000 means 0.3%)
    /// @param pointDelta The spacing between points to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, uint24 pointDelta) external;

    /// @notice Create a new pool which not exists.
    /// @param tokenX address of tokenX
    /// @param tokenY address of tokenY
    /// @param fee fee amount
    /// @param currentPoint initial point (log 1.0001 of price)
    /// @return address of newly created pool
    function newPool(
        address tokenX,
        address tokenY,
        uint24 fee,
        int24 currentPoint
    ) external returns (address);

    /// @notice Charge receiver of all pools.
    /// @return address of charge receiver
    function chargeReceiver() external view returns(address);

    /// @notice Get pool of (tokenX, tokenY, fee), address(0) for not exists.
    /// @param tokenX address of tokenX
    /// @param tokenY address of tokenY
    /// @param fee fee amount
    /// @return address of pool
    function pool(
        address tokenX,
        address tokenY,
        uint24 fee
    ) external view returns(address);

    /// @notice Get point delta of a given fee amount.
    /// @param fee fee amount
    /// @return pointDelta the point delta
    function fee2pointDelta(uint24 fee) external view returns (int24 pointDelta);

    /// @notice Change charge receiver, only owner of factory can call.
    /// @param _chargeReceiver address of new receiver
    function modifyChargeReceiver(address _chargeReceiver) external;

    /// @notice Change defaultFeeChargePercent
    /// @param _defaultFeeChargePercent new charge percent
    function modifyDefaultFeeChargePercent(uint24 _defaultFeeChargePercent) external;

    function deployPoolParams() external view returns(
        address tokenX,
        address tokenY,
        uint24 fee,
        int24 currentPoint,
        int24 pointDelta,
        uint24 feeChargePercent
    );

}