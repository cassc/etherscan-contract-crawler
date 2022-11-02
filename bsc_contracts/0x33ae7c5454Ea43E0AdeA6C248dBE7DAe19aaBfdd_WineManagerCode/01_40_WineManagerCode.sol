// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./WineManagerParts/AccessControlIntegration.sol";
import "./WineManagerParts/FactoryIntegration.sol";
import "./WineManagerParts/FirstSaleMarketIntegration.sol";
import "./WineManagerParts/MarketPlaceIntegration.sol";
import "./WineManagerParts/DeliveryServiceIntegration.sol";
import "./WineManagerParts/BordeauxCityBondIntegration.sol";
import "./interfaces/IWineManagerPoolIntegration.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";


contract WineManagerCode is
    Initializable,
    AccessControlIntegration,
    FactoryIntegration,
    FirstSaleMarketIntegration,
    MarketPlaceIntegration,
    DeliveryServiceIntegration,
    BordeauxCityBondIntegration,
    IWineManagerPoolIntegration
{

    function initialize(
        address owner_,
        address proxyAdmin_,
        address winePoolCode_,
        address wineFactoryCode_,
        address wineFirstSaleMarketCode_,
        address wineMarketPlaceCode_,
        address wineDeliveryServiceCode_,
        string memory baseUri_,
        string memory baseSymbol_,
        address firstSaleCurrency_,
        address[] memory allowedCurrencies_,
        uint256 orderFeeInPromille_
    )
        public
        initializer
    {
        _initializeAccessControlIntegration(owner_);
        _initializeFactory(
            proxyAdmin_,
            winePoolCode_,
            wineFactoryCode_,
            baseUri_,
            baseSymbol_
        );
        _initializeFirstSaleMarket(
            proxyAdmin_,
            wineFirstSaleMarketCode_,
            firstSaleCurrency_
        );
        _initializeMarketPlace(
            proxyAdmin_,
            wineMarketPlaceCode_,
            allowedCurrencies_,
            orderFeeInPromille_
        );
        _initializeDeliveryService(
            proxyAdmin_,
            wineDeliveryServiceCode_
        );
        _initializeAllowance();
    }

    function initializeBordeauxCityBond(
        address proxyAdmin_,
        address bordeauxCityBondCode_,
        uint256 BCBOutFee_,
        uint256 BCBFixedFee_,
        uint256 BCBFlexedFee_
    )
        public
        onlyOwner
    {
        _initializeBordeauxCityBond(
            proxyAdmin_,
            bordeauxCityBondCode_,
            BCBOutFee_,
            BCBFixedFee_,
            BCBFlexedFee_
        );
    }

//////////////////////////////////////// IWineManagerPoolIntegration

    mapping (address => bool) public override allowMint;
    mapping (address => bool) public override allowInternalTransfers;
    mapping (address => bool) public override allowBurn;

    function _initializeAllowance()
        public
        onlyOwner
    {
        allowMint[address(this)] = true;
        allowMint[firstSaleMarket] = true;
        allowInternalTransfers[address(this)] = true;
        allowInternalTransfers[deliveryService] = true;
        allowBurn[deliveryService] = true;
    }

//////////////////////////////////////// FactoryIntegration

    function createWinePool(
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
        public
        onlyRole(FACTORY_MANAGER_ROLE)
    {
        _createWinePool(
            name_,

            maxTotalSupply_,
            winePrice_,

            wineName_,
            wineProductionCountry_,
            wineProductionRegion_,
            wineProductionYear_,
            wineProducerName_,
            wineBottleVolume_,
            linkToDocuments_
        );
    }

    function disablePool(uint256 poolId)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IWineFactory(factory).disablePool(poolId);
    }

    function updateAllDescriptionFields(
        uint256 poolId,

        string memory wineName,
        string memory wineProductionCountry,
        string memory wineProductionRegion,
        string memory wineProductionYear,
        string memory wineProducerName,
        string memory wineBottleVolume,
        string memory linkToDocuments
    )
        public
        onlyRole(FACTORY_MANAGER_ROLE)
    {
        getPoolAsContract(poolId).updateAllDescriptionFields(
            wineName,
            wineProductionCountry,
            wineProductionRegion,
            wineProductionYear,
            wineProducerName,
            wineBottleVolume,
            linkToDocuments
        );
    }

    function editDescriptionField(uint256 poolId, bytes32 param, string memory value)
        public
        onlyRole(FACTORY_MANAGER_ROLE)
    {
        getPoolAsContract(poolId).editDescriptionField(param, value);
    }

    function editWinePoolMaxTotalSupply(uint256 poolId, uint256 value)
        public
        onlyRole(FACTORY_MANAGER_ROLE)
    {
        getPoolAsContract(poolId).editMaxTotalSupply(value);
    }

    function editWinePoolWinePrice(uint256 poolId, uint256 value)
        public
        onlyRole(FACTORY_MANAGER_ROLE)
    {
        getPoolAsContract(poolId).editWinePrice(value);
    }

    function transferInternalToInternal(uint256 poolId, address internalFrom, address internalTo, uint256 tokenId)
        public
        onlyRole(SYSTEM_ROLE)
    {
        getPoolAsContract(poolId).transferInternalToInternal(internalFrom, internalTo, tokenId);
    }

    function transferInternalToOuter(uint256 poolId, address internalFrom, address outerTo, uint256 tokenId)
        public
        onlyRole(SYSTEM_ROLE)
    {
        getPoolAsContract(poolId).transferInternalToOuter(internalFrom, outerTo, tokenId);
    }

//////////////////////////////////////// FirstSaleMarketIntegration - Treasury

    function editFirstSaleCurrency(
        address firstSaleCurrency_
    )
        public
        onlyRole(FIRST_SALE_MARKET_MANAGER_ROLE)
    {
        IWineFirstSaleMarket(firstSaleMarket)._editFirstSaleCurrency(firstSaleCurrency_);
    }

    function firstSaleMarketTreasuryGetBalance(address currency)
        public
        view
        onlyRole(FIRST_SALE_MARKET_MANAGER_ROLE)
        returns (uint256)
    {
        return IWineFirstSaleMarket(firstSaleMarket)._treasuryGetBalance(currency);
    }

    function firstSaleMarketWithdrawFromTreasury(address currency, uint256 amount, address to)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IWineFirstSaleMarket(firstSaleMarket)._withdrawFromTreasury(currency, amount, to);
    }

