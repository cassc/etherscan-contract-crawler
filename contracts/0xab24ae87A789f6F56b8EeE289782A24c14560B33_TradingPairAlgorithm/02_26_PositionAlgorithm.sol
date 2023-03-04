// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../IPositionAlgorithm.sol';
import 'contracts/position_trading/IPositionsController.sol';
import 'contracts/position_trading/PositionSnapshot.sol';
import '../ItemRef.sol';
import '../IAssetsController.sol';
import 'contracts/position_trading/ItemRefAsAssetLibrary.sol';
import 'contracts/position_trading/AssetTransferData.sol';
import './PositionLockerBase.sol';

/// @dev basic algorithm position
abstract contract PositionAlgorithm is PositionLockerBase {
    using ItemRefAsAssetLibrary for ItemRef;
    IPositionsController public immutable positionsController;

    constructor(address positionsControllerAddress) {
        positionsController = IPositionsController(positionsControllerAddress);
    }

    modifier onlyPositionOwner(uint256 positionId) {
        require(
            positionsController.ownerOf(positionId) == msg.sender,
            'only for position owner'
        );
        _;
    }

    modifier onlyFactory() {
        require(
            positionsController.isFactory(msg.sender),
            'only for factories'
        );
        _;
    }

    modifier onlyPositionsController() {
        require(
            msg.sender == address(positionsController),
            'only for positions controller'
        );
        _;
    }

    modifier onlyBuildMode(uint256 positionId) {
        require(
            positionsController.isBuildMode(positionId),
            'only for position build mode'
        );
        _;
    }

    function beforeAssetTransfer(AssetTransferData calldata arg)
        external
        onlyPositionsController
    {
        _beforeAssetTransfer(arg);
    }

    function _beforeAssetTransfer(AssetTransferData calldata arg)
        internal
        virtual
    {}

    function afterAssetTransfer(AssetTransferData calldata arg)
        external
        payable
        onlyPositionsController
    {
        _afterAssetTransfer(arg);
    }

    function _afterAssetTransfer(AssetTransferData calldata arg)
        internal
        virtual
    {}

    function withdrawAsset(
        uint256 positionId,
        uint256 assetCode,
        address recipient,
        uint256 amount
    ) external onlyPositionOwner(positionId) {
        _withdrawAsset(positionId, assetCode, recipient, amount);
    }

    function _withdrawAsset(
        // todo упростить - сделать где нужно метод проверки
        uint256 positionId,
        uint256 assetCode,
        address recipient,
        uint256 amount
    ) internal virtual onlyPositionOwner(positionId) {
        positionsController.getAssetReference(positionId, assetCode).withdraw(
            recipient,
            amount
        );
    }

    function lockPosition(uint256 positionId, uint256 lockSeconds)
        external
        onlyUnlockedPosition(positionId)
    {
        if (positionsController.isBuildMode(positionId)) {
            require(
                positionsController.isFactory(msg.sender),
                'only for factories'
            );
        } else {
            require(
                positionsController.ownerOf(positionId) == msg.sender,
                'only for position owner'
            );
        }
        unlockTimes[positionId] = block.timestamp + lockSeconds * 1 seconds;
    }

    function lockPermanent(uint256 positionId)
        external
        onlyPositionOwner(positionId)
    {
        _permamentLocks[positionId] = true;
    }
}