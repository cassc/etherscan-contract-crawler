// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @notice Interfaces of TradingHub
interface ITradingHub {
    struct BatchPositionInfo {
        uint256 poolId;
        address[] positions;
    }

    function getPositionState(address position)
        external
        view
        returns (
            uint256 poolId,
            address strToken,
            uint256 closingBlock,
            uint256 positionState
        );

    function getPoolStats(uint256 poolId)
        external
        view
        returns (
            uint256 opens,
            uint256 closings,
            uint256 legacies,
            uint256 ends
        );

    function getBatchPositionState(address[] calldata positions) external view returns (uint256[] memory positionsState);

    function getPositionsByPoolId(uint256 poolId, uint256 positionState) external view returns (address[] memory);

    function getPositionsByState(uint256 positionState) external view returns (address[] memory);

    function updatePositionState(address position, uint256 positionState) external;

    function batchUpdatePositionState(address[] calldata positions, uint256[] calldata positionsState) external;

    function isPoolWithdrawable(uint256 poolId) external view returns (bool);

    function setBatchClosePositions(BatchPositionInfo[] calldata batchPositionInfos) external;

    function executePositions(address[] calldata positions) external;

    function deliver(BatchPositionInfo[] calldata batchPositionInfos) external;

    event PositionOpened(uint256 indexed poolId, address indexed trader, address indexed positionAddr, uint256 orderSize);
    event PositionIncreased(uint256 indexed poolId, address indexed trader, address indexed positionAddr, uint256 orderSize);
    event PositionDecreased(uint256 indexed poolId, address indexed trader, address indexed positionAddr, uint256 orderSize);
    event PositionClosing(address indexed positionAddr);
    event PositionOverdrawn(address indexed positionAddr);
    event PositionClosed(address indexed positionAddr);
}