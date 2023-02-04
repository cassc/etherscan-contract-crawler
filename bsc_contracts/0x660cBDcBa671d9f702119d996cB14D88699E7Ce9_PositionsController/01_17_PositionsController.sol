// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../lib/factories/HasFactories.sol';
import './ItemRef.sol';
import 'contracts/position_trading/IPositionAlgorithm.sol';
import './IPositionsController.sol';
import 'contracts/fee/IFeeSettings.sol';
import 'contracts/position_trading/ItemRefAsAssetLibrary.sol';
import 'contracts/position_trading/AssetTransferData.sol';

interface IErc20Balance {
    function balanceOf(address account) external view returns (uint256);
}

contract PositionsController is HasFactories, IPositionsController {
    using ItemRefAsAssetLibrary for ItemRef;

    IFeeSettings feeSettings;
    uint256 _positionsCount; // total positions created
    uint256 _assetsCount;
    mapping(uint256 => address) public owners; // position owners
    mapping(uint256 => ItemRef) public ownerAssets; // owner's asset (what is offered). by position ids
    mapping(uint256 => ItemRef) public outputAssets; // output asset (what they want in return), may be absent, in case of locks. by position ids
    mapping(uint256 => address) public algorithms; // algorithm for processing the input and output asset
    mapping(uint256 => bool) _buildModes; // build modes by positions
    mapping(uint256 => uint256) _positionsByAssets;

    constructor(address feeSettings_) {
        feeSettings = IFeeSettings(feeSettings_);
    }

    receive() external payable {}

    modifier onlyPositionOwner(uint256 positionId) {
        require(owners[positionId] == msg.sender, 'only for position owner');
        _;
    }

    modifier onlyBuildMode(uint256 positionId) {
        require(this.isBuildMode(positionId), 'only for position build mode');
        _;
    }

    modifier oplyPositionAlgorithm(uint256 positionId) {
        require(
            this.getAlgorithm(positionId) == msg.sender,
            'only for position algotithm'
        );
        _;
    }

    function createPosition(address owner)
        external
        onlyFactory
        returns (uint256)
    {
        ++_positionsCount;
        owners[_positionsCount] = owner;
        _buildModes[_positionsCount] = true;
        return _positionsCount;
    }

    function getPosition(uint256 positionId)
        external
        view
        returns (
            address algorithm,
            AssetData memory asset1,
            AssetData memory asset2
        )
    {
        algorithm = algorithms[positionId];
        ItemRef memory ref = this.getAssetReference(positionId, 1);
        if (ref.addr != address(0)) asset1 = ref.getData();
        ref = this.getAssetReference(positionId, 2);
        if (ref.addr != address(0)) asset2 = ref.getData();
    }

    function positionsCount() external returns (uint256) {
        return _positionsCount;
    }

    function isBuildMode(uint256 positionId) external view returns (bool) {
        return _buildModes[positionId];
    }

    function stopBuild(uint256 positionId)
        external
        onlyFactory
        onlyBuildMode(positionId)
    {
        address alg = algorithms[positionId];
        require(alg != address(0), 'has no algorithm');

        delete _buildModes[positionId];

        emit NewPosition(
            owners[positionId],
            algorithms[positionId],
            positionId
        );
    }

    function getFeeSettings() external view returns (IFeeSettings) {
        return feeSettings;
    }

    function ownerOf(uint256 positionId)
        external
        view
        override
        returns (address)
    {
        return owners[positionId];
    }

    function getAssetReference(uint256 positionId, uint256 assetCode)
        external
        view
        returns (ItemRef memory)
    {
        if (assetCode == 1) return ownerAssets[positionId];
        else if (assetCode == 2) return outputAssets[positionId];
        else revert('unknown asset code');
    }

    function getAllPositionAssetReferences(uint256 positionId)
        external
        view
        returns (ItemRef memory position1, ItemRef memory position2)
    {
        return (ownerAssets[positionId], outputAssets[positionId]);
    }

    function getAsset(uint256 positionId, uint256 assetCode)
        external
        view
        returns (AssetData memory data)
    {
        return this.getAssetReference(positionId, assetCode).getData();
    }

    function createAsset(
        uint256 positionId,
        uint256 assetCode,
        address assetsController
    ) external onlyFactory returns (ItemRef memory) {
        ItemRef memory asset = ItemRef(assetsController, _createNewAssetId());
        _positionsByAssets[asset.id] = positionId;

        if (assetCode == 1) ownerAssets[positionId] = asset;
        else if (assetCode == 2) outputAssets[positionId] = asset;
        else revert('unknown asset code');

        return asset;
    }

    function setAlgorithm(uint256 positionId, address algorithm)
        external
        onlyFactory
        onlyBuildMode(positionId)
    {
        algorithms[positionId] = algorithm;
    }

    function getAlgorithm(uint256 positionId)
        external
        view
        override
        returns (address)
    {
        return algorithms[positionId];
    }

    function assetsCount() external view returns (uint256) {
        return _assetsCount;
    }

    function createNewAssetId() external onlyFactory returns (uint256) {
        return _createNewAssetId();
    }

    function _createNewAssetId() internal onlyFactory returns (uint256) {
        return ++_assetsCount;
    }

    function getAssetPositionId(uint256 assetId)
        external
        view
        returns (uint256)
    {
        return _positionsByAssets[assetId];
    }

    function beforeAssetTransfer(AssetTransferData calldata arg)
        external
        onlyFactory
    {
        uint256 positionId = arg.asset.getPositionId();
        IPositionAlgorithm alg = IPositionAlgorithm(algorithms[positionId]);
        if (address(alg) == address(0)) return;
        alg.beforeAssetTransfer(arg);
    }

    function afterAssetTransfer(AssetTransferData calldata arg)
        external
        payable
        onlyFactory
    {
        uint256 positionId = arg.asset.getPositionId();
        IPositionAlgorithm alg = IPositionAlgorithm(algorithms[positionId]);
        if (address(alg) == address(0)) return;
        alg.afterAssetTransfer{ value: msg.value }(arg);
    }

    function transferToAsset(
        uint256 positionId,
        uint256 assetCode,
        uint256 count,
        uint256[] calldata data
    ) external payable returns (uint256 ethSurplus) {
        ItemRef memory asset = this.getAssetReference(positionId, assetCode);
        ethSurplus = IAssetsController(asset.addr).transferToAsset{
            value: msg.value
        }(
            AssetTransferData(
                positionId,
                asset,
                assetCode,
                msg.sender,
                asset.addr,
                count,
                data
            )
        );
        if (ethSurplus > 0) {
            (bool surplusSent, ) = payable(msg.sender).call{
                value: ethSurplus
            }('');
            require(surplusSent, 'ethereum surplus is not sent');
        }
    }

    function transferToAssetFrom(
        address from,
        uint256 positionId,
        uint256 assetCode,
        uint256 count,
        uint256[] calldata data
    ) external payable onlyFactory returns (uint256 ethSurplus) {
        ItemRef memory asset = this.getAssetReference(positionId, assetCode);
        ethSurplus = IAssetsController(asset.addr).transferToAsset{
            value: msg.value
        }(
            AssetTransferData(
                positionId,
                asset,
                assetCode,
                from,
                asset.addr,
                count,
                data
            )
        );
        if (ethSurplus > 0) {
            (bool surplusSent, ) = msg.sender.call{ value: ethSurplus }('');
            require(surplusSent, 'ethereum surplus is not sent');
        }
    }

    function transferToAnotherAssetInternal(
        ItemRef calldata from,
        ItemRef calldata to,
        uint256 count
    ) external oplyPositionAlgorithm(from.getPositionId()) {
        require(
            from.assetTypeId() == to.assetTypeId(),
            'transfer from asset to must be same types'
        );
        if (to.assetTypeId() == 2) {
            uint256 lastBalance = IErc20Balance(to.contractAddr()).balanceOf(to.addr);
            from.withdraw(to.addr, count);
            to.addCount(IErc20Balance(to.contractAddr()).balanceOf(to.addr) - lastBalance);
        } else {
            from.withdraw(to.addr, count);
            to.addCount(count);
        }
    }

    function withdraw(
        uint256 positionId,
        uint256 assetCode,
        uint256 count
    ) external onlyPositionOwner(positionId) {
        _withdrawTo(positionId, assetCode, msg.sender, count);
    }

    function withdrawTo(
        uint256 positionId,
        uint256 assetCode,
        address to,
        uint256 count
    ) external {
        _withdrawTo(positionId, assetCode, to, count);
    }

    function _withdrawTo(
        uint256 positionId,
        uint256 assetCode,
        address to,
        uint256 count
    ) internal {
        address algAddr = this.getAlgorithm(positionId);
        ItemRef memory asset = this.getAssetReference(positionId, assetCode);
        if (algAddr != address(0)) {
            IPositionAlgorithm(algAddr).checkCanWithdraw(
                asset,
                assetCode,
                count
            );
        }
        asset.withdraw(to, count);
    }

    function withdrawInternal(
        ItemRef calldata asset,
        address to,
        uint256 count
    ) external oplyPositionAlgorithm(asset.getPositionId()) {
        asset.withdraw(to, count);
    }

    function count(ItemRef calldata asset) external view returns (uint256) {
        return asset.count();
    }

    function getCounts(uint256 positionId)
        external
        view
        returns (uint256, uint256)
    {
        return (
            this.getAssetReference(positionId, 1).count(),
            this.getAssetReference(positionId, 2).count()
        );
    }

    function positionLocked(uint256 positionId) external view returns (bool) {
        address algAddr = this.getAlgorithm(positionId);
        if (algAddr == address(0)) return false;
        return IPositionAlgorithm(algAddr).positionLocked(positionId);
    }
}