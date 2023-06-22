pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Dice.sol";
import "./Treasury.sol";
import "./Constants.sol";
import "./Inventory.sol";

/// @title Guild of Guardians PreSale Contract
/// @author Marc Griffiths
/// @notice This contract will be used to presale in game items for Guild of Guardians

contract GuildOfGuardiansPreSale is
    Constants,
    AccessControl,
    Treasury,
    Inventory
{
    constructor(address _usdEthPairAddress)
        Inventory(_usdEthPairAddress)
    {
        // Initialise roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PRODUCT_OWNER_ROLE, msg.sender);
        _setupRole(TREASURER_ROLE, msg.sender);
        _setupRole(IMMUTABLE_SYSTEM_ROLE, msg.sender);

        // Initialise chroma and upgrade chance, to 2 d.p. 200 is 2.00%
        settings.firstChromaChance = 1200;
        settings.secondChromaChance = 200;
        settings.rareToEpicUpgradeChance = 400;
        settings.rareToLegendaryUpgradeChance = 100;
        settings.epicToLegendaryUpgradeChance = 500;
        settings.petRareChance = 2700;
        settings.petEpicChance = 1000;
        settings.petLegendaryChance = 300;
        settings.rareHeroMythicChance = 3;
        settings.epicHeroMythicChance = 8;
        settings.legendaryHeroMythicChance = 22;

        // Initialise prices in USD, to 2 d.p 900 is $9.00
        productPrices[uint256(Product.RareHeroPack)][
            uint256(Price.FirstSale)
        ] = 1000;
        productPrices[uint256(Product.RareHeroPack)][
            uint256(Price.LastSale)
        ] = 1250;
        productPrices[uint256(Product.EpicHeroPack)][
            uint256(Price.FirstSale)
        ] = 4400;
        productPrices[uint256(Product.EpicHeroPack)][
            uint256(Price.LastSale)
        ] = 5500;
        productPrices[uint256(Product.LegendaryHeroPack)][
            uint256(Price.FirstSale)
        ] = 20000;
        productPrices[uint256(Product.LegendaryHeroPack)][
            uint256(Price.LastSale)
        ] = 25000;
        productPrices[uint256(Product.PetPack)][
            uint256(Price.FirstSale)
        ] = 6000;
        productPrices[uint256(Product.PetPack)][uint256(Price.LastSale)] = 7500;
        productPrices[uint256(Product.EnergyToken)][
            uint256(Price.FirstSale)
        ] = 12000;
        productPrices[uint256(Product.EnergyToken)][
            uint256(Price.LastSale)
        ] = 15000;
        productPrices[uint256(Product.BasicGuildToken)][
            uint256(Price.FirstSale)
        ] = 16000;
        productPrices[uint256(Product.BasicGuildToken)][
            uint256(Price.LastSale)
        ] = 20000;
        productPrices[uint256(Product.Tier1GuildToken)][
            uint256(Price.FirstSale)
        ] = 320000;
        productPrices[uint256(Product.Tier1GuildToken)][
            uint256(Price.LastSale)
        ] = 400000;
        productPrices[uint256(Product.Tier2GuildToken)][
            uint256(Price.FirstSale)
        ] = 1600000;
        productPrices[uint256(Product.Tier2GuildToken)][
            uint256(Price.LastSale)
        ] = 2000000;
        productPrices[uint256(Product.Tier3GuildToken)][
            uint256(Price.FirstSale)
        ] = 8000000;
        productPrices[uint256(Product.Tier3GuildToken)][
            uint256(Price.LastSale)
        ] = 10000000;

        // Initialise stock levels
        originalStock[uint256(Product.RareHeroPack)] = 0;
        originalStock[uint256(Product.EpicHeroPack)] = 0;
        originalStock[uint256(Product.LegendaryHeroPack)] = 0;
        originalStock[uint256(Product.EnergyToken)] = 0;
        originalStock[uint256(Product.BasicGuildToken)] = 0;
        originalStock[uint256(Product.Tier1GuildToken)] = 0;
        originalStock[uint256(Product.Tier2GuildToken)] = 0;
        originalStock[uint256(Product.Tier3GuildToken)] = 0;
        originalStock[uint256(Product.PetPack)] = 0;
        stockAvailable[uint256(Product.RareHeroPack)] = 0;
        stockAvailable[uint256(Product.EpicHeroPack)] = 0;
        stockAvailable[uint256(Product.LegendaryHeroPack)] = 0;
        stockAvailable[uint256(Product.EnergyToken)] = 0;
        stockAvailable[uint256(Product.BasicGuildToken)] = 0;
        stockAvailable[uint256(Product.Tier1GuildToken)] = 0;
        stockAvailable[uint256(Product.Tier2GuildToken)] = 0;
        stockAvailable[uint256(Product.Tier3GuildToken)] = 0;
        stockAvailable[uint256(Product.PetPack)] = 0;
    }
}