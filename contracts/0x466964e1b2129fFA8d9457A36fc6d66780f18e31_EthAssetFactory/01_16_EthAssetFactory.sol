pragma solidity ^0.8.17;
import './EthAsset.sol';
import 'contracts/lib/factories/ContractData.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/position_trading/assets/AssetFactoryBase.sol';
import 'contracts/interfaces/assets/typed/IEthAssetFactory.sol';

contract EthAssetFactory is AssetFactoryBase {
    constructor(address positionsController_)
        AssetFactoryBase(positionsController_)
    {}

    function setAsset(uint256 positionId, uint256 assetCode) external {
        _setAsset(positionId, assetCode, createAsset());
    }

    function createAsset() internal returns (ContractData memory) {
        ContractData memory data;
        data.factory = address(this);
        data.contractAddr = address(
            new EthAsset(address(positionsController), this)
        );
        return data;
    }

    function _clone(address, address owner) internal override returns (IAsset) {
        return new EthAsset(owner, this);
    }
}