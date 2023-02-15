// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";

import { EnumerableSet } from '@solidstate/contracts/data/EnumerableSet.sol';

using EnumerableSet for EnumerableSet.UintSet;
using EnumerableSet for EnumerableSet.AddressSet;

struct BookStorage {
    bool initialized;
    
    address gameContract;
    bool isMintActive;
    
    string nameSingular;
    string externalLink;
    string tokenDescription;
    
    uint maxNameRuneCount;
    uint damangeEventsLastForDuration;
    uint startingPunkHealth;
    
    uint32 imageScaleUpFactor;
    address[] backgroundImagePointersByLevel;
    
    uint32 currentThemeVersion;
    mapping(uint => ThemeStorage) versionedThemes;
    
    bool operatorFilteringEnabled;
    address withdrawAddress;

    mapping(uint => string) punkIdToName;
    mapping(bytes32 => uint) punkNameHashToPunkId;
    mapping(uint => uint32[]) punkIdToPunkDamageEvents;
    mapping(address => uint) userToPrimaryPunkId;
}

struct ThemeStorage {
    mapping(uint8 => EnumerableSet.UintSet) allowedAttributes;
    EnumerableSet.UintSet allowedAttributeCounts;
    uint64 activatedAt;
    uint64 duration;
}

enum Gender {
    Human, Male, Female, Zombie, Ape, Alien
}

enum AttributeSlot {
    MouthOrLips, Face, Neck, Beard, Ears, Hair, Mouth, Eyes, Nose
}

enum Attribute {
    None, Male1, Male2, Male3, Male4, Female1, Female2, Female3, Female4, Zombie, Ape, Alien, RosyCheeks_m, LuxuriousBeard_m, ClownHairGreen_m, MohawkDark_m, CowboyHat_m, Mustache_m, ClownNose_m, Cigarette_m, NerdGlasses_m, RegularShades_m, KnittedCap_m, ShadowBeard_m, Frown_m, CapForward_m, Goat_m, Mole_m, PurpleHair_m, SmallShades_m, ShavedHead_m, ClassicShades_m, Vape_m, SilverChain_m, Smile_m, BigShades_m, MohawkThin_m, Beanie_m, Cap_m, ClownEyesGreen_m, NormalBeardBlack_m, MedicalMask_m, NormalBeard_m, VR_m, EyePatch_m, WildHair_m, TopHat_m, Bandana_m, Handlebars_m, FrumpyHair_m, CrazyHair_m, PoliceCap_m, BuckTeeth_m, DoRag_m, FrontBeard_m, Spots_m, BigBeard_m, VampireHair_m, PeakSpike_m, Chinstrap_m, Fedora_m, Earring_m, HornedRimGlasses_m, Headband_m, Pipe_m, MessyHair_m, FrontBeardDark_m, Hoodie_m, GoldChain_m, Muttonchops_m, StringyHair_m, EyeMask_m, ThreeDGlasses_m, ClownEyesBlue_m, Mohawk_m, PilotHelmet_f, TassleHat_f, HotLipstick_f, BlueEyeShadow_f, StraightHairDark_f, Choker_f, CrazyHair_f, RegularShades_f, WildBlonde_f, ThreeDGlasses_f, Mole_f, WildWhiteHair_f, Spots_f, FrumpyHair_f, NerdGlasses_f, Tiara_f, OrangeSide_f, RedMohawk_f, MessyHair_f, ClownEyesBlue_f, Pipe_f, WildHair_f, PurpleEyeShadow_f, StringyHair_f, DarkHair_f, EyePatch_f, BlondeShort_f, ClassicShades_f, EyeMask_f, ClownHairGreen_f, Cap_f, MedicalMask_f, Bandana_f, PurpleLipstick_f, ClownNose_f, Headband_f, Pigtails_f, StraightHairBlonde_f, KnittedCap_f, ClownEyesGreen_f, Cigarette_f, WeldingGoggles_f, MohawkThin_f, GoldChain_f, VR_f, Vape_f, PinkWithHat_f, BlondeBob_f, Mohawk_f, BigShades_f, Earring_f, GreenEyeShadow_f, StraightHair_f, RosyCheeks_f, HalfShaved_f, MohawkDark_f, BlackLipstick_f, HornedRimGlasses_f, SilverChain_f
}

struct PunkDataStorage {
    bytes palette;
    mapping(uint8 => bytes) assets;
    mapping(uint8 => string) assetNames;
    mapping(uint8 => Gender) baseToGender;
    mapping(Gender => uint[]) genderToBases;
    mapping(uint8 => bool) isHat;
    mapping(uint80 => uint16) packedAssetsToOldPunksIdPlusOneMap;
    string[10] assetSlotToTraitType;
    
    mapping(uint8 => mapping(uint8 => EnumerableSet.UintSet)) genderedAttributes;
    EnumerableSet.UintSet validBases;
}

