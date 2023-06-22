// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "solady/src/utils/DynamicBufferLib.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/SafeTransferLib.sol";
import "solady/src/utils/Base64.sol";
import "solady/src/utils/SSTORE2.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "solady/src/utils/LibPRNG.sol";
import "solady/src/tokens/ERC721.sol";

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ERC1155Holder, ERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

import "hardhat/console.sol";

interface PunkDataInterface {
    function punkImage(uint16 index) external view returns (bytes memory);
    function punkAttributes(uint16 index) external view returns (string memory);
}

interface BabylonBook {
    function renderAssetSvgRects(uint8 assetIndex) external view returns (string memory);
}

interface EPD {
    enum PunkAttributeType {SEX, HAIR, EYES, BEARD, EARS, LIPS, MOUTH,
                                FACE, EMOTION, NECK, NOSE, CHEEKS, TEETH}
    
    enum PunkAttributeValue {NONE, ALIEN, APE, BANDANA, BEANIE, BIG_BEARD, BIG_SHADES, BLACK_LIPSTICK, BLONDE_BOB, BLONDE_SHORT, BLUE_EYE_SHADOW, BUCK_TEETH, CAP, CAP_FORWARD, CHINSTRAP, CHOKER, CIGARETTE, CLASSIC_SHADES, CLOWN_EYES_BLUE, CLOWN_EYES_GREEN, CLOWN_HAIR_GREEN, CLOWN_NOSE, COWBOY_HAT, CRAZY_HAIR, DARK_HAIR, DO_RAG, EARRING, EYE_MASK, EYE_PATCH, FEDORA, FEMALE, FRONT_BEARD, FRONT_BEARD_DARK, FROWN, FRUMPY_HAIR, GOAT, GOLD_CHAIN, GREEN_EYE_SHADOW, HALF_SHAVED, HANDLEBARS, HEADBAND, HOODIE, HORNED_RIM_GLASSES, HOT_LIPSTICK, KNITTED_CAP, LUXURIOUS_BEARD, MALE, MEDICAL_MASK, MESSY_HAIR, MOHAWK, MOHAWK_DARK, MOHAWK_THIN, MOLE, MUSTACHE, MUTTONCHOPS, NERD_GLASSES, NORMAL_BEARD, NORMAL_BEARD_BLACK, ORANGE_SIDE, PEAK_SPIKE, PIGTAILS, PILOT_HELMET, PINK_WITH_HAT, PIPE, POLICE_CAP, PURPLE_EYE_SHADOW, PURPLE_HAIR, PURPLE_LIPSTICK, RED_MOHAWK, REGULAR_SHADES, ROSY_CHEEKS, SHADOW_BEARD, SHAVED_HEAD, SILVER_CHAIN, SMALL_SHADES, SMILE, SPOTS, STRAIGHT_HAIR, STRAIGHT_HAIR_BLONDE, STRAIGHT_HAIR_DARK, STRINGY_HAIR, TASSLE_HAT, THREE_D_GLASSES, TIARA, TOP_HAT, VAMPIRE_HAIR, VAPE, VR, WELDING_GOGGLES, WILD_BLONDE, WILD_HAIR, WILD_WHITE_HAIR, ZOMBIE}
    
    function attrStringToEnumMapping(string memory) external view returns (PunkAttributeValue);
    function attrEnumToStringMapping(PunkAttributeValue) external view returns (string memory);
    function attrValueToTypeEnumMapping(PunkAttributeValue) external view returns (PunkAttributeType);
}

