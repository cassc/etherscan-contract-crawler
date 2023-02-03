// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../PositionAlgorithm.sol';
import '../PositionAlgorithm.sol';
import 'contracts/position_trading/IPositionsController.sol';
import 'contracts/position_trading/ItemRefAsAssetLibrary.sol';

/// @dev locks the asset of the position owner for a certain time
contract PositionLockerAlgorithm is PositionAlgorithm {
    using ItemRefAsAssetLibrary for ItemRef;

    constructor(address positionsController)
        PositionAlgorithm(positionsController)
    {}

    function checkCanWithdraw(
        ItemRef calldata asset,
        uint256 assetCode,
        uint256 count
    ) external view {
        require(
            !this.positionLocked(asset.getPositionId()),
            'position is locked'
        );
    }
}