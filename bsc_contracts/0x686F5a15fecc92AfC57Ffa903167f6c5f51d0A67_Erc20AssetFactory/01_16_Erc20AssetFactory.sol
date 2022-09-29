pragma solidity ^0.8.17;
import './Erc20Asset.sol';
import 'contracts/lib/factories/ContractData.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/position_trading/assets/AssetFactoryBase.sol';
import 'contracts/interfaces/assets/typed/IErc20Asset.sol';
import 'contracts/interfaces/assets/typed/IErc20AssetFactory.sol';

contract Erc20AssetFactory is AssetFactoryBase, IErc20AssetFactory {
    constructor(address positionsController_)
        AssetFactoryBase(positionsController_)
    {}

    function setAsset(
        uint256 positionId,
        uint256 assetCode,
        address contractAddress
    ) external {
        _setAsset(positionId, assetCode, createAsset(contractAddress));
    }

    function createAsset(address contractAddress)
        internal
        returns (ContractData memory)
    {
        ContractData memory data;
        data.factory = address(this);
        data.contractAddr = address(
            new Erc20Asset(address(positionsController), this, contractAddress)
        );
        return data;
    }

    function _clone(address asset, address owner)
        internal
        override
        returns (IAsset)
    {
        return
            new Erc20Asset(
                owner,
                this,
                IErc20Asset(asset).getContractAddress()
            );
    }
}