//////////////////////////////////////// FirstSaleMarketIntegration - Token

    function firstSaleSetBottle(uint256 poolId, address internalUser)
        public
        onlyRole(SYSTEM_ROLE)
    {
        getPoolAsContract(poolId).mintToInternalUser(internalUser);
    }

//////////////////////////////////////// WineMarketPlace - Settings

    function marketPlaceEditAllowedCurrency(address currency_, bool value)
        public
        onlyRole(MARKET_PLACE_MANAGER_ROLE)
    {
        IWineMarketPlace(marketPlace)._editAllowedCurrency(currency_, value);
    }

    function marketPlaceEditOrderFeeInPromille(uint256 orderFeeInPromille_)
        public
        onlyRole(MARKET_PLACE_MANAGER_ROLE)
    {
        IWineMarketPlace(marketPlace)._editOrderFeeInPromille(orderFeeInPromille_);
    }

//////////////////////////////////////// WineMarketPlace - Owner

    function marketPlaceWithdrawFee(address currencyAddress, address to, uint256 amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IWineMarketPlace(marketPlace).withdrawFee(currencyAddress, to, amount);
    }

//////////////////////////////////////// BordeauxCityBondIntegration - Owner

    function bordeauxCityBondEditBCBOutFee(uint256 value)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IBordeauxCityBondIntegration(bordeauxCityBond)._editBCBOutFee(value);
    }

    function bordeauxCityBondEditBCBFixedFee(uint256 value)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IBordeauxCityBondIntegration(bordeauxCityBond)._editBCBFixedFee(value);
    }

    function bordeauxCityBondEditBCBFlexedFee(uint256 value)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IBordeauxCityBondIntegration(bordeauxCityBond)._editBCBFlexedFee(value);
    }

    function bordeauxCityBondWithdrawFee(address to, uint256 amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IBordeauxCityBondIntegration(bordeauxCityBond).withdrawBCBFee(to, amount);
    }