struct StoredNFT {
    bool is1155;
    address contractAddress;
    uint88 tokenId;
}

struct NFTVault {
    string slug;
    EnumerableSet.AddressSet allowedContracts;
    StoredNFT[] storedNFTs;
}

struct PrizeWithProbability {
    string prizeSlug;
    uint probability;
}

struct Prize {
    string slug;
    string name;
    string vaultSlug;
    uint NFTAmount;
    string gameItemSlug;
    uint gameItemAmount;
}

struct Chest {
    string name;
    string slug;
    PrizeWithProbability[] prizes;
}

struct ChestWithProbability {
    string chestSlug;
    uint probability;
}

struct ChestSetCost {
    string vaultSlug;
    uint NFTAmount;
    string gameItemSlug;
    uint gameItemAmount;
    uint bookHealthCost;
}

struct ChestSet {
    string slug;
    ChestSetCost cost;
    ChestWithProbability[] chests;
}

struct GameItemTokenInfo {
    string slug;
    string name;
    string description;
    string imageURI;
    string externalLink;
    string canBeCombinedIntoSlug;
    uint costToCombine;
}

struct GameAuctionStorage {
    uint32 auctionId;
    bool settled;
    uint64 startTime;
    uint64 endTime;
    address highestBidder;
    uint highestBidAmount;
}

struct GameAuctionConfigStorage {
    bool auctionEnabled;
    uint64 timeBuffer;
    uint reservePrice;
    uint minBidAmountIfCurrentBidZero;
    uint16 minBidIncrementPercentage;
    uint64 auctionDuration;
}

struct GameOpenEditionStorage {
    bool paused;
    uint64 startTime;
    uint64 duration;
    uint64 totalMinted;
    uint pricePerToken;
    string tokenSlug;
}

struct GameStorage {
    bool initialized;
    address bookContract;
    
    uint8 seedBlockGap;
    
    mapping(address => mapping(string => uint)) userChestSetSeedBlocks;
    mapping(address => mapping(string => string)) userChestSetActiveChestSlug;
    mapping(string => NFTVault) nftVaults;
    mapping(string => Prize) prizes;
    mapping(string => Chest) chests;
    mapping(string => ChestSet) chestSets;
    mapping(uint => GameItemTokenInfo) tokenIdToTokenInfo;

    address withdrawAddress;
    string auctionItemSlug;
    
    bool operatorFilteringEnabled;
}

library LibStorage {
    bytes32 constant BOOK_STORAGE_POSITION = keccak256("c21.babylon.game.book.storage");
    bytes32 constant GAME_STORAGE_POSITION = keccak256("c21.babylon.game.game.storage");
    bytes32 constant GAME_OPEN_EDITION_STORAGE_POSITION = keccak256("c21.babylon.game.openedition.storage");
    bytes32 constant GAME_AUCTION_STORAGE_POSITION = keccak256("c21.babylon.game.auction.storage");
    bytes32 constant GAME_AUCTION_CONFIG_STORAGE_POSITION = keccak256("c21.babylon.game.auction.config.storage");
    bytes32 constant PUNK_DATA_STORAGE_POSITION = keccak256("c21.babylon.game.book.punk.data.storage");
    
    function bookStorage() internal pure returns (BookStorage storage gs) {
        bytes32 position = BOOK_STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }
    
    function punkDataStorage() internal pure returns (PunkDataStorage storage gs) {
        bytes32 position = PUNK_DATA_STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }
    
    function gameStorage() internal pure returns (GameStorage storage gs) {
        bytes32 position = GAME_STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }
    
    function gameOpenEditionStorage() internal pure returns (GameOpenEditionStorage storage gs) {
        bytes32 position = GAME_OPEN_EDITION_STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }
    
    function gameAuctionStorage() internal pure returns (GameAuctionStorage storage gs) {
        bytes32 position = GAME_AUCTION_STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }
    
    function gameAuctionConfigStorage() internal pure returns (GameAuctionConfigStorage storage gs) {
        bytes32 position = GAME_AUCTION_CONFIG_STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }
}

contract WithStorage {
    function bk() internal pure returns (BookStorage storage) {
        return LibStorage.bookStorage();
    }
    
    function ps() internal pure returns (PunkDataStorage storage) {
        return LibStorage.punkDataStorage();
    }
    
    function gs() internal pure returns (GameStorage storage) {
        return LibStorage.gameStorage();
    }
    
    function oes() internal pure returns (GameOpenEditionStorage storage) {
        return LibStorage.gameOpenEditionStorage();
    }
    
    function auct() internal pure returns (GameAuctionStorage storage) {
        return LibStorage.gameAuctionStorage();
    }
    
    function acs() internal pure returns (GameAuctionConfigStorage storage) {
        return LibStorage.gameAuctionConfigStorage();
    }
    
    function ds() internal pure returns (LibDiamond.DiamondStorage storage) {
        return LibDiamond.diamondStorage();
    }
}