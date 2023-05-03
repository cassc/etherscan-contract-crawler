pragma solidity ^0.8.0;

import {SSTORE2} from "solmate/utils/SSTORE2.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Initializable} from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {Synthia, IERC721OwnerOf} from "./Synthia.sol";
import {SynthiaTraits} from "./SynthiaTraits.sol";
import {ISynthiaTraitsERC721} from "./ISynthiaTraitsERC721.sol";

contract SynthiaRenderer is Owned, Initializable {
    error ErrorMessage(string);

    string[] public traits;
    Synthia public synthia;
    SynthiaTraits public synthiaTraits;
    mapping(string => address) public pointers;

    function _getTraitIdx(string memory name) internal view returns (uint256) {
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        for (uint256 i = 0; i < traits.length; i++) {
            if (keccak256(abi.encodePacked(traits[i])) == nameHash) {
                return i;
            }
        }
        revert ErrorMessage("Trait not found");
    }

    function getTraitsLength() public view returns (uint256) {
        return traits.length;
    }

    constructor() Owned(address(0)) {
        _disableInitializers();
    }

    function initialize(
        address _synthia,
        address _synthiaTraits
    ) public initializer {
        synthia = Synthia(_synthia);
        synthiaTraits = SynthiaTraits(_synthiaTraits);
        traits = ["clothes", "hair", "accessory", "hat"];
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    mapping(address => bool) public traitAdmin;

    function updateTraitAdmin(
        address traitAdminAddr,
        bool value
    ) public onlyOwner {
        traitAdmin[traitAdminAddr] = value;
    }

    modifier onlyTraitAdmin() {
        if (msg.sender != address(synthia)) {
            revert ErrorMessage("Not synthia");
        }
        _;
    }

    function addPointer(
        string memory name,
        string calldata data
    ) public onlyOwner {
        if (pointers[name] != address(0)) {
            revert ErrorMessage("Pointer exists");
        }
        pointers[name] = SSTORE2.write(bytes(data));
    }

    function getData(string memory name) public view returns (string memory) {
        return string(SSTORE2.read(pointers[name]));
    }

    function getSvgString() public view returns (string memory) {}

    struct FilterId {
        string hair;
        string clothes;
        string hat;
        string acc;
        string shaman;
    }

    function _getFilterIds() internal pure returns (FilterId memory filters) {
        return
            FilterId({
                hair: "hf",
                clothes: "cf",
                hat: "htf",
                acc: "accf",
                shaman: "sf"
            });
    }

    function _getFilter(
        string memory id,
        string memory color
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<filter id="',
                id,
                '"><feFlood flood-color="',
                color,
                '" result="overlayColor" /><feComposite operator="in" in="overlayColor" in2="SourceAlpha" result="coloredAlpha" /><feBlend mode="overlay" in="coloredAlpha" in2="SourceGraphic" /></filter>'
            );
    }

    function _getImageDef(
        string memory data,
        string memory id
    ) internal pure returns (string memory) {
        return string.concat('<image href="', data, '" id="', id, '"></image>');
    }

    function _getSvgFilters(
        Colors memory colors
    ) internal view returns (string memory) {
        FilterId memory filters = _getFilterIds();
        return
            string.concat(
                _getFilter(filters.shaman, "#00cbdd"),
                _getFilter(filters.hair, colors.hair),
                _getFilter(filters.clothes, colors.clothes),
                _getFilter(filters.hat, colors.hat),
                _getFilter(filters.acc, colors.acc)
            );
    }

    function getMultipleSeeds(
        uint256 initialSeed,
        uint8 numSeeds
    ) public pure returns (uint256[] memory seeds) {
        seeds = new uint[](numSeeds);

        for (uint8 i = 0; i < numSeeds; i++) {
            uint256 shiftedSeed = (initialSeed >> i) |
                (initialSeed << (256 - i));
            seeds[i] = uint256(keccak256(abi.encode(shiftedSeed)));
        }
    }

    function _getDefs(
        Colors memory colors
    ) internal view returns (string memory) {
        return
            string.concat(
                "<defs>",
                _getSvgFilters(colors),
                '<clipPath id="c"><rect width="400" height="400" /></clipPath>',
                _getImageDef(getData("body"), "bimg"),
                _getImageDef(getData("clothes"), "cimg"),
                _getImageDef(getData("hair"), "himg"),
                _getImageDef(getData("hat"), "htimg"),
                _getImageDef(getData("accessory"), "acimg"),
                "</defs>"
            );
    }

    function _chance(
        uint256 percent,
        uint256 seed
    ) internal pure returns (bool) {
        return _randomNumberBetween(1, 100, seed) <= percent;
    }

    function _randomNumberBetween(
        uint256 start,
        uint256 end,
        uint256 seed
    ) internal pure returns (uint256) {
        uint256 range = end - start + 1;
        uint256 randomNumber = start + (seed % range);

        return randomNumber;
    }

    function _getX(uint256 seed) internal pure returns (uint256) {
        return _randomNumberBetween(0, 4, seed);
    }

    function _getY(uint256 seed) internal pure returns (uint256) {
        return _randomNumberBetween(0, 5, seed);
    }

    struct Pos {
        uint256 bodyX;
        uint256 clothesX;
        uint256 clothesY;
        uint256 hairX;
        uint256 hairY;
        uint256 hatX;
        uint256 hatY;
        uint256 accX;
        uint256 accY;
    }

    struct Colors {
        string bg;
        string clothes;
        string hat;
        string hair;
        string acc;
    }

    struct TraitInfo {
        string factionName;
        uint256 factionIdx;
        uint intelligence;
        uint agility;
        uint charisma;
        uint wisdom;
        uint strength;
        uint technomancy;
        bool hasHair;
        bool hasAccessory;
        bool hasHat;
        bool hasCustomClothes;
        bool hasCustomHair;
        bool hasCustomAccessory;
        bool hasCustomHat;
        bool canBeHybrid;
    }

    function _getTraitType(
        string memory name,
        string memory value,
        bool custom,
        bool comma
    ) internal pure returns (string memory) {
        return
            string.concat(
                '{"trait_type":"',
                name,
                custom ? " [CUSTOM]" : "",
                '","value":"',
                value,
                '"}',
                comma ? "," : ""
            );
    }

    function _getStatType(
        string memory name,
        uint value,
        bool comma
    ) internal pure returns (string memory) {
        return
            string.concat(
                '{"trait_type":"',
                name,
                '","value":',
                Strings.toString(value),
                "}",
                comma ? "," : ""
            );
    }

    function _getCustomTraitName(
        uint256 tokenId,
        uint256 idx
    ) internal view returns (string memory) {
        CustomTrait memory trait = tokenIdToIdxToCustomTrait[tokenId][idx];
        try
            ISynthiaTraitsERC721(trait.contractAddress).getTraitName(
                trait.tokenId
            )
        returns (string memory traitName) {
            return traitName;
        } catch {
            return "";
        }
    }

    function _getStats(
        TraitInfo memory traitInfo
    ) internal pure returns (string memory) {
        return
            string.concat(
                _getStatType("Intelligence", traitInfo.intelligence, true),
                _getStatType("Agility", traitInfo.agility, true),
                _getStatType("Strength", traitInfo.strength, true),
                _getStatType("Charisma", traitInfo.charisma, true),
                _getStatType("Wisdom", traitInfo.wisdom, true),
                _getStatType("Technomancy", traitInfo.technomancy, true)
            );
    }

    function _getAttrs(
        uint256 tokenId,
        Pos memory pos,
        TraitInfo memory traitInfo
    ) internal view returns (string memory) {
        return
            string.concat(
                "[",
                _getStats(traitInfo),
                traitInfo.hasHat
                    ? _getTraitType(
                        "hat",
                        traitInfo.hasCustomHat
                            ? _getCustomTraitName(tokenId, _getTraitIdx("hat"))
                            : synthiaTraits.getHatName(
                                uint16(pos.hatX),
                                uint16(pos.hatY)
                            ),
                        traitInfo.hasCustomHat,
                        true
                    )
                    : "",
                traitInfo.hasAccessory
                    ? _getTraitType(
                        "accessory",
                        traitInfo.hasCustomAccessory
                            ? _getCustomTraitName(
                                tokenId,
                                _getTraitIdx("accessory")
                            )
                            : synthiaTraits.getAccesoryName(
                                uint16(pos.accX),
                                uint16(pos.accY)
                            ),
                        traitInfo.hasCustomAccessory,
                        true
                    )
                    : "",
                traitInfo.hasHair
                    ? _getTraitType(
                        "hair",
                        traitInfo.hasCustomHair
                            ? _getCustomTraitName(tokenId, _getTraitIdx("hair"))
                            : synthiaTraits.getHairName(
                                uint16(pos.hairX),
                                uint16(pos.hairY)
                            ),
                        traitInfo.hasCustomHair,
                        true
                    )
                    : "",
                _getTraitType("faction", traitInfo.factionName, false, true),
                _getTraitType(
                    "clothes",
                    traitInfo.hasCustomClothes
                        ? _getCustomTraitName(tokenId, _getTraitIdx("clothes"))
                        : synthiaTraits.getClothesName(
                            uint16(pos.clothesX),
                            uint16(pos.clothesY)
                        ),
                    traitInfo.hasCustomClothes,
                    false
                ),
                "]"
            );
    }

    function getPrerevealMetadataUri() public pure returns (string memory) {
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        '{"name":"Synthia Virtual Identity Bootloader","description":"Loading...","image":"https://lpmetadata.s3.us-west-1.amazonaws.com/bootloader.gif"}'
                    )
                )
            );
    }

    function getMetadataDataUri(
        uint256 seed,
        uint256 tokenId
    ) public view returns (string memory) {
        uint256[] memory seeds = getMultipleSeeds(seed, 25);
        TraitInfo memory traitInfo = getTraitInfo(seeds, tokenId);
        Pos memory pos = _getPos(seeds, traitInfo.factionIdx);

        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        string.concat(
                            '{"name":"Synthia Identity #',
                            Strings.toString(tokenId),
                            '","image":"',
                            string.concat(
                                "data:image/svg+xml;base64,",
                                Base64.encode(
                                    bytes(
                                        _getSvg(
                                            tokenId,
                                            traitInfo,
                                            pos,
                                            _getColors(seeds)
                                        )
                                    )
                                )
                            ),
                            '","attributes":',
                            _getAttrs(tokenId, pos, traitInfo),
                            ',"description":"',
                            synthiaTraits.getDescription(),
                            '"}'
                        )
                    )
                )
            );
    }

    function _getSvg(
        uint256 tokenId,
        TraitInfo memory traitInfo,
        Pos memory pos,
        Colors memory colors
    ) internal view returns (string memory) {
        FilterId memory filters = _getFilterIds();
        uint32 clothesTrait = synthiaTraits.packXY(
            uint16(pos.clothesX),
            uint16(pos.clothesY)
        );

        bool isHood = clothesTrait == 131072 ||
            clothesTrait == 262145 ||
            clothesTrait == 196610 ||
            clothesTrait == 262147;
        string memory clothes = _getTraitString(
            filters.clothes,
            "cimg",
            pos.clothesX,
            pos.clothesY
        );

        return
            _constructSvg(
                SvgParameters(
                    tokenId,
                    traitInfo,
                    pos,
                    colors,
                    isHood,
                    clothes,
                    filters
                )
            );
    }

    function _getFactionArr() internal view returns (string[6] memory) {
        return [
            "Neo-Luddites",
            "Data Syndicate",
            "Techno Shamans",
            "The Grid",
            "The Reclaimed",
            "The Disconnected"
        ];
    }

    function getTraitInfo(
        uint256[] memory seeds,
        uint256 tokenId
    ) public view returns (TraitInfo memory) {
        string[6] memory factions = _getFactionArr();
        uint256 factionIdx = _randomNumberBetween(
            0,
            factions.length - 1,
            seeds[17]
        );
        return
            TraitInfo({
                factionName: factions[factionIdx],
                factionIdx: factionIdx,
                hasHair: _chance(90, seeds[0]),
                hasAccessory: _chance(50, seeds[1]),
                hasHat: _chance(50, seeds[2]),
                hasCustomClothes: hasCustomTrait(tokenId, 0),
                hasCustomHair: hasCustomTrait(tokenId, 1),
                hasCustomAccessory: hasCustomTrait(tokenId, 2),
                hasCustomHat: hasCustomTrait(tokenId, 3),
                canBeHybrid: factionIdx == 2 ? _chance(5, seeds[18]) : false,
                intelligence: _randomNumberBetween(1, 100, seeds[19]),
                agility: _randomNumberBetween(1, 100, seeds[20]),
                charisma: _randomNumberBetween(1, 100, seeds[21]),
                wisdom: _randomNumberBetween(1, 100, seeds[22]),
                technomancy: _randomNumberBetween(1, 100, seeds[23]),
                strength: _randomNumberBetween(1, 100, seeds[24])
            });
    }

    function _getPos(
        uint256[] memory seeds,
        uint256 factionIdx
    ) internal pure returns (Pos memory) {
        return
            Pos({
                // If faction is techno shaman then allow for transcendence
                bodyX: _randomNumberBetween(
                    0,
                    factionIdx == 2 ? 3 : 2,
                    seeds[16]
                ),
                clothesX: _getX(seeds[3]),
                // Neo-luddites only wear neo luddite clothes
                clothesY: factionIdx == 0 ? 0 : _getY(seeds[4]),
                hairX: _getX(seeds[5]),
                hairY: _getY(seeds[6]),
                hatX: _getX(seeds[7]),
                hatY: factionIdx == 0 ? 0 : _getY(seeds[8]),
                accX: _getX(seeds[9]),
                accY: factionIdx == 0 ? 0 : _getY(seeds[10])
            });
    }

    function _getColorArrays()
        internal
        pure
        returns (string[6] memory, string[8] memory)
    {
        string[6] memory bgColors = [
            "#FF2079",
            "#28fcb3",
            "#1C1C1C",
            "#7122FA",
            "#FDBC3B",
            "#1ba6fe"
        ];
        string[8] memory traitColors = [
            // Blue
            "#0039f3",
            // magenta
            "#d400f3",
            // brown
            "#4b2d15",
            // lime
            "#4de245",
            // cyan
            "#45e2d9",
            // gold
            "#ffd325",
            // light blue
            "#7baaf6",
            // gray
            "#919191"
        ];
        return (bgColors, traitColors);
    }

    function _getColors(
        uint256[] memory seeds
    ) internal view returns (Colors memory) {
        (
            string[6] memory bgColors,
            string[8] memory traitColors
        ) = _getColorArrays();
        return
            Colors({
                bg: bgColors[
                    _randomNumberBetween(0, bgColors.length - 1, seeds[11])
                ],
                clothes: traitColors[
                    _randomNumberBetween(0, traitColors.length - 1, seeds[12])
                ],
                hat: traitColors[
                    _randomNumberBetween(0, traitColors.length - 1, seeds[13])
                ],
                hair: traitColors[
                    _randomNumberBetween(0, traitColors.length - 1, seeds[14])
                ],
                acc: traitColors[
                    _randomNumberBetween(0, traitColors.length - 1, seeds[15])
                ]
            });
    }

    // Define a new struct to group related parameters.
    struct SvgParameters {
        uint256 tokenId;
        TraitInfo traitInfo;
        Pos pos;
        Colors colors;
        bool isHood;
        string clothes;
        FilterId filters;
    }

    function _constructSvg(
        SvgParameters memory params
    ) internal view returns (string memory) {
        string memory accessory = params.traitInfo.hasCustomAccessory
            ? _getCustomTraitSvgString(params.tokenId, 2)
            : params.traitInfo.hasAccessory
            ? _getTraitString(
                params.filters.acc,
                "acimg",
                params.pos.accX,
                params.pos.accY
            )
            : "";

        uint32 packedHat = synthiaTraits.packXY(
            uint16(params.pos.hatX),
            uint16(params.pos.hatY)
        );
        bool accessoryOverHat = params.pos.hatY == 0 ||
            params.pos.hatY == 5 ||
            packedHat == 262147;

        string memory hat = params.traitInfo.hasCustomHat
            ? _getCustomTraitSvgString(params.tokenId, 3)
            : params.traitInfo.hasHat
            ? _getTraitString(
                params.filters.hat,
                "htimg",
                params.pos.hatX,
                params.pos.hatY
            )
            : "";
        return
            string.concat(
                '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400" width="400" height="400">',
                _getDefs(params.colors),
                '<g clip-path="url(#c)">',
                '<rect width="400" height="400" fill="',
                params.colors.bg,
                '" />',
                _getBodyString(
                    params.pos.bodyX,
                    params.filters,
                    params.traitInfo
                ),
                !params.isHood
                    ? params.traitInfo.hasCustomClothes
                        ? _getCustomTraitSvgString(params.tokenId, 0)
                        : params.clothes
                    : "",
                params.traitInfo.hasCustomHair
                    ? _getCustomTraitSvgString(params.tokenId, 1)
                    : params.traitInfo.hasHair
                    ? _getTraitString(
                        params.filters.hair,
                        "himg",
                        params.pos.hairX,
                        params.pos.hairY
                    )
                    : "",
                accessoryOverHat ? hat : accessory,
                accessoryOverHat ? accessory : hat,
                params.isHood
                    ? params.traitInfo.hasCustomClothes
                        ? _getCustomTraitSvgString(params.tokenId, 0)
                        : params.clothes
                    : "",
                "</g></svg>"
            );
    }

    struct CustomTrait {
        address contractAddress;
        uint256 tokenId;
    }

    mapping(uint256 => mapping(uint256 => CustomTrait))
        public tokenIdToIdxToCustomTrait;

    function clearCustomTrait(
        uint256 tokenId,
        uint256 idx
    ) public onlyTraitAdmin {
        delete tokenIdToIdxToCustomTrait[tokenId][idx];
    }

    function _getCustomTraitSvgString(
        uint256 tokenId,
        uint256 idx
    ) internal view returns (string memory) {
        return
            string.concat(
                '<image href="',
                _getCustomTraitImage(tokenId, idx),
                '" width="400" height="400"></image>'
            );
    }

    function hasCustomTrait(
        uint256 tokenId,
        uint256 idx
    ) public view returns (bool) {
        CustomTrait memory trait = tokenIdToIdxToCustomTrait[tokenId][idx];
        if (trait.contractAddress == address(0)) {
            return false;
        }

        try
            IERC721OwnerOf(trait.contractAddress).ownerOf(trait.tokenId)
        returns (address owner) {
            if (synthia.ownerOf(tokenId) != owner) {
                return false;
            }
            return true;
        } catch {
            return false;
        }
    }

    function _getCustomTraitImage(
        uint256 tokenId,
        uint256 idx
    ) internal view returns (string memory) {
        CustomTrait memory trait = tokenIdToIdxToCustomTrait[tokenId][idx];

        try
            ISynthiaTraitsERC721(trait.contractAddress).getTraitImage(
                trait.tokenId
            )
        returns (string memory traitImage) {
            return traitImage;
        } catch {
            return "";
        }
    }

    function setCustomTrait(
        uint256 tokenId,
        uint256 idx,
        address traitContractAddress,
        uint256 traitTokenId
    ) public onlyTraitAdmin {
        tokenIdToIdxToCustomTrait[tokenId][idx] = CustomTrait({
            contractAddress: traitContractAddress,
            tokenId: traitTokenId
        });
    }

    function _getBodyString(
        uint256 bodyX,
        FilterId memory filters,
        TraitInfo memory traitInfo
    ) internal pure returns (string memory) {
        return
            string.concat(
                "<use",
                bodyX == 3
                    ? string.concat(' filter="url(#', filters.shaman, ')"')
                    : "",
                ' href="#bimg',
                '" x="-',
                Strings.toString(bodyX * 400),
                '" y="0" width="400" height="400" />',
                traitInfo.canBeHybrid && traitInfo.factionIdx == 2 && bodyX != 3
                    ? string.concat(
                        "<use",
                        string.concat(' filter="url(#', filters.shaman, ')"'),
                        ' href="#bimg',
                        '" x="-',
                        Strings.toString(4 * 400),
                        '" y="0" width="400" height="400" />'
                    )
                    : ""
            );
    }

    function _getTraitString(
        string memory filterId,
        string memory href,
        uint256 x,
        uint256 y
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<use filter="url(#',
                filterId,
                ')" href="#',
                href,
                '" x="-',
                Strings.toString(x * 400),
                '" y="-',
                Strings.toString(y * 400),
                '" width="400" height="400" />'
            );
    }
}