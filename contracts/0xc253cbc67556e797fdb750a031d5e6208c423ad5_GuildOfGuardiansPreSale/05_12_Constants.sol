pragma solidity >=0.8.0 <0.9.0;

contract Constants {
    uint256 constant cMaxRandom = 10000;
    uint8 constant cFutureBlockOffset = 2;
    uint8 constant cNumRareHeroTypes = 16;
    uint8 constant cNumEpicHeroTypes = 11;
    uint8 constant cNumLegendaryHeroTypes = 8;
    uint256 constant numProduct = 9;

    uint8 constant cNumHeroTypes =
        cNumRareHeroTypes + cNumEpicHeroTypes + cNumLegendaryHeroTypes;

    uint16 constant cReferralDiscount = 500;
    uint16 constant cReferrerBonus = 500;

    bytes32 public constant PRODUCT_OWNER_ROLE =
        keccak256("PRODUCT_OWNER_ROLE");
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");
    bytes32 public constant IMMUTABLE_SYSTEM_ROLE =
        keccak256("IMMUTABLE_SYSTEM_ROLE");

    enum Product {
        RareHeroPack,
        EpicHeroPack,
        LegendaryHeroPack,
        PetPack,
        EnergyToken,
        BasicGuildToken,
        Tier1GuildToken,
        Tier2GuildToken,
        Tier3GuildToken
    }

    enum Rarity {Rare, Epic, Legendary, Common, NA}

    enum Price {FirstSale, LastSale}
}