contract Drunks is Ownable, ERC721, ERC2981, ERC1155Holder, OperatorFilterer {
    error ContractsCannotMint();
    error MustMintAtLeastOneToken();
    error NotEnoughAvailableTokens();
    error NeedExactPayment();
    error MintIsNotActive();
    error ContractSealed();
    error NothingToWithdraw();
    error WrongKeyContract();
    error WrongKeyItem();
    error WrongKeyAmount();
    error NoMoreRemainingKeyMints();
    
    using LibString for *;
    using SafeTransferLib for *;
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;
    using LibPRNG for LibPRNG.PRNG;
    
    struct TraitData {
        uint8 id;
        EPD.PunkAttributeType traitType;
        EPD.PunkAttributeValue traitValueEnum;
        bool isFallen;
        int8[2] translate;
        string internalName;
        string externalName;
    }
    
    struct Drunk {
        uint16 id;
        uint8 fallenTraitCount;
        TraitData[] traits;
    }
    
    struct ContractConfig {
        string name;
        string nameSingular;
        string symbol;
        string externalLink;
        string tokenDescription;
        uint costPerToken;
        uint16 maxSupply;
        uint16 remainingSupply;
        uint8 remainingKeyMints;
        bool operatorFilteringEnabled;
        bool isMintActive;
        bool contractSealed;
    }
    
    ContractConfig internal config;
    
    function getConfig() external view returns (ContractConfig memory) {
        return config;
    }
    
    PunkDataInterface public immutable punkDataContract;
    EPD public immutable extendedPunkDataContract;
    BabylonBook public immutable babylonBook;
    IERC1155 public immutable babylonGame;
    
    address internal constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint public constant babylonKeyTokenId = 98817275316469254658835613186317234565061035910961234952676070055051228466648;
    
    uint16[626] internal drunkIds = [5093,3443,6145,1,17,24,32,39,40,219,239,257,295,317,348,370,389,415,416,429,461,495,523,546,562,597,621,623,638,643,656,676,686,704,707,716,825,842,885,908,918,920,959,962,986,1000,1049,1100,1118,1133,1154,1171,1193,1211,1260,1266,1303,1338,1359,1380,1425,1429,1447,1481,1483,1507,1560,1578,1585,1605,1636,1641,1643,1655,1702,1703,1728,1748,1762,1770,1793,1794,1795,1796,1839,1851,1871,1912,1919,2032,2097,2126,2157,2163,2167,2192,2208,2242,2261,2307,2308,2314,2319,2344,2362,2377,2379,2387,2421,2424,2441,2466,2469,2471,2494,2548,2571,2587,2589,2632,2636,2639,2644,2648,2657,2672,2691,2693,2715,2718,2727,2763,2767,2795,2894,2951,2961,3011,3016,3017,3032,3039,3084,3090,3117,3130,3136,3152,3169,3172,3174,3177,3182,3184,3197,3230,3250,3283,3288,3292,3305,3313,3330,3362,3365,3393,3400,3406,3411,3415,3438,3439,3444,3460,3463,3538,3555,3558,3569,3596,3625,3643,3677,3689,3700,3758,3760,3766,3810,3814,3822,3852,3871,3889,3929,3967,3974,3978,3982,4002,4005,4024,4047,4050,4068,4074,4141,4142,4143,4192,4239,4280,4288,4289,4298,4311,4322,4352,4370,4371,4387,4411,4415,4450,4457,4488,4494,4505,4528,4529,4556,4558,4572,4574,4632,4640,4651,4667,4669,4676,4694,4697,4707,4715,4730,4735,4736,4746,4749,4774,4781,4785,4798,4805,4807,4842,4847,4863,4920,4923,4976,4998,5003,5047,5066,5072,5098,5101,5113,5120,5125,5131,5149,5176,5205,5229,5233,5238,5261,5263,5276,5327,5377,5401,5410,5423,5433,5456,5460,5465,5466,5477,5491,5492,5529,5548,5604,5614,5643,5655,5657,5659,5683,5716,5728,5732,5733,5736,5774,5804,5805,5863,5877,5914,5925,5935,5956,5962,5984,6051,6056,6058,6060,6061,6063,6066,6081,6101,6106,6112,6140,6188,6203,6229,6279,6289,6291,6303,6354,6392,6420,6427,6438,6447,6463,6475,6494,6529,6539,6540,6552,6586,6602,6632,6633,6652,6655,6657,6661,6673,6682,6704,6711,6717,6721,6724,6726,6784,6795,6898,6943,6953,6976,6992,6996,7031,7042,7051,7080,7087,7115,7130,7134,7166,7185,7190,7198,7201,7224,7242,7253,7270,7273,7277,7297,7298,7314,7331,7332,7335,7345,7368,7401,7410,7420,7424,7425,7431,7435,7440,7442,7477,7484,7496,7510,7539,7549,7550,7564,7571,7578,7579,7588,7591,7600,7602,7660,7667,7671,7688,7692,7711,7716,7738,7740,7763,7765,7770,7771,7772,7784,7787,7835,7862,7889,7890,7892,7917,7918,7920,7925,7926,7944,7947,7953,7956,7977,7988,8000,8019,8026,8036,8079,8086,8101,8105,8107,8120,8136,8141,8152,8171,8174,8176,8179,8191,8213,8231,8244,8262,8263,8301,8312,8320,8337,8346,8362,8369,8373,8385,8389,8390,8393,8413,8430,8445,8447,8448,8463,8482,8499,8507,8546,8551,8561,8567,8571,8594,8608,8609,8615,8622,8624,8634,8658,8667,8677,8685,8700,8715,8748,8750,8756,8772,8781,8786,8801,8803,8809,8812,8830,8840,8867,8875,8884,8889,8891,8908,8918,8925,8926,8935,8940,8946,8998,9008,9016,9022,9036,9038,9046,9050,9056,9080,9083,9084,9089,9090,9097,9110,9113,9130,9145,9156,9162,9166,9168,9192,9242,9259,9279,9283,9289,9300,9314,9316,9330,9336,9355,9357,9362,9374,9375,9385,9412,9415,9418,9422,9436,9437,9516,9547,9565,9569,9573,9591,9600,9612,9628,9637,9648,9653,9659,9667,9668,9688,9709,9734,9760,9767,9774,9804,9807,9811,9813,9816,9827,9912,9936,9952,9959,9960,9972,9984,9992,9996];
    
    bytes internal constant hashedAssetNames = hex'f2832d534c54446e7286885ad519e00a8b72758d32b85d54faa61b214c6dabe4be3849f4a9d6ff4df983dac6f1faa1511907503b08bea978e9bd0b5dd382b4afcfa9eb095ef25649834463fbe584a554ca5c443de39d7c2877d127c44c21cde6553bc39f4024da6ecfe9661143c88a1818e899dc16b9249f7a54ac877e558c0e364f38889c3fb7c60ab7f036d85c589a4de0d5e29aafd325873c711ce6eb02e44fbed4c57fc058ffccc5be2f3136a21adadb49536ba0ccf9382afaadfc84194a1659ce4584bbce09060896a25fcd06c8d604dd721833744e856106d6b019f52894a6195d3292c84a3f13a7f57c3c44575730838ddfb9d6b84c63fcf77f8cbf07fe4c3225b46654de12bd';

    address constant pivAddress = 0xf98537696e2Cf486F8F32604B2Ca2CDa120DBBa8;
    address constant middleAddress = 0x31c388503566D2E0BA335D22792BddF90bC86C82;
    
    mapping(bool => mapping(EPD.PunkAttributeValue => int8[2])) isFemaleToTranslations;
    
    function isHat(uint8 assetId) internal pure returns (bool res) {
        uint8[10] memory hats = [16,22,25,37,38,46,51,60,105,113];
        
        for (uint i; i < hats.length; ++i) {
            if (hats[i] == assetId) {
                res = true;
            }
        }
    }
    
    function isWig(uint8 assetId) internal pure returns (bool res) {
        uint8[4] memory wigs = [58,65,93,101];
        
        for (uint i; i < wigs.length; ++i) {
            if (wigs[i] == assetId) {
                res = true;
            }
        }
    }
    
    function isSmokingDevice(uint8 assetId) internal pure returns (bool res) {
        uint8[6] memory smokingDevices = [19,32,64,95,115,120];

        for (uint i; i < smokingDevices.length; ++i) {
            if (smokingDevices[i] == assetId) {
                res = true;
            }
        }
    }
    
    function isGlasses(uint8 assetId) internal pure returns (bool res) {
        uint8[14] memory glasses = [20,21,31,35,43,62,72,82,84,89,102,119,124,132];
        
        for (uint i; i < glasses.length; ++i) {
            if (glasses[i] == assetId) {
                res = true;
            }
        }
    }
    
    function name() public view virtual override returns (string memory) {
        return config.name;
    }

    function symbol() public view virtual override returns (string memory) {
        return config.symbol;
    }
    
    function maxSupply() external view returns (uint) {
        return config.maxSupply;
    }
    
    function totalSupply() external view returns (uint16) {
        return config.maxSupply - config.remainingSupply;
    }
    
    function remainingSupply() external view returns (uint16) {
        return config.remainingSupply;
    }
    
    function setContractConfig(ContractConfig calldata _config) external onlyOwner unsealed {
        config = _config;
    }
    
    function _internalEthMint(address to, uint _numToMint) internal {
        if (msg.value != totalMintCost(_numToMint)) revert NeedExactPayment();
        if (msg.sender != tx.origin) revert ContractsCannotMint();

        _internalMintWithoutCostCheck(to, _numToMint);
    }
    
    function _internalKeyMint(address to, uint _numToMint) internal {
        _internalMintWithoutCostCheck(to, _numToMint);
    }
    
    function _internalMintWithoutCostCheck(address to, uint _numToMint) internal {
        if (!config.isMintActive) revert MintIsNotActive();
        if (_numToMint == 0) revert MustMintAtLeastOneToken();
        if (config.remainingSupply < _numToMint) revert NotEnoughAvailableTokens();

        uint seed = uint(keccak256(abi.encodePacked(
            block.timestamp, block.difficulty
        )));
        
        LibPRNG.PRNG memory prng = LibPRNG.PRNG(seed);
        
        uint16 updatedRemainingSupply = config.remainingSupply;
        
        for (uint i; i < _numToMint;) {
            uint randomIndex = prng.uniform(updatedRemainingSupply);

            uint16 tokenId = getAvailableTokenAtIndex(randomIndex, updatedRemainingSupply);
            
            _mint(to, tokenId);
            _setExtraData(tokenId, uint96(seed));
            
            --updatedRemainingSupply;
            
            unchecked {++i;}
        }
        
        config.remainingSupply = updatedRemainingSupply;
    }
    
    function getAvailableTokenAtIndex(uint indexToUse, uint16 updatedRemainingSupply)
        internal
        returns (uint16)
    {
        uint16 result = drunkIds[indexToUse];

        uint16 lastIndex = updatedRemainingSupply - 1;
        uint16 lastValInArray = drunkIds[lastIndex];
        
        if (indexToUse != lastIndex) {
            drunkIds[indexToUse] = lastValInArray;
        }
        
        return result;
    }
    
    modifier unsealed() {
        if (config.contractSealed) revert ContractSealed();
        _;
    }
    
    function setTokenDescription(string calldata _tokenDescription) external onlyOwner unsealed {
        config.tokenDescription = _tokenDescription;
    }
    
    function sealContract() external onlyOwner unsealed {
        config.contractSealed = true;
    }
    
    function flipMintState() external onlyOwner {
        config.isMintActive = !config.isMintActive;
    }
    
    function getTwoBytesAtIndex(bytes memory data, uint256 index) internal pure returns (bytes2) {
        return bytes2((uint16(uint8(data[2 * index])) << 8) | uint16(uint8(data[2 * index + 1])));
    }
    
    function assetNameToAssetId(string memory input) public pure returns (uint8 assetId) {
        uint needle = uint(uint16(bytes2(uint16(uint(keccak256(bytes(input)))))));

        uint256 assetCount = hashedAssetNames.length / 2;
        
        for (uint i; i < assetCount;) {
            uint el = uint256(uint16(getTwoBytesAtIndex(hashedAssetNames, i)));
            
            if (el == needle) {
                return uint8(i + 1);
            }
            
            unchecked {++i;}
        }
    }
    
    constructor(ContractConfig memory _config) {
        config = _config;
        
        config.maxSupply = uint16(drunkIds.length);
        config.remainingSupply = config.maxSupply;
        config.contractSealed = false;
        config.remainingKeyMints = 25;
        
        _registerForOperatorFiltering();
        config.operatorFilteringEnabled = true;
        
        _setDefaultRoyalty(address(this), 500);
        
        punkDataContract = PunkDataInterface(
            block.chainid == 5 ?
                0xd61Cb6E357bF34B9280d6cC6F7CCF1E66C2bcf89 :
                0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2
        );
        extendedPunkDataContract = EPD(
            block.chainid == 5 ?
                0xA253808c5ACf2597294b9d15F16D8B0429D9A96A :
                0xf03e345bB89Dc9cFaf8Fda381a9E4417BFB46e7A
        );
        
        babylonBook = BabylonBook(
            block.chainid == 5 ?
                0x38F8Df421283Fbe39AA8a4F89076447c8741703b :
                0xd6f61833206712c429E03142D71232f57b46f8aC
        );
        
        babylonGame = IERC1155(
            block.chainid == 5 ?
                0x698da032E7F01D8aaB4055EDa446347d590205d2 :
                0xd19D35601C9F4156cc2cFCcA42aE4aE4A44ACF9A
        );
    }
    
    function airdrop(address toAddress, uint numTokens) external payable {
        _internalEthMint(toAddress, numTokens);
    }
    
    function mintPublic(uint numTokens) external payable {
        _internalEthMint(msg.sender, numTokens);
    }
    
    function exists(uint tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
    
    function tokenURI(uint256 id) public view override returns (string memory) {
        if (!_exists(id)) revert TokenDoesNotExist();

        return constructTokenURI(uint16(id));
    }
    
    function constructTokenURI(uint16 tokenId) internal view returns (string memory) {
        bytes memory title = abi.encodePacked(config.nameSingular, " #", tokenId.toString());

        string memory imageSvg = tokenImage(tokenId);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"', title, '",'
                                '"description":"', config.tokenDescription.escapeJSON(), '",'
                                '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(wrapSVG(imageSvg))),'",'
                                '"external_url":"', config.externalLink, '",'
                                '"attributes": ',
                                    punkAttributesAsJSON(tokenId),
                                '}'
                            )
                        )
                    )
                )
            );
    }
    
    function tokenImage(uint16 tokenId) public view returns (string memory) {
        DynamicBufferLib.DynamicBuffer memory svgBytes;
        
        svgBytes.append(abi.encodePacked(
            '<svg width="1200" height="1200" shape-rendering="crispEdges" xmlns="http://www.w3.org/2000/svg" ',
            'version="1.2" viewBox="0 0 24 24">',
            '<style>g{transform-origin:center}g.rotate{transform:rotate(90deg)}g.rotate rect[fill="#bababa80"], g.rotate rect[fill="#dedede80"] {display:none}',
            'rect{width:1px;height:1px}</style>',
            '<rect x="0" y="0" style="width:24px;height:14px" fill="#766e61"/>',
            '<rect x="0" y="14" style="width:24px;height:10px" fill="#544b3c"/>'
        ));
        
        svgBytes.append('<g>');
        
        Drunk memory drunk = initializeDrunk(tokenId);
        
        for (uint i; i < drunk.traits.length; ++i) {
            TraitData memory trait = drunk.traits[i];
            
            if (trait.id != 0 && !trait.isFallen) {
                svgBytes.append(abi.encodePacked(
                    '<g class="rotate">',
                        babylonBook.renderAssetSvgRects(trait.id),
                    "</g>"
                ));
            }
        }
        
        for (uint i; i < drunk.traits.length; ++i) {
            TraitData memory trait = drunk.traits[i];
            
            if (trait.id != 0 && trait.isFallen) {
                bytes memory coords = abi.encodePacked(
                    intToString(trait.translate[0]), 'px,', intToString(trait.translate[1]), 'px'
                );
                
                bytes memory translateStr = abi.encodePacked('style="transform:translate(', coords,')"');
            
                bytes memory extraRects;
                
                if (trait.id == 22) {
                    extraRects = '<rect x="6" y="7" fill="black"/><rect x="7" y="6" fill="black"/><rect x="8" y="5" fill="black"/><rect x="9" y="5" fill="black"/><rect x="10" y="5" fill="black"/><rect x="11" y="5" fill="black"/><rect x="12" y="5" fill="black"/><rect x="13" y="5" fill="black"/><rect x="14" y="5" fill="black"/><rect x="15" y="6" fill="black"/><rect x="16" y="7" fill="black"/>';
                }
                
                svgBytes.append(abi.encodePacked(
                    '<g ', translateStr,'>',
                        babylonBook.renderAssetSvgRects(trait.id),
                        extraRects,
                    "</g>"
                ));
            }
        }
        
        svgBytes.append('</g></svg>');
        return string(svgBytes.data);
    }
    
    function intToString(int input) internal pure returns (string memory) {
        return input >= 0 ? uint(input).toString() : string.concat("-", uint(-1 * input).toString());
    }
    
    function wrapSVG(string memory svg) internal pure returns (string memory) {
        return string.concat(
                        '<svg width="100%" height="100%" viewBox="0 0 1200 1200" version="1.2" xmlns="http://www.w3.org/2000/svg"><image width="1200" height="1200" href="data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '"></image></svg>'
                );
    }
    
    function withdraw() external {
        require(address(this).balance > 0);
        
        uint total = address(this).balance;
        uint half = total / 2;
        
        middleAddress.safeTransferETH(half);
        pivAddress.safeTransferETH(total - half);
    }
    
    function totalMintCost(uint numTokens) public view returns (uint) {
        return numTokens * config.costPerToken;
    }
    
    function markDrunkAttributesFallen(Drunk memory drunk) internal view returns (Drunk memory) {
        uint seed = uint(keccak256(abi.encodePacked(
            drunk.id, _getExtraData(drunk.id)
        )));
        
        LibPRNG.PRNG memory prng = LibPRNG.PRNG(seed);
        
        bool isFemale = drunk.traits[0].traitValueEnum == EPD.PunkAttributeValue.FEMALE;
        bool hatFallen;
        bool pipeFallen;
        bool mouthFallen;

        for (uint i; i < drunk.traits.length; ++i) {
            EPD.PunkAttributeType attrType = extendedPunkDataContract.attrValueToTypeEnumMapping(
                extendedPunkDataContract.attrStringToEnumMapping(drunk.traits[i].externalName)
            );
            
            uint8 assetId = drunk.traits[i].id;
            
            if (attrType == EPD.PunkAttributeType.HAIR) {
                if (
                    (isHat(assetId) && prng.uniform(100) >= 5) ||
                    (isWig(assetId) && prng.uniform(100) >= 5)
                ) {
                    drunk.traits[i] = setTranslateOfFallenTraits(isFemale, drunk.traits[i]);
                    drunk.fallenTraitCount++;
                    hatFallen = true;
                }
            }
            
            if (
                attrType == EPD.PunkAttributeType.MOUTH &&
                isSmokingDevice(assetId) &&
                prng.uniform(100) >= 5
            ) {
                drunk.traits[i] = setTranslateOfFallenTraits(isFemale, drunk.traits[i]);
                drunk.fallenTraitCount++;
                mouthFallen = true;
                
                if (drunk.traits[i].traitValueEnum == EPD.PunkAttributeValue.PIPE) {
                    pipeFallen = true;
                }
            }
            
            if (
                attrType == EPD.PunkAttributeType.EYES &&
                isGlasses(assetId) &&
                !pipeFallen &&
                prng.uniform(100) >= 5
            ) {
                drunk.traits[i] = setTranslateOfFallenTraits(isFemale, drunk.traits[i]);
                drunk.fallenTraitCount++;
                
                if (hatFallen) {
                    drunk.traits[i].translate[1]++;
                    drunk.traits[i].translate[0]--;
                    
                    if (!mouthFallen) {
                        drunk.traits[i].translate[0] -= 8;
                    }
                }
            }
        }
        
        return drunk;
    }
    
    function setTranslateOfFallenTraits(
        bool isFemale,
        TraitData memory input
    ) internal view returns (TraitData memory) {
        input.isFallen = true;        
        input.translate = isFemaleToTranslations[isFemale][input.traitValueEnum];
        
        return input;
    }
    
    function initializeDrunk(uint16 punkId) internal view returns (Drunk memory) {
        string memory attributes = punkDataContract.punkAttributes(punkId);

        string[] memory attributeArray = attributes.split(", ");
        
        Drunk memory drunk = Drunk({
            id: punkId,
            fallenTraitCount: 0,
            traits: new TraitData[](attributeArray.length)
        });
        
        for (uint i = 0; i < attributeArray.length; i++) {
            string memory untrimmedAttribute = attributeArray[i];
            string memory trimmedAttribute = untrimmedAttribute;
            uint8 assetId;
            
            if (i == 0) {
                trimmedAttribute = untrimmedAttribute.split(' ')[0];
                assetId = assetNameToAssetId(untrimmedAttribute);
            } else {
                string memory firstLetter = attributeArray[0].slice(0, 1);
                firstLetter = firstLetter.eq("F") ? "F" : "M";
                
                assetId = assetNameToAssetId(
                    string(abi.encodePacked(trimmedAttribute, "_", firstLetter))
                );
            }
            
            EPD.PunkAttributeValue attrValue = extendedPunkDataContract.attrStringToEnumMapping(trimmedAttribute);
            EPD.PunkAttributeType attrType = extendedPunkDataContract.attrValueToTypeEnumMapping(attrValue);
            
            TraitData memory td = TraitData({
                id: assetId,
                traitType: attrType,
                traitValueEnum: attrValue,
                internalName: untrimmedAttribute,
                externalName: trimmedAttribute,
                isFallen: false,
                translate: [int8(0), int8(0)]
            });
            
            drunk.traits[i] = td;
        }
        
        return markDrunkAttributesFallen(drunk);
    }
    
    function punkAttributesAsJSON(uint16 punkId) public view returns (string memory) {
        Drunk memory drunk = initializeDrunk(punkId);
        
        DynamicBufferLib.DynamicBuffer memory outputBytes;
        outputBytes.append("[");
        
        for (uint i; i < drunk.traits.length; ++i) {
            TraitData memory td = drunk.traits[i];
            
            if (td.id != 0) {
                outputBytes.append(bytes(punkAttributeAsJSON(td)));
                
                if (i < drunk.traits.length - 1) {
                    outputBytes.append(",");
                }
            }
        }
        
        outputBytes.append(
            abi.encodePacked(',{"trait_type":"Fallen Traits", "value":"', drunk.fallenTraitCount.toString(), '"}')
        );
        
        return string(abi.encodePacked(outputBytes.data, "]"));
    }
    
    function punkAttributeAsJSON(TraitData memory td) internal pure returns (string memory) {
        string memory attributeAsString = td.externalName;
        string memory attributeTypeAsString;
        
        EPD.PunkAttributeType attrType = td.traitType;
        
        if (attrType == EPD.PunkAttributeType.SEX) {
            attributeTypeAsString = "Sex";
        } else if (attrType == EPD.PunkAttributeType.HAIR) {
            attributeTypeAsString = "Hair";
        } else if (attrType == EPD.PunkAttributeType.EYES) {
            attributeTypeAsString = "Eyes";
        } else if (attrType == EPD.PunkAttributeType.BEARD) {
            attributeTypeAsString = "Beard";
        } else if (attrType == EPD.PunkAttributeType.EARS) {
            attributeTypeAsString = "Ears";
        } else if (attrType == EPD.PunkAttributeType.LIPS) {
            attributeTypeAsString = "Lips";
        } else if (attrType == EPD.PunkAttributeType.MOUTH) {
            attributeTypeAsString = "Mouth";
        } else if (attrType == EPD.PunkAttributeType.FACE) {
            attributeTypeAsString = "Face";
        } else if (attrType == EPD.PunkAttributeType.EMOTION) {
            attributeTypeAsString = "Emotion";
        } else if (attrType == EPD.PunkAttributeType.NECK) {
            attributeTypeAsString = "Neck";
        } else if (attrType == EPD.PunkAttributeType.NOSE) {
            attributeTypeAsString = "Nose";
        } else if (attrType == EPD.PunkAttributeType.CHEEKS) {
            attributeTypeAsString = "Cheeks";
        } else if (attrType == EPD.PunkAttributeType.TEETH) {
            attributeTypeAsString = "Teeth";
        }
        
        return string(abi.encodePacked('{"trait_type":"', attributeTypeAsString, '", "value":"', attributeAsString, '"}'));
    }
    
    function setTranslations(
        EPD.PunkAttributeValue[] calldata femaleValues,
        int8[2][] calldata femaleTranslations,
        EPD.PunkAttributeValue[] calldata nonFemaleValues,
        int8[2][] calldata nonFemaleTranslations
    ) external onlyOwner unsealed {
        uint longerLength = femaleValues.length > nonFemaleValues.length ? femaleValues.length : nonFemaleValues.length;
        
        for (uint i; i < longerLength; ) {
            if (i < femaleValues.length) {
                isFemaleToTranslations[true][femaleValues[i]] = femaleTranslations[i];
            }
            
            if (i < nonFemaleValues.length) {
                isFemaleToTranslations[false][nonFemaleValues[i]] = nonFemaleTranslations[i];
            }
            
            unchecked {++i;}
        }
    }
    
    function remainingKeyMints() external view returns (uint) {
        return config.remainingKeyMints;
    }
    
    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes memory
    ) public override returns (bytes4) {
        if (msg.sender != address(babylonGame)) revert WrongKeyContract();
        if (id != babylonKeyTokenId) revert WrongKeyItem();
        if (value != 1) revert WrongKeyAmount();
        if (config.remainingKeyMints == 0) revert NoMoreRemainingKeyMints();
        
        config.remainingKeyMints -= 1;
        babylonGame.safeTransferFrom(address(this), burnAddress, id, value, "");
        
        _internalKeyMint(from, 1);
        
        return this.onERC1155Received.selector;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981, ERC1155Receiver)
        returns (bool) {
        return ERC721.supportsInterface(interfaceId) ||
               ERC1155Receiver.supportsInterface(interfaceId) ||
               ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) external onlyOwner {
        config.operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return config.operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
    
    receive() external payable {}
    fallback (bytes calldata) external payable returns (bytes memory) {}
}