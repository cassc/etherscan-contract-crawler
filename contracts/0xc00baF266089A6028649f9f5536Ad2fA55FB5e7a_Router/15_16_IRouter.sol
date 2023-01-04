// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "./IPoolFactory.sol";
import "./IOracleManager.sol";

interface IRouter {
    event FactorySet(address indexed _emitter, address indexed _poolFactory);

    event OracleManagerSet(
        address indexed _emitter,
        address indexed _oracleManager
    );

    event TreasurySet(address indexed _emitter, address indexed _treasury);

    event Deposit(
        uint256 indexed _pid,
        address indexed _asset,
        uint256 indexed _amt
    );

    event Borrow(
        uint256 indexed _pid,
        uint256 indexed _borrAmt,
        address[] collateralAssets,
        uint256[] _colAmts
    );

    event Repay(
        uint256 indexed _pid,
        address indexed _lentAsset,
        uint256 indexed _amt
    );

    event Redeem(
        uint256 indexed _pid,
        address indexed _asset,
        bool indexed _hasDefaulted
    );

    event LeftoversWithdrawn(uint256 indexed _pid, uint256 indexed _amt);

    function poolFactory() external view returns (IPoolFactory);

    function oracleManager() external view returns (IOracleManager);

    function treasury() external view returns (address);

    function getBorrowingPower(
        address[] calldata _collateralAssets,
        uint256[] calldata _amts
    ) external view returns (uint256 _borrowingPower);

    function deposit(uint256 _pid, uint256 _amt) external;

    function borrow(
        uint256 _pid,
        address[] calldata _collateralAssets,
        uint256[] calldata _amts
    ) external;

    function repay(uint256 _pid, uint256 _amt) external;

    function redeem(uint256 _pid) external;

    function withdrawLeftovers(uint256 _pid) external;
}