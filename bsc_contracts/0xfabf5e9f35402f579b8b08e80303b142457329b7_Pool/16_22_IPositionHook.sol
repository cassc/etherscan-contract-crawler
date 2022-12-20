pragma solidity 0.8.15;

import {Side, IPool} from "./IPool.sol";

interface IPositionHook {
    function preIncreasePosition(
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        bytes calldata extradata
    ) external;

    function postIncreasePosition(
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        bytes calldata extradata
    ) external;

    function preDecreasePosition(
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        bytes calldata extradata
    ) external;

    function postDecreasePosition(
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        bytes calldata extradata
    ) external;

    function preLiquidatePosition(
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        bytes calldata extradata
    ) external;

    function postLiquidatePosition(
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        bytes calldata extradata
    ) external;

    event PreIncreasePositionExecuted(
        address pool, address owner, address indexToken, address collateralToken, Side side, bytes extradata
    );
    event PostIncreasePositionExecuted(
        address pool, address owner, address indexToken, address collateralToken, Side side, bytes extradata
    );
    event PreDecreasePositionExecuted(
        address pool, address owner, address indexToken, address collateralToken, Side side, bytes extradata
    );
    event PostDecreasePositionExecuted(
        address pool, address owner, address indexToken, address collateralToken, Side side, bytes extradata
    );
    event PreLiquidatePositionExecuted(
        address pool, address owner, address indexToken, address collateralToken, Side side, bytes extradata
    );
    event PostLiquidatePositionExecuted(
        address pool, address owner, address indexToken, address collateralToken, Side side, bytes extradata
    );
}