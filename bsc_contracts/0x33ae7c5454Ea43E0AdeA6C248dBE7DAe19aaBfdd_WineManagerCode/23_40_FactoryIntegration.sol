// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../interfaces/IWineFactory.sol";
import "../interfaces/IWinePoolFull.sol";
import "../interfaces/IWineManagerFactoryIntegration.sol";
import "../proxy/TransparentUpgradeableProxyInitializable.sol";
import "../proxy/ITransparentUpgradeableProxyInitializable.sol";

abstract contract FactoryIntegration is IWineManagerFactoryIntegration
{
    address public override factory;

    function _initializeFactory(
        address proxyAdmin_,
        address winePoolCode_,
        address wineFactoryCode_,
        string memory baseUri_,
        string memory baseSymbol_
    )
        internal
    {
        factory = address(new TransparentUpgradeableProxyInitializable());
        ITransparentUpgradeableProxyInitializable(factory).initializeProxy(wineFactoryCode_, proxyAdmin_, bytes(""));
        IWineFactory(factory).initialize(proxyAdmin_, winePoolCode_, address(this), baseUri_, baseSymbol_);
    }

    function _createWinePool(
        string memory name_,

        uint256 maxTotalSupply_,
        uint256 winePrice_,

        string memory wineName_,
        string memory wineProductionCountry_,
        string memory wineProductionRegion_,
        string memory wineProductionYear_,
        string memory wineProducerName_,
        string memory wineBottleVolume_,
        string memory linkToDocuments_
    )
        internal
    {
        (uint256 poolId, address winePoolAddress) = IWineFactory(factory).createWinePool(
            name_,

            maxTotalSupply_,
            winePrice_
        );
        IWinePoolFull(winePoolAddress).updateAllDescriptionFields(
            wineName_,
            wineProductionCountry_,
            wineProductionRegion_,
            wineProductionYear_,
            wineProducerName_,
            wineBottleVolume_,
            linkToDocuments_
        );

        emit WinePoolCreated(poolId, winePoolAddress);
    }

    function getPoolAddress(uint256 poolId)
        override
        public view
        returns (address)
    {
        return IWineFactory(factory).getPool(poolId);
    }

    function getPoolAsContract(uint256 poolId)
        override
        public view
        returns (IWinePoolFull)
    {
        return IWinePoolFull(getPoolAddress(poolId));
    }

}