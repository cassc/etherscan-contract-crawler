// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILiquidationManager {
    event Liquidation(
        uint256 _liquidatedDebt,
        uint256 _liquidatedColl,
        uint256 _collGasCompensation,
        uint256 _debtGasCompensation
    );
    event TroveLiquidated(address indexed _borrower, uint256 _debt, uint256 _coll, uint8 _operation);
    event TroveUpdated(address indexed _borrower, uint256 _debt, uint256 _coll, uint256 _stake, uint8 _operation);

    function batchLiquidateTroves(address troveManager, address[] calldata _troveArray) external;

    function enableTroveManager(address _troveManager) external;

    function liquidate(address troveManager, address borrower) external;

    function liquidateTroves(address troveManager, uint256 maxTrovesToLiquidate, uint256 maxICR) external;

    function CCR() external view returns (uint256);

    function DEBT_GAS_COMPENSATION() external view returns (uint256);

    function DECIMAL_PRECISION() external view returns (uint256);

    function PERCENT_DIVISOR() external view returns (uint256);

    function borrowerOperations() external view returns (address);

    function factory() external view returns (address);

    function stabilityPool() external view returns (address);
}