// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

enum Beard {
    None,
    Long,
    Short,
    Handlebar,
    Braided,
    Goatee,
    Dreaded
}

enum FemaleBody {
    Natural,
    Tan,
    Dark,
    DarkTan,
    DeepTan,
    Pale,
    Shadow
}

enum FemaleClothing {
    BlackShirt,
    WhiteShirt,
    BlueBlouse,
    WhiteBlouse,
    Bodysuit,
    Deckhand,
    Leaves,
    SteelPlateArmor,
    Gown
}

enum FemaleFace {
    None,
    Eyepatch,
    Eyeshadow,
    Sunglasses,
    Cyclops,
    GlowingEyes
}

enum FemaleHair {
    Long,
    Short,
    Ponytail
}

enum FemaleHat {
    None,
    BlackBuccaneer,
    BlackCrewmate,
    BrownCrewmate,
    Cowboy,
    Pirate,
    Captain,
    Halo,
    GoldLeafWreath,
    GildedBuccaneer,
    Headband
}

enum Gender {
    Male,
    Female
}

enum HairColor {
    None,
    Blue,
    Black,
    Brown,
    Blonde,
    Red,
    White
}

enum MaleBody {
    None,
    Natural,
    Tan,
    Dark,
    DarkTan,
    DeepTan,
    Pale,
    Shadow,
    Robot
}

enum MaleClothing {
    None,
    BlackShirt,
    BrownShirt,
    WhiteShirt,
    PrisonerShirt,
    CrewhandVest,
    LeatherCoat,
    BlackBeltGi,
    RainCoat,
    Executive,
    ClawWound,
    BlackPlateArmor,
    SteelPlateArmor,
    MatrixRobe,
    Tuxedo,
    GoldPlateArmor,
    SamuraiArmor
}

enum MaleFace {
    None,
    Eyeliner,
    Eyepatch,
    MechanicShades,
    BoneSkullMask,
    NinjaMask,
    SurgicalMask,
    BlueGoggles,
    PurpleGoggles,
    BlackSkullMask,
    Monocle,
    GlowingEyes,
    OniMask,
    GoldSkullMask
}

enum MaleHair {
    None,
    Long,
    Short,
    Wave,
    Balding,
    Parted,
    Ragged,
    Dreaded
}

enum MaleHat {
    None,
    BlackBuccaneer,
    BoxLogoSnapback,
    Cowboy,
    Headband,
    Pirate,
    Rice,
    YankeeSnapback,
    GildedBuccaneer,
    Captain,
    Crown,
    GoldLeafWreath,
    Halo,
    RoyalCrown,
    SOSSnapback,
    SamuraiHelmet
}

enum Special {
    None,
    SteelKnight,
    StormNinja,
    ShadowNinja,
    BloodNinja,
    GildedBlackKnight,
    GildedWhiteKnight,
    IvorySkeleton,
    EbonySkeleton
}

enum Unique {
    None,
    AngelOfDeath,
    CaptainJack,
    Cthulhu,
    DavyJones,
    FlameDemon,
    GoldenBones,
    GoldRobot,
    Medusa,
    Warlord,
    YoungJack,
    Zombie
}

enum Wing {
    None,
    Black,
    White,
    Red,
    Gold
}

struct TraitSet {
    uint8 body;
    uint8 clothing;
    uint8 face;
    uint8 hair;
    uint8 hat;
    Beard beard;
    Gender gender;
    HairColor hairColor;
    Special special;
    Unique unique;
    Wing wings;
}