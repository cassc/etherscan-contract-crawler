pragma solidity ^0.8.17;
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/lib/ownable/OwnableSimple.sol';
import 'contracts/interfaces/assets/typed/IEthAssetFactory.sol';
import 'contracts/interfaces/assets/typed/IErc20AssetFactory.sol';
import 'contracts/interfaces/assets/typed/IErc721ItemAssetFactory.sol';
import 'contracts/lib/factories/ContractData.sol';
import 'contracts/interfaces/position_trading/algorithms/IPositionLockerAlgorithmInstaller.sol';
import 'contracts/interfaces/position_trading/algorithms/ISaleAlgorithm.sol';
import 'contracts/interfaces/position_trading/algorithms/IPositionTradingAlgorithm.sol';

/// @dev asset creation data
struct AssetCreationData {
    /// @dev asset codes:
    /// 0 - asset is missing
    /// 1 - EthAsset
    /// 2 - Erc20Asset
    /// 3 - Erc721ItemAsset
    uint256 assetTypeCode;
    address contractAddress;
    uint256 tokenId;
}

contract PositionFactory is OwnableSimple {
    IPositionsController public positionsController;
    IEthAssetFactory public ethAssetFactory; // assetType 1
    IErc20AssetFactory public erc20AssetFactory; // assetType 2
    IErc721ItemAssetFactory public erc721AssetFactory; // assetType 3
    IPositionLockerAlgorithmInstaller public positionLockerAlgorithm;
    ISaleAlgorithm public saleAlgorithm;

    constructor(
        address positionsController_,
        address ethAssetFactory_,
        address erc20AssetFactory_,
        address erc721AssetFactory_,
        address positionLockerAlgorithm_,
        address saleAlgorithm_
    ) OwnableSimple(msg.sender) {
        positionsController = IPositionsController(positionsController_);
        ethAssetFactory = IEthAssetFactory(ethAssetFactory_);
        erc20AssetFactory = IErc20AssetFactory(erc20AssetFactory_);
        erc721AssetFactory = IErc721ItemAssetFactory(erc721AssetFactory_);
        positionLockerAlgorithm = IPositionLockerAlgorithmInstaller(
            positionLockerAlgorithm_
        );
        saleAlgorithm = ISaleAlgorithm(saleAlgorithm_);
    }

    function setPositionsController(address positionsController_)
        external
        onlyOwner
    {
        positionsController = IPositionsController(positionsController_);
    }

    function setethAssetFactory(address ethAssetFactory_) external onlyOwner {
        ethAssetFactory = IEthAssetFactory(ethAssetFactory_);
    }

    function createPositionWithAssets(
        AssetCreationData calldata data1,
        AssetCreationData calldata data2
    ) external {
        // create a position
        positionsController.createPosition();
        uint256 positionId = _lastCreatedPositionId();

        // set assets
        _setAsset(positionId, 1, data1);
        _setAsset(positionId, 2, data2);

        // transfer ownership of the position
        positionsController.transferPositionOwnership(positionId, msg.sender);
    }

    function createPositionLockAlgorithm(AssetCreationData calldata data)
        external
    {
        // create a position
        positionsController.createPosition();
        uint256 positionId = _lastCreatedPositionId();

        // set assets
        _setAsset(positionId, 1, data);

        // set algorithm
        positionLockerAlgorithm.setAlgorithm(positionId);

        // transfer ownership of the position
        positionsController.transferPositionOwnership(positionId, msg.sender);
    }

    function createSaleAlgorithm(
        AssetCreationData calldata data1,
        AssetCreationData calldata data2,
        Price calldata price
    ) external {
        // create a position
        positionsController.createPosition();
        uint256 positionId = _lastCreatedPositionId();

        // set assets
        _setAsset(positionId, 1, data1);
        _setAsset(positionId, 2, data2);

        // set algorithm
        saleAlgorithm.setAlgorithm(positionId);

        // set price
        saleAlgorithm.setPrice(positionId, price);

        // transfer ownership of the position
        positionsController.transferPositionOwnership(positionId, msg.sender);
    }

    function _lastCreatedPositionId() internal view returns (uint256) {
        return
            positionsController.positionOfOwnerByIndex(
                address(this),
                positionsController.ownedPositionsCount(address(this)) - 1
            );
    }

    function _setAsset(
        uint256 positionId,
        uint256 assetCode,
        AssetCreationData calldata data
    ) internal {
        if (data.assetTypeCode == 1)
            ethAssetFactory.setAsset(positionId, assetCode);
        else if (data.assetTypeCode == 2)
            erc20AssetFactory.setAsset(
                positionId,
                assetCode,
                data.contractAddress
            );
        else if (data.assetTypeCode == 3)
            erc721AssetFactory.setAsset(
                positionId,
                assetCode,
                data.contractAddress,
                data.tokenId
            );
    }
}