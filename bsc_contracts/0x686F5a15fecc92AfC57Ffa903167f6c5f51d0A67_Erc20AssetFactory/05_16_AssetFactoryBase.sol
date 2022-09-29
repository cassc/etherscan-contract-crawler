pragma solidity ^0.8.17;
import 'contracts/lib/factories/ContractData.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/interfaces/assets/IAssetCloneFactory.sol';

abstract contract AssetFactoryBase is IAssetCloneFactory {
    IPositionsController public positionsController;

    constructor(address positionsController_) {
        positionsController = IPositionsController(positionsController_);
    }

    modifier onlyPositionOwner(uint256 positionId) {
        require(positionsController.ownerOf(positionId) == msg.sender);
        _;
    }

    function _setAsset(
        uint256 positionId,
        uint256 assetCode,
        ContractData memory contractData
    ) internal onlyPositionOwner(positionId) {
        positionsController.setAsset(positionId, assetCode, contractData);
    }

    function clone(address asset, address owner)
        external
        override
        returns (IAsset)
    {
        require(msg.sender == asset, 'only for assets');
        return _clone(asset, owner);
    }

    function _clone(address asset, address owner)
        internal
        virtual
        returns (IAsset);
}