//////////////////////////////////////// DeliverySettings

    function deliveryServiceEditPoolDateBeginOfDelivery(uint256 poolId, uint256 dateBegin)
        public
        onlyRole(DELIVERY_SETTINGS_MANAGER_ROLE)
    {
        IWineDeliveryService(deliveryService)._editPoolDateBeginOfDelivery(poolId, dateBegin);
    }

//////////////////////////////////////// DeliveryTasks view methods

    function deliveryServiceShowSingleDeliveryTask(uint256 deliveryTaskId)
        public view
        onlyRole(DELIVERY_SUPPORT_ROLE)
        returns (IWineDeliveryService.DeliveryTask memory)
    {
        return IWineDeliveryService(deliveryService).showSingleDeliveryTask(deliveryTaskId);
    }

    function deliveryServiceShowLastDeliveryTask(uint256 poolId, uint256 tokenId)
        public view
        onlyRole(DELIVERY_SUPPORT_ROLE)
        returns (uint256, IWineDeliveryService.DeliveryTask memory)
    {
        return IWineDeliveryService(deliveryService).showLastDeliveryTask(poolId, tokenId);
    }

    function deliveryServiceShowFullHistory(uint256 poolId, uint256 tokenId)
        public view
        onlyRole(DELIVERY_SUPPORT_ROLE)
        returns (uint256, IWineDeliveryService.DeliveryTask[] memory)
    {
        return IWineDeliveryService(deliveryService).showFullHistory(poolId, tokenId);
    }

//////////////////////////////////////// DeliveryTasks edit methods

    function deliveryServiceDeliveryForInternal(uint256 poolId, uint256 tokenId, string memory deliveryData)
        public
        onlyRole(SYSTEM_ROLE)
    {
        IWineDeliveryService(deliveryService).requestDeliveryForInternal(poolId, tokenId, deliveryData);
    }

    function deliveryServiceSetDeliveryTaskAmount(uint256 poolId, uint256 tokenId, uint256 amount)
        public
        onlyRole(SYSTEM_ROLE)
    {
        IWineDeliveryService(deliveryService).setDeliveryTaskAmount(poolId, tokenId, amount);
    }

    function deliveryServicePayDeliveryTaskAmountInternal(uint256 poolId, uint256 tokenId)
        public
        onlyRole(SYSTEM_ROLE)
    {
        IWineDeliveryService(deliveryService).payDeliveryTaskAmountInternal(poolId, tokenId);
    }

    function deliveryServiceCancelDeliveryTask(uint256 poolId, uint256 tokenId, string memory supportResponse)
        public
        onlyRole(DELIVERY_SUPPORT_ROLE)
    {
        IWineDeliveryService(deliveryService).cancelDeliveryTask(poolId, tokenId, supportResponse);
    }

    function deliveryServiceFinishDeliveryTask(uint256 poolId, uint256 tokenId, string memory supportResponse)
        public
        onlyRole(DELIVERY_SUPPORT_ROLE)
    {
        IWineDeliveryService(deliveryService).finishDeliveryTask(poolId, tokenId, supportResponse);
    }

    function deliveryServiceWithdrawPaymentAmount(address to)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IWineDeliveryService(deliveryService).withdrawPaymentAmount(to);
    }

}